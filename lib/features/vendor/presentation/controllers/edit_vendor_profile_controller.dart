import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/utils/tax_id_formats.dart';
import '../../../../core/utils/image_pick.dart';

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
      // Logo sirf dikhne ke liye hai — photo preset.
      final picked = await pickPhotoImage(_picker, source);
      if (picked != null) newLogo.value = File(picked.path);
    } catch (_) {
      AppSnackbar.error(message: 'image_pick_failed'.tr);
    }
  }

  // Change-phone flow ab shared sheet me hai
  // (features/shared/.../change_phone_sheet.dart) — wo ProfileApiService
  // seedha call karti hai aur success par `onUpdated` se currentPhone
  // yahan update kar deti hai.

  Future<void> save() async {
    if (isSaving.value) return;
    if (companyNameCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'company_name_required_error'.tr);
      return;
    }
    if (_locationDirty &&
        (selectedState.value == null || selectedCity.value == null)) {
      AppSnackbar.error(message: 'select_state_and_city_error'.tr);
      return;
    }
    // WhatsApp optional hai — par bhara ho to poore 10 digit chahiye.
    final whatsapp = whatsappCtrl.text.trim();
    if (whatsapp.isNotEmpty && whatsapp.length != 10) {
      AppSnackbar.error(message: 'valid_whatsapp_error'.tr);
      return;
    }
    // GSTIN optional hai — khaali chhod sakte hain, par bhara ho to
    // format sahi hona chahiye.
    final gst = gstCtrl.text.trim().toUpperCase();
    if (gst.isNotEmpty && !TaxIdFormats.isValidGst(gst)) {
      AppSnackbar.error(message: 'valid_gst_error'.tr);
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
      if (diff(whatsapp, _me?.whatsappNumber) != null)
        'whatsappNumber': whatsapp,
      if (diff(websiteCtrl.text, _me?.website) != null)
        'website': websiteCtrl.text.trim(),
      if (diff(workAreaCtrl.text, _me?.workArea) != null)
        'workArea': workAreaCtrl.text.trim(),
      if (diff(gst, _me?.gstNumber) != null) 'gstNumber': gst,
      if (_locationDirty) ...{
        'workStateID': selectedState.value!.id,
        'workCityID': selectedCity.value!.id,
      },
    };

    if (fields.isEmpty && newLogo.value == null) {
      AppSnackbar.warning(message: 'no_changes_warning'.tr);
      return;
    }

    isSaving.value = true;
    try {
      final res = await _vendorApi.editVendorProfile(
        fields: fields,
        companyLogo: newLogo.value,
      );
      if (res.success) {
        // Pehle back, PHIR snackbar — ulta karne par `Get.back()` snackbar
        // ko hi band karta hai (GetX me snackbar ek route hai), screen
        // wahin reh jaati aur message bhi dikhta nahi.
        Get.back(result: true);
        AppSnackbar.success(
            message: res.message ?? 'profile_updated_success'.tr);
      } else {
        AppSnackbar.error(message: res.message ?? 'update_failed_generic'.tr);
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
