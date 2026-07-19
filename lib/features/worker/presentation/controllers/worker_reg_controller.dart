import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/models/skill_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/models/worker_models.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../app/routes/app_routes.dart';

class WorkerRegController extends GetxController {
  final _picker = ImagePicker();
  final _skillsApi = SkillsApiService();
  final _locationApi = LocationApiService();
  final _workerApi = WorkerApiService();
  final _documentApi = DocumentUploadService();

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
    _prefillFromSession();
    _loadSkills();
    _loadStates();
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
        AppSnackbar.error(message: 'Failed to load skills');
      }
    } catch (e) {
      AppSnackbar.error(message: 'Error loading skills: $e');
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
        AppSnackbar.error(message: 'Failed to load states');
      }
    } catch (e) {
      AppSnackbar.error(message: 'Error loading states: $e');
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
      AppSnackbar.error(message: 'Error loading cities: $e');
    } finally {
      isLoadingCities.value = false;
    }
  }

  // Step 1
  final nameCtrl       = TextEditingController();
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

  final workPhotos      = <File>[].obs;          // list of work photo files
  final isUploadingPhoto = false.obs;

  // Pick ID proof from camera or gallery
  Future<void> pickIdProof(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;
      idProofFile.value = File(picked.path);
      idProofUploaded.value = false; // reset if re-picked
    } catch (e) {
      AppSnackbar.error(message: 'Could not pick image. Please try again.');
    }
  }

  // Experience certificate — PDF ya image ho sakta hai
  final experienceCertFile = Rxn<File>();
  final experienceCertType = ''.obs; // 'pdf' ya 'image'

  void removeExperienceCert() {
    experienceCertFile.value = null;
    experienceCertType.value = '';
  }
  Future<void> pickExperienceCert(ImageSource? source) async {
    if (source == null) {
      // ✅ Sahi — instance method
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        experienceCertFile.value = File(result.files.single.path!);
        experienceCertType.value = 'pdf';
      }
    } else {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        experienceCertFile.value = File(picked.path);
        experienceCertType.value = 'image';
      }
    }
  }

  // Remove ID proof
  void removeIdProof() {
    idProofFile.value = null;
    idProofUploaded.value = false;
  }

  // Pick a work photo
  Future<void> pickWorkPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;
      if (workPhotos.length >= 6) {
        AppSnackbar.warning(message: 'You can upload up to 6 work photos.');
        return;
      }
      workPhotos.add(File(picked.path));
    } catch (e) {
      AppSnackbar.error(message: 'Could not pick image.');
    }
  }

  // Remove a work photo by index
  void removeWorkPhoto(int index) {
    if (index < workPhotos.length) workPhotos.removeAt(index);
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
                title: const Text('Camera'),
                onTap: () {
                  Get.back();
                  onSelect(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
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
  void submitStep3() => Get.toNamed(AppRoutes.documentUpload);

  // ── Submit Entire Profile to API ──────────────────────
  Future<void> submitWorkerProfile() async {
    // Validate required fields
    if (nameCtrl.text.isEmpty) {
      AppSnackbar.error(message: 'Please enter your name');
      return;
    }
    if (dobCtrl.text.isEmpty) {
      AppSnackbar.error(message: 'Please select your date of birth');
      return;
    }

    if (selectedPrimarySkillId.value == null) {
      AppSnackbar.error(message: 'Please select your primary skill');
      return;
    }
    if (selectedState.value == null) {
      AppSnackbar.error(message: 'Please select your work state');
      return;
    }
    if (selectedCity.value == null) {
      AppSnackbar.error(message: 'Please select your city');
      return;
    }
    if (salaryCtrl.text.isEmpty) {
      AppSnackbar.error(message: 'Please enter your expected salary');
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
      );

      // Debug logging — pretty print request and files
      final requestMap = request.toJson();
      final filesInfo = {
        'profileImage': workPhotos.isNotEmpty ? workPhotos.first.path : null,
        'workSamplesPhoto': workPhotos.length,
        'governmentID': idProofFile.value?.path,
        'experienceCertificate': experienceCertFile.value?.path,
      };

      print('🚀 ===== SUBMIT WORKER PROFILE REQUEST =====');
      print(const JsonEncoder.withIndent('  ').convert(requestMap));
      print('📸 FILES:');
      print(const JsonEncoder.withIndent('  ').convert(filesInfo));
      print('📦 =======================================');

      // Submit to API with files (multiple work photos supported)
      final response = await _workerApi.createWorkerProfile(
        request,
        profileImage: workPhotos.isNotEmpty ? workPhotos.first : null,
        workSamplesPhotos: workPhotos.isNotEmpty ? workPhotos.toList() : null,
        experienceCertificate: experienceCertFile.value,
        governmentID: idProofFile.value,
      );

      if (response.success) {
        // userType persist karo taaki dobara registration na maange
        await SessionService.to.setUserType('worker');
        AppSnackbar.success(message: response.message ?? 'Profile created successfully');
        Get.offNamed(AppRoutes.profilePending);
      } else {
        AppSnackbar.error(message: response.message ?? 'Failed to create profile');
      }
    } catch (e) {
      AppSnackbar.error(message: 'Error: Unable to create profile');
    } finally {
      isSubmitting.value = false;
    }
  }

  // ── Upload ID Proof ───────────────────────────────────
  Future<void> _uploadIdProof() async {
    if (idProofFile.value == null) return;

    isUploadingId.value = true;
    try {
      final response = await _documentApi.uploadIdProof(idProofFile.value!);
      if (response.success) {
        idProofUploaded.value = true;
        AppSnackbar.success(message: 'ID proof uploaded successfully');
      } else {
        AppSnackbar.error(
            message: response.message ?? 'Failed to upload ID proof');
      }
    } catch (e) {
      AppSnackbar.error(message: 'Error uploading ID proof: $e');
    } finally {
      isUploadingId.value = false;
    }
  }

  // ── Upload Work Photos ────────────────────────────────
  Future<void> uploadWorkPhotos() async {
    if (workPhotos.isEmpty) {
      AppSnackbar.warning(message: 'Please select at least one work photo');
      return;
    }

    isUploadingPhoto.value = true;
    try {
      int successCount = 0;
      for (final photo in workPhotos) {
        final response = await _documentApi.uploadWorkPhoto(photo);
        if (response.success) {
          successCount++;
        }
      }

      if (successCount == workPhotos.length) {
        AppSnackbar.success(
            message: 'All work photos uploaded successfully');
      } else {
        AppSnackbar.warning(
            message: '$successCount of ${workPhotos.length} photos uploaded');
      }
    } catch (e) {
      AppSnackbar.error(message: 'Error uploading photos: $e');
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  // ── Upload Experience Certificate ─────────────────────
  Future<void> uploadExperienceCert() async {
    if (experienceCertFile.value == null) {
      AppSnackbar.warning(message: 'Please select a certificate file');
      return;
    }

    isUploadingPhoto.value = true;
    try {
      final response =
          await _documentApi.uploadExperienceCert(experienceCertFile.value!);
      if (response.success) {
        AppSnackbar.success(
            message: 'Experience certificate uploaded successfully');
      } else {
        AppSnackbar.error(
            message: response.message ?? 'Failed to upload certificate');
      }
    } catch (e) {
      AppSnackbar.error(message: 'Error uploading certificate: $e');
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  Future<void> submitDocuments() async {
    // Validate required documents
    if (idProofFile.value == null) {
      AppSnackbar.warning(message: 'Please upload your government ID proof.');
      return;
    }

    // Call submitWorkerProfile which sends profile + all files
    await submitWorkerProfile();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
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