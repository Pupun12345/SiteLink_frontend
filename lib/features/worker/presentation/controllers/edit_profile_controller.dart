import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/models/skill_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';
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
        if (u.dateOfBirth != null) {
          dobCtrl.text = _fmtDate(u.dateOfBirth!);
        }
        currentProfileImageUrl.value = u.profileImage ?? '';
        if (u.totalExperience != null) {
          experienceYears.value = u.totalExperience!.round();
        }

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
        AppSnackbar.error(message: meRes.message ?? 'Profile load nahi hua');
      }
    } catch (_) {
      AppSnackbar.error(message: 'Profile load nahi hua — dobara try karein');
    } finally {
      isLoading.value = false;
    }
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

  void setPrimarySkill(int? id) {
    if (id == null || id == selectedPrimarySkillId.value) return;
    selectedPrimarySkillId.value = id;
    selectedSecondarySkillIds.remove(id); // primary secondary me na rahe
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
      final picked = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1200);
      if (picked != null) newProfileImage.value = File(picked.path);
    } catch (_) {
      AppSnackbar.error(message: 'Image pick nahi ho paayi');
    }
  }

  // ── Save ──────────────────────────────────────────────────────
  Future<void> save() async {
    if (isSaving.value) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackbar.error(message: 'Naam khaali nahi ho sakta');
      return;
    }
    // Location: dono chahiye ya koi nahi (backend rule)
    if (_locationDirty &&
        (selectedState.value == null || selectedCity.value == null)) {
      AppSnackbar.error(message: 'State aur city dono select karein');
      return;
    }
    if (_skillsDirty && selectedPrimarySkillId.value == null) {
      AppSnackbar.error(message: 'Primary skill select karein');
      return;
    }

    // Sirf filled/changed fields — partial update
    final fields = <String, dynamic>{
      if (name != (_me?.name ?? '')) 'name': name,
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

    if (fields.isEmpty && newProfileImage.value == null) {
      AppSnackbar.warning(message: 'Koi change nahi hai');
      return;
    }

    isSaving.value = true;
    try {
      final res = await _workerApi.editWorkerProfile(
        fields: fields,
        profileImage: newProfileImage.value,
      );
      if (res.success) {
        // Profile tab turant refresh ho jaaye
        if (Get.isRegistered<WorkerProfileController>()) {
          Get.find<WorkerProfileController>().fetchProfile();
        }
        AppSnackbar.success(
            message: res.message ?? 'Profile updated successfully');
        Get.back(result: true);
      } else {
        AppSnackbar.error(message: res.message ?? 'Update nahi hua');
      }
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    dobCtrl.dispose();
    expDescCtrl.dispose();
    salaryCtrl.dispose();
    otherSkillCtrl.dispose();
    super.onClose();
  }
}
