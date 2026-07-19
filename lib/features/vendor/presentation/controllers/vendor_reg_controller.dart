import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR REGISTRATION — POST /api/profile/create/vendor (multipart)
// ═══════════════════════════════════════════════════════════════════
// Backend required: companyName, name, designation, panNumber (text)
//                 + panCardImage, gstCertificate (files)
// Optional: email, gstNumber, whatsappNumber, website, workArea,
//           workStateID + workCityID (dono saath), companyLogo, profileImage.
class VendorRegController extends GetxController {
  final _vendorApi   = VendorApiService();
  final _locationApi = LocationApiService();
  final _picker      = ImagePicker();

  // ── Text fields ──────────────────────────────────────────────
  final companyNameCtrl   = TextEditingController();
  final contactPersonCtrl = TextEditingController(); // = name
  final designationCtrl   = TextEditingController();
  final panCtrl           = TextEditingController();
  final gstCtrl           = TextEditingController();
  final emailCtrl         = TextEditingController();
  final whatsappCtrl      = TextEditingController();
  final workAreaCtrl      = TextEditingController();

  // ── Location (API-driven) ────────────────────────────────────
  final allStates = <StateModel>[].obs;
  final allCities = <CityModel>[].obs;
  final selectedState = Rxn<StateModel>();
  final selectedCity  = Rxn<CityModel>();
  final isLoadingCities = false.obs;

  // ── Files ────────────────────────────────────────────────────
  final panCardImage   = Rxn<File>(); // MANDATORY
  final gstCertificate = Rxn<File>(); // MANDATORY
  final companyLogo    = Rxn<File>();

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _prefillFromSession();
    _loadStates();
  }

  /// Google/OTP login ke baad session me jo naam/email hai (Google se
  /// aata hai) use registration form me pre-fill — user ko dobara na
  /// likhna pade. OTP-only user ke liye ye khaali reh sakte hain.
  void _prefillFromSession() {
    final user = SessionService.to.user;
    final name = user?.name ?? SessionService.to.userName;
    if (contactPersonCtrl.text.trim().isEmpty && name.isNotEmpty) {
      contactPersonCtrl.text = name;
    }
    final email = user?.email ?? '';
    if (emailCtrl.text.trim().isEmpty && email.isNotEmpty) {
      emailCtrl.text = email;
    }
  }

  Future<void> _loadStates() async {
    try {
      final res = await _locationApi.getStates();
      if (res.success) allStates.assignAll(res.data);
    } catch (_) {/* dropdown khaali rahega, retry submit pe */}
  }

  Future<void> onStateChanged(StateModel? st) async {
    if (st == null) return;
    selectedState.value = st;
    selectedCity.value = null;
    isLoadingCities.value = true;
    try {
      final res = await _locationApi.getCities(st.id!);
      allCities.assignAll(res.success ? res.data : const []);
    } finally {
      isLoadingCities.value = false;
    }
  }

  Future<void> pickFile(Rxn<File> target, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1600);
      if (picked != null) target.value = File(picked.path);
    } catch (_) {
      AppSnackbar.error(message: 'Image pick nahi ho paayi');
    }
  }

  Future<void> submit() async {
    if (isLoading.value) return;

    // ── Validation (backend requirements) ──────────────────────
    if (companyNameCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'Company name required hai');
      return;
    }
    if (contactPersonCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'Contact person ka naam required hai');
      return;
    }
    if (designationCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'Designation required hai');
      return;
    }
    final pan = panCtrl.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
      AppSnackbar.error(message: 'Valid PAN number daalein (ABCDE1234F)');
      return;
    }
    if (panCardImage.value == null) {
      AppSnackbar.error(message: 'PAN card ki photo upload karein');
      return;
    }
    if (gstCertificate.value == null) {
      AppSnackbar.error(message: 'GST certificate upload karein');
      return;
    }
    // State/city: dono ya koi nahi
    if ((selectedState.value == null) != (selectedCity.value == null)) {
      AppSnackbar.error(message: 'State aur city dono select karein');
      return;
    }

    isLoading.value = true;
    try {
      final res = await _vendorApi.createVendorProfile(
        fields: {
          'companyName': companyNameCtrl.text.trim(),
          'name': contactPersonCtrl.text.trim(),
          'designation': designationCtrl.text.trim(),
          'panNumber': pan,
          if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
          if (gstCtrl.text.trim().isNotEmpty)
            'gstNumber': gstCtrl.text.trim().toUpperCase(),
          if (whatsappCtrl.text.trim().isNotEmpty)
            'whatsappNumber': whatsappCtrl.text.trim(),
          if (workAreaCtrl.text.trim().isNotEmpty)
            'workArea': workAreaCtrl.text.trim(),
          if (selectedState.value != null) ...{
            'workStateID': selectedState.value!.id,
            'workCityID': selectedCity.value!.id,
          },
        },
        panCardImage: panCardImage.value!,
        gstCertificate: gstCertificate.value!,
        companyLogo: companyLogo.value,
      );

      if (res.success) {
        // userType persist — dobara registration na maange
        await SessionService.to.setUserType('vendor');
        AppSnackbar.success(
            message: res.message ?? 'Vendor profile created successfully');
        Get.offAllNamed(AppRoutes.vendorHome);
      } else {
        AppSnackbar.error(message: res.message ?? 'Profile create nahi hua');
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    companyNameCtrl.dispose();
    contactPersonCtrl.dispose();
    designationCtrl.dispose();
    panCtrl.dispose();
    gstCtrl.dispose();
    emailCtrl.dispose();
    whatsappCtrl.dispose();
    workAreaCtrl.dispose();
    super.onClose();
  }
}
