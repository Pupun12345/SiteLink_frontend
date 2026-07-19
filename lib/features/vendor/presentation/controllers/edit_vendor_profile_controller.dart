import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  EDIT VENDOR PROFILE — PUT /api/profile/edit/vendor (partial multipart)
// ═══════════════════════════════════════════════════════════════════
class EditVendorProfileController extends GetxController {
  final _profileApi  = ProfileApiService();
  final _vendorApi   = VendorApiService();
  final _locationApi = LocationApiService();
  final _picker      = ImagePicker();

  final isLoading = true.obs;
  final isSaving  = false.obs;

  // Editable fields
  final companyNameCtrl = TextEditingController();
  final nameCtrl        = TextEditingController();
  final designationCtrl = TextEditingController();
  final emailCtrl       = TextEditingController();
  final whatsappCtrl    = TextEditingController();
  final websiteCtrl     = TextEditingController();
  final workAreaCtrl    = TextEditingController();
  final gstCtrl         = TextEditingController();

  // Phone number — read-only here; changing it needs OTP verification
  // (see change_phone_sheet.dart), so it's kept out of the plain-field diff.
  final currentPhone = ''.obs;

  // Location
  final allStates = <StateModel>[].obs;
  final allCities = <CityModel>[].obs;
  final selectedState = Rxn<StateModel>();
  final selectedCity  = Rxn<CityModel>();
  final isLoadingCities = false.obs;
  bool _locationDirty = false;

  // New images (optional)
  final newLogo    = Rxn<File>();
  final currentLogoUrl = ''.obs;

  MyProfile? _me;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _profileApi.getMe(),
        _locationApi.getStates(),
      ]);
      final meRes     = results[0] as MyProfileResponse;
      final statesRes = results[1] as GetStatesResponse;
      if (statesRes.success) allStates.assignAll(statesRes.data);

      final u = meRes.user;
      if (u != null) {
        _me = u;
        companyNameCtrl.text = u.companyName ?? '';
        nameCtrl.text        = u.name ?? '';
        designationCtrl.text = u.designation ?? '';
        emailCtrl.text       = u.email ?? '';
        whatsappCtrl.text    = u.whatsappNumber ?? '';
        websiteCtrl.text     = u.website ?? '';
        workAreaCtrl.text    = u.workArea ?? '';
        gstCtrl.text         = u.gstNumber ?? '';
        currentLogoUrl.value = u.companyLogo ?? '';
        currentPhone.value   = u.phone ?? '';

        final st = allStates.firstWhereOrNull(
            (s) => s.name?.toLowerCase() == u.workState?.toLowerCase());
        if (st != null) {
          selectedState.value = st;
          await _loadCities(st.id!, matchCity: u.workCity);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCities(int stateId, {String? matchCity}) async {
    isLoadingCities.value = true;
    try {
      final res = await _locationApi.getCities(stateId);
      allCities.assignAll(res.success ? res.data : const []);
      if (matchCity != null) {
        selectedCity.value = allCities.firstWhereOrNull(
            (c) => c.name?.toLowerCase() == matchCity.toLowerCase());
      }
    } finally {
      isLoadingCities.value = false;
    }
  }

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

  Future<void> pickLogo(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1200);
      if (picked != null) newLogo.value = File(picked.path);
    } catch (_) {
      AppSnackbar.error(message: 'Image pick nahi ho paayi');
    }
  }

  // ── Change phone number (OTP-gated) ────────────────────────────────
  Future<PhoneChangeOtpResponse> sendPhoneOtp(String newPhone) {
    return _profileApi.sendPhoneChangeOtp(newPhone);
  }

  Future<PhoneChangeOtpResponse> verifyPhoneOtp(String otp, String newPhone) async {
    final res = await _profileApi.verifyPhoneChangeOtp(otp);
    if (res.success) {
      currentPhone.value = newPhone;
    }
    return res;
  }

  Future<void> save() async {
    if (isSaving.value) return;
    if (companyNameCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'Company name khaali nahi ho sakta');
      return;
    }
    if (_locationDirty &&
        (selectedState.value == null || selectedCity.value == null)) {
      AppSnackbar.error(message: 'State aur city dono select karein');
      return;
    }

    String? diff(String cur, String? old) =>
        cur.trim() != (old ?? '') ? cur.trim() : null;

    final fields = <String, dynamic>{
      if (diff(companyNameCtrl.text, _me?.companyName) != null)
        'companyName': companyNameCtrl.text.trim(),
      if (diff(nameCtrl.text, _me?.name) != null) 'name': nameCtrl.text.trim(),
      if (diff(designationCtrl.text, _me?.designation) != null)
        'designation': designationCtrl.text.trim(),
      if (diff(emailCtrl.text, _me?.email) != null)
        'email': emailCtrl.text.trim(),
      if (diff(whatsappCtrl.text, _me?.whatsappNumber) != null)
        'whatsappNumber': whatsappCtrl.text.trim(),
      if (diff(websiteCtrl.text, _me?.website) != null)
        'website': websiteCtrl.text.trim(),
      if (diff(workAreaCtrl.text, _me?.workArea) != null)
        'workArea': workAreaCtrl.text.trim(),
      if (diff(gstCtrl.text, _me?.gstNumber) != null)
        'gstNumber': gstCtrl.text.trim().toUpperCase(),
      if (_locationDirty) ...{
        'workStateID': selectedState.value!.id,
        'workCityID': selectedCity.value!.id,
      },
    };

    if (fields.isEmpty && newLogo.value == null) {
      AppSnackbar.warning(message: 'Koi change nahi hai');
      return;
    }

    isSaving.value = true;
    try {
      final res = await _vendorApi.editVendorProfile(
        fields: fields,
        companyLogo: newLogo.value,
      );
      if (res.success) {
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
    companyNameCtrl.dispose();
    nameCtrl.dispose();
    designationCtrl.dispose();
    emailCtrl.dispose();
    whatsappCtrl.dispose();
    websiteCtrl.dispose();
    workAreaCtrl.dispose();
    gstCtrl.dispose();
    super.onClose();
  }
}
