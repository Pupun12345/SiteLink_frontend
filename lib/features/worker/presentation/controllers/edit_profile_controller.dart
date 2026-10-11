import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/models/skill_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/searchable_picker.dart';
import '../../../../core/utils/image_pick.dart';
import 'worker_profile_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  EDIT PROFILE CONTROLLER — PUT /api/profile/edit/worker
// ═══════════════════════════════════════════════════════════════════
// Backend PARTIAL update karta hai, isliye sirf changed cheezein bhejte
// hain (dirty-tracking):
//  • primarySkillId bhejo to backend poori skills list REBUILD karta hai
//    → skills tabhi bhejo jab user ne skills change ki ho.
//  • workStateID/workCityID dono saath chahiye (warna 400)
//    → location tabhi bhejo jab user ne badla ho.
class EditProfileController extends GetxController {
  final _profileApi  = ProfileApiService();
  final _workerApi   = WorkerApiService();
  final _skillsApi   = SkillsApiService();
  final _locationApi = LocationApiService();
  final _picker      = ImagePicker();

  // ── State ─────────────────────────────────────────────────────
  final isLoading = true.obs;   // initial prefill
  final isSaving  = false.obs;

  // ── Basic fields ──────────────────────────────────────────────
  final nameCtrl    = TextEditingController();
  final nomineeCtrl = TextEditingController();
  final dobCtrl     = TextEditingController(); // YYYY-MM-DD
  final gender      = RxnString();             // 'male' | 'female' | 'other'
  final expDescCtrl = TextEditingController();
  final salaryCtrl  = TextEditingController();
  final salaryType  = RxnString();             // 'daily' | 'weekly' | 'monthly'
  final experienceYears = RxnInt();
  final willRelocate    = RxnBool();

  // ── Skills ────────────────────────────────────────────────────
  final allSkills = <SkillModel>[].obs;
  final selectedPrimarySkillId    = RxnInt();
  final selectedSecondarySkillIds = <int>[].obs;
  final otherSkillCtrl = TextEditingController();
  bool _skillsDirty = false;

  // ── Location ──────────────────────────────────────────────────
  final allStates = <StateModel>[].obs;
  final allCities = <CityModel>[].obs;
  final selectedState = Rxn<StateModel>();
  final selectedCity  = Rxn<CityModel>();
  final isLoadingCities = false.obs;
  bool _locationDirty = false;

  // ── Images / files ────────────────────────────────────────────
  final currentProfileImageUrl = ''.obs; // server wali (preview)
  final newProfileImage = Rxn<File>();   // nayi pick ki hui

  // ── Experience certificates ───────────────────────────────────
  // Do list: server par pehle se pade (paths) aur ab naye chune gaye.
  // Save par backend ko dono bhejte hain — `keepExperienceCertificates`
  // me wo purane jo user ne rakhe, aur naye files upload karke. Sirf
  // naye bhejne se purane chup-chaap gayab ho jaate.
  static const maxExperienceCerts = 5;

  final existingCerts = <String>[].obs; // server paths
  final newCerts      = <File>[].obs;   // ab chune gaye

  bool isPdf(File f) => f.path.toLowerCase().endsWith('.pdf');

  int get _totalCerts => existingCerts.length + newCerts.length;
  bool get canAddCert => _totalCerts < maxExperienceCerts;

  void removeExistingCert(int i) {
    if (i >= 0 && i < existingCerts.length) existingCerts.removeAt(i);
  }

  void removeNewCert(int i) {
    if (i >= 0 && i < newCerts.length) newCerts.removeAt(i);
  }

