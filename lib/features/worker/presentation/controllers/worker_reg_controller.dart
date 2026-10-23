import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/models/skill_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/models/worker_models.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/image_pick.dart';

class WorkerRegController extends GetxController {
  final _picker = ImagePicker();
  final _skillsApi = SkillsApiService();
  final _locationApi = LocationApiService();
  final _workerApi = WorkerApiService();

  // ── API Data ──────────────────────────────────────────
  final allSkills = <SkillModel>[].obs;
  final allStates = <StateModel>[].obs;
  final allCities = <CityModel>[].obs;
  final isLoadingSkills = false.obs;
  final isLoadingStates = false.obs;
  final isLoadingCities = false.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    final restored = _restoreDraft();
    if (!restored) _prefillFromSession();
    _loadSkills();
    _loadStates();
    if (restored) _recoverLostPick();
  }

  // ── Draft (process death se bachav) ────────────────────────────
  // Gallery / camera khulne par kam RAM wale phone par Android hamara
  // process maar deta hai. Wapas aane par app splash se shuru hota hai aur
  // poora bhara hua form gayab. Isliye form ka draft GetStorage me rakhte
  // hain — har step change aur har picker khulne se PEHLE — aur splash
  // isse dekh kar user ko usi step par wapas le aata hai.
  static const _kDraft = 'worker_reg_draft';
  static final _box = GetStorage();

  /// Picker kis cheez ke liye khula tha — process death ke baad
  /// `retrieveLostData()` se mili image sahi jagah lagane ke liye.
  static const _pickProfile = 'profile';
  static const _pickIdProof = 'idProof';
  static const _pickCert = 'cert';

  /// Abhi user kis step par hai (route name).
  String _step = AppRoutes.workerReg1;

  /// Adhoora registration hai to uska step (route), warna null. Splash
  /// isse user ko wapas form par laata hai.
  static String? pendingDraftStep() {
    final raw = _box.read(_kDraft);
    if (raw is! Map) return null;
    final step = raw['step'];
    return step is String && step.isNotEmpty ? step : null;
  }

  static Future<void> clearDraft() => _box.remove(_kDraft);

  void _saveDraft({String? pendingPick}) {
    _box.write(_kDraft, {
      'step': _step,
      'pendingPick': pendingPick,
      'profilePhoto': profilePhoto.value?.path,
      'name': nameCtrl.text,
      'nominee': nomineeCtrl.text,
      'dob': dobCtrl.text,
      'city': cityCtrl.text,
      'gender': gender.value,
      'primarySkillId': selectedPrimarySkillId.value,
      'secondarySkillIds': selectedSecondarySkillIds.toList(),
      'experienceYears': experienceYears.value,
      'expDesc': expDescCtrl.text,
      'otherSkill': otherSkillCtrl.text,
      'stateId': selectedState.value?.id,
      'stateName': selectedState.value?.name,
      'cityId': selectedCity.value?.id,
      'cityName': selectedCity.value?.name,
      'preferredArea': preferredAreaCtrl.text,
      'willRelocate': willRelocate.value,
      'salaryType': salaryType.value,
      'salary': salaryCtrl.text,
      'idType': selectedIdType.value,
      'idProof': idProofFile.value?.path,
      'certs': experienceCerts.map((f) => f.path).toList(),
    });
  }

  String? _pendingPick;

  /// Draft mila aur form me bhar diya → true.
  bool _restoreDraft() {
    final raw = _box.read(_kDraft);
    if (raw is! Map) return false;
    final d = Map<String, dynamic>.from(raw);

    // Sirf wahi file wapas lagao jo disk par abhi bhi hai (cache saaf ho
    // sakta hai).
    File? existing(Object? path) =>
        path is String && path.isNotEmpty && File(path).existsSync()
            ? File(path)
            : null;
    String str(String k) => d[k] is String ? d[k] as String : '';

    _step = str('step').isEmpty ? AppRoutes.workerReg1 : str('step');
    _pendingPick = d['pendingPick'] as String?;
    profilePhoto.value = existing(d['profilePhoto']);
    nameCtrl.text = str('name');
    nomineeCtrl.text = str('nominee');
    dobCtrl.text = str('dob');
    cityCtrl.text = str('city');
    if (str('gender').isNotEmpty) gender.value = str('gender');
    selectedPrimarySkillId.value = d['primarySkillId'] as int?;
    selectedSecondarySkillIds.assignAll(
        (d['secondarySkillIds'] as List? ?? const []).whereType<int>());
    if (d['experienceYears'] is int) {
      experienceYears.value = d['experienceYears'] as int;
    }
    expDescCtrl.text = str('expDesc');
    otherSkillCtrl.text = str('otherSkill');
    final stateId = d['stateId'] as int?;
    if (stateId != null) {
      selectedState.value =
          StateModel(id: stateId, name: d['stateName'] as String?);
      loadCitiesForState(stateId);
    }
    final cityId = d['cityId'] as int?;
    if (cityId != null) {
      selectedCity.value =
          CityModel(id: cityId, name: d['cityName'] as String?);
    }
    preferredAreaCtrl.text = str('preferredArea');
    if (d['willRelocate'] is bool) willRelocate.value = d['willRelocate'] as bool;
    if (str('salaryType').isNotEmpty) salaryType.value = str('salaryType');
    salaryCtrl.text = str('salary');
    if (str('idType').isNotEmpty) selectedIdType.value = str('idType');
    idProofFile.value = existing(d['idProof']);
    experienceCerts.assignAll(
        (d['certs'] as List? ?? const []).map(existing).whereType<File>());
    return true;
  }

  /// Process death se pehle jo image chuni gayi thi, Android use
  /// `retrieveLostData()` me rakh deta hai — use sahi field me lagao.
  Future<void> _recoverLostPick() async {
    final target = _pendingPick;
    if (target == null || !Platform.isAndroid) return;
    try {
      final lost = await _picker.retrieveLostData();
      final path = lost.file?.path;
      if (path == null) return;
      final file = File(path);
      switch (target) {
        case _pickProfile:
          profilePhoto.value = file;
        case _pickIdProof:
          idProofFile.value = file;
          idProofUploaded.value = false;
        case _pickCert:
          if (experienceCerts.length < maxExperienceCerts) {
            experienceCerts.add(file);
          }
      }
    } catch (_) {
      // Recover na ho paaye to user dobara chun lega — form to bacha hai.
    } finally {
      _pendingPick = null;
      _saveDraft();
    }
  }

  /// Step badalte waqt draft me step bhi likho, phir navigate.
  void _goTo(String route) {
    _step = route;
    _saveDraft();
    Get.toNamed(route);
  }

  /// Step 2 ka Next.
  void goToStep3() => _goTo(AppRoutes.workerReg3);

  /// Picker khulne se pehle: jis screen par picker hai wahi step, aur
  /// kis field ke liye khula — taaki restart ke baad wahin wapas aayein.
  void _beforePick(String step, String? target) {
    _step = step;
    _saveDraft(pendingPick: target);
  }

  /// Google/OTP login ke baad session me jo naam hai (Google se aata hai)
  /// use registration form me pre-fill — user ko dobara na likhna pade.
  void _prefillFromSession() {
    final name = SessionService.to.user?.name ?? SessionService.to.userName;
    if (nameCtrl.text.trim().isEmpty && name.isNotEmpty) {
      nameCtrl.text = name;
    }
  }

  // ── Load Skills from API ──────────────────────────────
  Future<void> _loadSkills() async {
    isLoadingSkills.value = true;
    try {
      final response = await _skillsApi.getAllSkills();
      if (response.success && response.data.isNotEmpty) {
        allSkills.value = response.data;
      } else {
        AppSnackbar.error(message: 'load_skills_failed'.tr);
      }
    } catch (e) {
      AppSnackbar.error(message: 'load_skills_error'.trParams({'error': '$e'}));
    } finally {
      isLoadingSkills.value = false;
    }
  }

  // ── Load States from API ──────────────────────────────
  Future<void> _loadStates() async {
    isLoadingStates.value = true;
    try {
      final response = await _locationApi.getStates();
      if (response.success && response.data.isNotEmpty) {
        allStates.value = response.data;
      } else {
        AppSnackbar.error(message: 'load_states_failed'.tr);
      }
    } catch (e) {
      AppSnackbar.error(message: 'load_states_error'.trParams({'error': '$e'}));
    } finally {
      isLoadingStates.value = false;
    }
  }

  // ── Load Cities when state changes ────────────────────
  Future<void> loadCitiesForState(int stateId) async {
    isLoadingCities.value = true;

    try {
      final citiesResponse = await _locationApi.getCities(stateId);

      if (citiesResponse.success && citiesResponse.data.isNotEmpty) {
        allCities.value = citiesResponse.data;
      } else {
        allCities.clear();
      }
    } catch (e) {
      AppSnackbar.error(message: 'load_cities_error'.trParams({'error': '$e'}));
    } finally {
      isLoadingCities.value = false;
    }
  }

  // Step 1
  /// Worker ki apni photo (chehra). Optional hai, par registration me hi
  /// maang lete hain — baad me Edit Profile se daalna zyadatar kabhi hota
  /// hi nahi, aur vendor ko applicant list me chehra dikhna chahiye.
  final profilePhoto = Rxn<File>();

  Future<void> pickProfilePhoto(ImageSource source) async {
    _beforePick(AppRoutes.workerReg1, _pickProfile);
    try {
      // Photo preset — avatar chhota dikhta hai, zyada compress theek hai.
      final picked = await pickPhotoImage(_picker, source);
      if (picked != null) profilePhoto.value = File(picked.path);
    } catch (_) {
      AppSnackbar.error(message: 'image_pick_failed'.tr);
    }
    _saveDraft();
  }

  void removeProfilePhoto() => profilePhoto.value = null;

  final nameCtrl       = TextEditingController();
  final nomineeCtrl    = TextEditingController();
  final dobCtrl        = TextEditingController();
  final cityCtrl       = TextEditingController();
  final gender         = 'Male'.obs;

  // Step 2
  final selectedPrimarySkillId = Rxn<int>();
  final selectedSecondarySkillIds = <int>[].obs;
  final skillSearchCtrl  = TextEditingController();
  final skillSearch      = ''.obs;
  final experienceYears  = 3.obs;
  final expDescCtrl      = TextEditingController();
  final otherSkillCtrl   = TextEditingController();

  void onSkillSearchChanged(String val) => skillSearch.value = val;

  void toggleSecondarySkillId(int id) {
    if (selectedSecondarySkillIds.contains(id)) {
      selectedSecondarySkillIds.remove(id);
    } else {
      selectedSecondarySkillIds.add(id);
    }
  }

  void addCustomSkill() {
    final custom = otherSkillCtrl.text.trim();
    if (custom.isEmpty) return;
    // Custom skill will be sent in `otherSkill` field. Keep text for user review.
  }

  // Step 3
  final selectedState = Rxn<StateModel>();
  final selectedCity = Rxn<CityModel>();
  final preferredAreaCtrl = TextEditingController();
  final willRelocate      = true.obs;
  final salaryType        = 'daily'.obs;
  final salaryCtrl        = TextEditingController();

  // ── Document Upload ──────────────────────────────────────────
  final selectedIdType  = 'Aadhaar'.obs;
  final idProofFile     = Rx<File?>(null);       // selected ID image
  final idProofUploaded = false.obs;             // true after successful upload
  final isUploadingId   = false.obs;

  // Pick ID proof from camera or gallery
  Future<void> pickIdProof(ImageSource source) async {
    _beforePick(AppRoutes.documentUpload, _pickIdProof);
    try {
      // Document preset — admin ko ID par text padhna hota hai.
      final picked = await pickDocumentImage(_picker, source);
      if (picked != null) {
        idProofFile.value = File(picked.path);
        idProofUploaded.value = false; // reset if re-picked
      }
    } catch (e) {
      AppSnackbar.error(message: 'image_pick_retry_error'.tr);
    }
    _saveDraft();
  }

  // ── Experience certificates (multiple) ──────────────────────────
  // Worker alag-alag company/skill ke ek se zyada certificate laga
  // sakta hai. Har ek PDF ya image ho sakta hai.
  static const maxExperienceCerts = 5; // backend multer bhi 5 par capped hai

  final experienceCerts = <File>[].obs;

  /// Kya file PDF hai? (thumbnail ki jagah PDF chip dikhane ke liye)
  bool isPdf(File f) => f.path.toLowerCase().endsWith('.pdf');

  void removeExperienceCert(int index) {
    if (index >= 0 && index < experienceCerts.length) {
      experienceCerts.removeAt(index);
      _saveDraft();
    }
  }

  /// `source == null` → PDF picker, warna camera/gallery se image.
  Future<void> pickExperienceCert(ImageSource? source) async {
    if (experienceCerts.length >= maxExperienceCerts) {
      AppSnackbar.warning(
          message: 'max_certificates_error'
              .trParams({'count': '$maxExperienceCerts'}));
      return;
    }
    // PDF (file_picker) ke liye lost-data recovery nahi hoti, par form
    // phir bhi draft se bach jaata hai.
    _beforePick(AppRoutes.documentUpload, source == null ? null : _pickCert);
    try {
      if (source == null) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null && result.files.single.path != null) {
          experienceCerts.add(File(result.files.single.path!));
        }
      } else {
        // Document preset — certificate ka text padhne layak rehna chahiye.
        final picked = await pickDocumentImage(_picker, source);
        if (picked != null) experienceCerts.add(File(picked.path));
      }
    } catch (_) {
      AppSnackbar.error(message: 'image_pick_retry_error'.tr);
    }
    _saveDraft();
  }

  // Remove ID proof
  void removeIdProof() {
    idProofFile.value = null;
    idProofUploaded.value = false;
    _saveDraft();
  }

  // Show bottom sheet to choose Camera or Gallery
  void showImageSourceSheet({
    required BuildContext context,
    required void Function(ImageSource) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('camera_label'.tr),
                onTap: () {
                  Get.back();
                  onSelect(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('gallery_label'.tr),
                onTap: () {
                  Get.back();
                  onSelect(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 3 navigation
  /// Step 1 ka Next. Pehle bina check ke aage chala jaata tha, aur
  /// khaali naam ka pata chauthe step par submit karte waqt chalta tha.
  void submitStep1() {
    if (nameCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'enter_name_error'.tr);
      return;
    }
    if (nomineeCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'enter_nominee_error'.tr);
      return;
    }
    _goTo(AppRoutes.workerReg2);
  }

  void submitStep3() => _goTo(AppRoutes.documentUpload);

  // ── Submit Entire Profile to API ──────────────────────
  Future<void> submitWorkerProfile() async {
    if (isSubmitting.value) return; // double-submit guard

    // Validate required fields
    if (nameCtrl.text.isEmpty) {
      AppSnackbar.error(message: 'enter_name_error'.tr);
      return;
    }
    if (nomineeCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'enter_nominee_error'.tr);
      return;
    }
    if (dobCtrl.text.isEmpty) {
      AppSnackbar.error(message: 'select_dob_error'.tr);
      return;
    }

    if (selectedPrimarySkillId.value == null) {
      AppSnackbar.error(message: 'select_primary_skill_error'.tr);
      return;
    }
    if (selectedState.value == null) {
      AppSnackbar.error(message: 'select_work_state_error'.tr);
      return;
    }
    if (selectedCity.value == null) {
      AppSnackbar.error(message: 'select_city_error'.tr);
      return;
    }
    if (salaryCtrl.text.isEmpty) {
      AppSnackbar.error(message: 'enter_expected_salary_error'.tr);
      return;
    }

    isSubmitting.value = true;
    try {
      // Build request using IDs where required
      final request = WorkerProfileRequest(
        name: nameCtrl.text,
        dateOfBirth: dobCtrl.text,
        gender: gender.value,
        primarySkillId: selectedPrimarySkillId.value,
        secondarySkillId: selectedSecondarySkillIds.toList(),
        totalExperience: experienceYears.value,
        experienceDescription: expDescCtrl.text,
        willingtoRelocate: willRelocate.value,
        salaryType: salaryType.value,
        salary: salaryCtrl.text,
        otherSkill: otherSkillCtrl.text.trim().isEmpty ? null : otherSkillCtrl.text.trim(),
        workStateId: selectedState.value?.id,
        workCityId: selectedCity.value?.id,
        cityName: selectedCity.value?.name,
        nomineeName: nomineeCtrl.text.trim(),
      );

      // Debug logging — pretty print request and files
      final requestMap = request.toJson();
      final filesInfo = {
        'governmentID': idProofFile.value?.path,
        'experienceCertificate': experienceCerts.length,
      };

      print('🚀 ===== SUBMIT WORKER PROFILE REQUEST =====');
      print(const JsonEncoder.withIndent('  ').convert(requestMap));
      print('📸 FILES:');
      print(const JsonEncoder.withIndent('  ').convert(filesInfo));
      print('📦 =======================================');

      // Submit to API with files (multiple work photos supported)
      //
      // `profileImage` ab apne dedicated picker se aata hai (Step 1).
      final response = await _workerApi.createWorkerProfile(
        request,
        profileImage: profilePhoto.value,
        experienceCertificates: experienceCerts.toList(),
        governmentID: idProofFile.value,
      );

      if (response.success) {
        // userType persist karo taaki dobara registration na maange
        await SessionService.to.setUserType('worker');
        await clearDraft();
        // Navigate pehle, snackbar baad me — snackbar GetX me ek route
        // hai, isliye pehle dikhane par wo navigation ke saath hi gayab
        // ho jaata tha aur user ko confirmation kabhi dikhta hi nahi tha.
        Get.offNamed(AppRoutes.profilePending);
        AppSnackbar.success(message: response.message ?? 'profile_created_success'.tr);
      } else {
        AppSnackbar.error(message: response.message ?? 'profile_create_failed'.tr);
      }
    } catch (e) {
      AppSnackbar.error(message: 'profile_create_error_generic'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ID proof ka alag upload step hata diya gaya — `governmentID` seedha
  // createWorkerProfile ke saath jaata hai (upar submit me). Yahan ek
  // `_uploadIdProof()` pada tha jise koi call hi nahi karta tha.



  @override
  void onClose() {
    nameCtrl.dispose();
    nomineeCtrl.dispose();
    dobCtrl.dispose();
    cityCtrl.dispose();
    expDescCtrl.dispose();
    // workCityCtrl removed — using selectedState/selectedCity
    skillSearchCtrl.dispose();
    otherSkillCtrl.dispose();
    preferredAreaCtrl.dispose();
    salaryCtrl.dispose();
    super.onClose();
  }
}