  Future<void> pickCert(ImageSource? source) async {
    if (!canAddCert) {
      AppSnackbar.warning(
          message: 'max_certificates_error'
              .trParams({'count': '$maxExperienceCerts'}));
      return;
    }
    try {
      if (source == null) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null && result.files.single.path != null) {
          newCerts.add(File(result.files.single.path!));
        }
      } else {
        final picked = await pickDocumentImage(_picker, source);
        if (picked != null) newCerts.add(File(picked.path));
      }
    } catch (_) {
      AppSnackbar.error(message: 'image_pick_failed'.tr);
    }
  }

  MyProfile? _me;
  String get initials {
    final n = nameCtrl.text.trim();
    if (n.isEmpty) return 'U';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  // ── Prefill: profile + skills + states parallel load ──────────
  Future<void> _bootstrap() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _profileApi.getMe(),
        _skillsApi.getAllSkills(),
        _locationApi.getStates(),
      ]);

      final meRes     = results[0] as MyProfileResponse;
      final skillsRes = results[1] as GetSkillsResponse;
      final statesRes = results[2] as GetStatesResponse;

      if (skillsRes.success) allSkills.assignAll(skillsRes.data);
      if (statesRes.success) allStates.assignAll(statesRes.data);

      final u = meRes.user;
      if (meRes.success && u != null) {
        _me = u;
        nameCtrl.text = u.name ?? '';
        nomineeCtrl.text = u.nomineeName ?? '';
        if (u.dateOfBirth != null) {
          dobCtrl.text = _fmtDate(u.dateOfBirth!);
        }
        currentProfileImageUrl.value = u.profileImage ?? '';
        existingCerts.assignAll(u.experienceCertificate);
        if (u.totalExperience != null) {
          experienceYears.value = u.totalExperience!.round();
        }
        // Baaki work-preference fields bhi prefill — pehle ye save to hote
        // the par wapas load nahi hote the (backend inhe getProfile me
        // bhejta hi nahi tha), isliye har baar khaali dikhte the.
        gender.value = _normalizeGender(u.gender);
        expDescCtrl.text = u.experienceDescription ?? '';
        willRelocate.value = u.willingtoRelocate;
        salaryType.value = u.salaryType;
        if (u.salary != null) salaryCtrl.text = '${u.salary}';

        // Primary skill — naam se id match
        final primary = allSkills.firstWhereOrNull(
            (s) => s.name?.toLowerCase() == u.primarySkill?.toLowerCase());
        selectedPrimarySkillId.value = primary?.skillId;

        // Secondary skills — naam se ids match (custom skill drop ho jaati
        // hai, wo otherSkill field se dubara bhej sakte hain)
        for (final skillName in u.skills) {
          final m = allSkills.firstWhereOrNull(
              (s) => s.name?.toLowerCase() == skillName.toLowerCase());
          if (m?.skillId != null && m!.skillId != primary?.skillId) {
            selectedSecondarySkillIds.add(m.skillId!);
          }
        }

        // State/City — naam se match, phir cities load karke city match
        final st = allStates.firstWhereOrNull(
            (s) => s.name?.toLowerCase() == u.workState?.toLowerCase());
        if (st != null) {
          selectedState.value = st;
          await _loadCities(st.id!, matchCityName: u.workCity);
        }
      } else {
        AppSnackbar.error(message: meRes.message ?? 'profile_load_failed'.tr);
      }
    } catch (_) {
      AppSnackbar.error(message: 'profile_load_retry'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Backend 'Male'/'Female'/'Other' bhejta hai, UI chips lowercase use
  /// karte hain — match na ho to koi chip selected nahi dikhti.
  String? _normalizeGender(String? g) {
    final v = g?.trim().toLowerCase();
    return (v == 'male' || v == 'female' || v == 'other') ? v : null;
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadCities(int stateId, {String? matchCityName}) async {
    isLoadingCities.value = true;
    try {
      final res = await _locationApi.getCities(stateId);
      allCities.assignAll(res.success ? res.data : const []);
      if (matchCityName != null) {
        selectedCity.value = allCities.firstWhereOrNull(
            (c) => c.name?.toLowerCase() == matchCityName.toLowerCase());
      }
    } finally {
      isLoadingCities.value = false;
    }
  }

  // ── UI actions ────────────────────────────────────────────────
  Future<void> pickDob(BuildContext context) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(dobCtrl.text) ??
        DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day), // 18+ only
    );
    if (picked != null) dobCtrl.text = _fmtDate(picked);
  }

  // ── Skill picker helpers (searchable dropdown ke liye) ────────
  /// Saari skills picker-options ke roop me. Sorting picker khud
  /// alphabetically karta hai.
  List<PickerOption<int>> get skillOptions => allSkills
      .where((s) => s.skillId != null)
      .map((s) => PickerOption<int>(value: s.skillId!, label: s.name ?? ''))
      .toList();

  String skillNameById(int id) =>
      allSkills.firstWhereOrNull((s) => s.skillId == id)?.name ?? '';

  /// Selected primary skill ka naam — kuch select na ho to null.
  String? get primarySkillName {
    final id = selectedPrimarySkillId.value;
    if (id == null) return null;
    final name = skillNameById(id);
    return name.isEmpty ? null : name;
  }

  List<String> get secondarySkillNames =>
      selectedSecondarySkillIds.map(skillNameById).toList();

  void setPrimarySkill(int? id) {
    if (id == null || id == selectedPrimarySkillId.value) return;
    selectedPrimarySkillId.value = id;
    selectedSecondarySkillIds.remove(id); // primary secondary me na rahe
    _skillsDirty = true;
  }

  /// Multi-select picker se poori list ek saath set karo.
  void setSecondarySkills(List<int> ids) {
    final next = ids.where((id) => id != selectedPrimarySkillId.value).toList();
    selectedSecondarySkillIds.assignAll(next);
    _skillsDirty = true;
  }

  void toggleSecondarySkill(int id) {
    if (id == selectedPrimarySkillId.value) return;
    if (selectedSecondarySkillIds.contains(id)) {
      selectedSecondarySkillIds.remove(id);
    } else {
      selectedSecondarySkillIds.add(id);
    }
    _skillsDirty = true;
  }

  void markSkillsDirty() => _skillsDirty = true; // otherSkill type karne par

  Future<void> onStateChanged(StateModel? st) async {
    if (st == null || st.id == selectedState.value?.id) return;
    selectedState.value = st;
    selectedCity.value = null;
    _locationDirty = true;
    await _loadCities(st.id!);
  }

  void onCityChanged(CityModel? c) {
    if (c == null) return;
    selectedCity.value = c;
    _locationDirty = true;
  }

  Future<void> pickProfileImage(ImageSource source) async {
    try {
      // Profile photo — photo preset (avatar 80px me dikhta hai).
      final picked = await pickPhotoImage(_picker, source);
      if (picked != null) newProfileImage.value = File(picked.path);
    } catch (_) {
      AppSnackbar.error(message: 'image_pick_failed'.tr);
    }
  }

  // ── Save ──────────────────────────────────────────────────────
  Future<void> save() async {
    if (isSaving.value) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackbar.error(message: 'name_required_error'.tr);
      return;
    }
    // Location: dono chahiye ya koi nahi (backend rule)
    if (_locationDirty &&
        (selectedState.value == null || selectedCity.value == null)) {
      AppSnackbar.error(message: 'select_state_and_city_error'.tr);
      return;
    }
    if (_skillsDirty && selectedPrimarySkillId.value == null) {
      AppSnackbar.error(message: 'select_primary_skill_error'.tr);
      return;
    }

    // Sirf filled/changed fields — partial update
    final fields = <String, dynamic>{
      if (name != (_me?.name ?? '')) 'name': name,
      if (nomineeCtrl.text.trim().isNotEmpty &&
          nomineeCtrl.text.trim() != (_me?.nomineeName ?? ''))
        'nomineeName': nomineeCtrl.text.trim(),
      if (dobCtrl.text.trim().isNotEmpty &&
          dobCtrl.text.trim() !=
              (_me?.dateOfBirth != null ? _fmtDate(_me!.dateOfBirth!) : ''))
        'dateOfBirth': dobCtrl.text.trim(),
      if (gender.value != null) 'gender': gender.value,
      if (experienceYears.value != null)
        'totalExperience': experienceYears.value,
      if (expDescCtrl.text.trim().isNotEmpty)
        'experienceDescription': expDescCtrl.text.trim(),
      if (willRelocate.value != null) 'willingtoRelocate': willRelocate.value,
      if (salaryType.value != null) 'salaryType': salaryType.value,
      if (salaryCtrl.text.trim().isNotEmpty) 'salary': salaryCtrl.text.trim(),
      if (_skillsDirty) ...{
        'primarySkillId': selectedPrimarySkillId.value,
        'secondarySkillId': selectedSecondarySkillIds.toList(),
        if (otherSkillCtrl.text.trim().isNotEmpty)
          'otherSkill': otherSkillCtrl.text.trim(),
      },
      if (_locationDirty) ...{
        'workStateID': selectedState.value!.id,
        'workCityID': selectedCity.value!.id,
      },
    };

    // Certificates bhi badle ho sakte hain — naya add hua ya purana
    // hataya gaya. Dono case me save allow karna hai.
    final certsChanged = newCerts.isNotEmpty ||
        existingCerts.length != (_me?.experienceCertificate.length ?? 0);

    if (fields.isEmpty && newProfileImage.value == null && !certsChanged) {
      AppSnackbar.warning(message: 'no_changes_warning'.tr);
      return;
    }

    isSaving.value = true;
    try {
      final res = await _workerApi.editWorkerProfile(
        fields: fields,
        profileImage: newProfileImage.value,
        experienceCertificates: newCerts.isEmpty ? null : newCerts.toList(),
        // Poori final list ka purana hissa — jo user ne rakha. Tabhi
        // bhejte hain jab kuch badla ho, warna backend field ko chhuta
        // hi nahi.
        keepExperienceCertificates: certsChanged ? existingCerts.toList() : null,
      );
      if (res.success) {
        // Profile tab turant refresh ho jaaye
        if (Get.isRegistered<WorkerProfileController>()) {
          Get.find<WorkerProfileController>().fetchProfile();
        }
        // Pehle back, PHIR snackbar — ulta karne par `Get.back()` snackbar
        // ko hi band karta hai (GetX me snackbar ek route hai), screen
        // wahin reh jaati aur message bhi dikhta nahi.
        Get.back(result: true);
        AppSnackbar.success(
            message: res.message ?? 'profile_updated_success'.tr);
      } else {
        AppSnackbar.error(message: res.message ?? 'profile_update_failed'.tr);
      }
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    nomineeCtrl.dispose();
    dobCtrl.dispose();
    expDescCtrl.dispose();
    salaryCtrl.dispose();
    otherSkillCtrl.dispose();
    super.onClose();
  }
}
