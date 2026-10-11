import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/utils/tax_id_formats.dart';
import '../../../../core/utils/image_pick.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR REGISTRATION — POST /api/profile/create/vendor (multipart)
// ═══════════════════════════════════════════════════════════════════
// Required: companyName, name, designation, panNumber (text)
//           + gstCertificate (file)
// Optional: email, gstNumber, whatsappNumber, website, workArea,
//           workStateID + workCityID (dono saath), panCardImage,
//           companyLogo, profileImage.
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
  /// Contact number — backend par `user.phone`. Yahi number baad me OTP
  /// se badalta hai; WhatsApp number isse alag cheez hai.
  final phoneCtrl         = TextEditingController();
  final whatsappCtrl      = TextEditingController();
  final workAreaCtrl      = TextEditingController();

  // ── Location (API-driven) ────────────────────────────────────
  final allStates = <StateModel>[].obs;
  final allCities = <CityModel>[].obs;
  final selectedState = Rxn<StateModel>();
  final selectedCity  = Rxn<CityModel>();
  final isLoadingCities = false.obs;

  // ── Files ────────────────────────────────────────────────────
  final panCardImage   = Rxn<File>(); // optional
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
    // OTP se login kiya ho to phone pehle se hai — dobara na likhwao.
    final phone = user?.phone ?? '';
    if (phoneCtrl.text.trim().isEmpty && phone.isNotEmpty) {
      phoneCtrl.text = phone;
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
      // PAN / GST certificate — document preset, kyunki admin verify
      // karte waqt inka text padhta hai.
      final picked = await pickDocumentImage(_picker, source);
      if (picked != null) target.value = File(picked.path);
    } catch (_) {
      AppSnackbar.error(message: 'image_pick_failed'.tr);
    }
  }

  Future<void> submit() async {
    if (isLoading.value) return;

    // ── Validation (backend requirements) ──────────────────────
    if (companyNameCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'company_name_required_error'.tr);
      return;
    }
    if (contactPersonCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'contact_person_required_error'.tr);
      return;
    }
    if (designationCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'designation_required_error'.tr);
      return;
    }
    final pan = panCtrl.text.trim().toUpperCase();
    if (!TaxIdFormats.isValidPan(pan)) {
      AppSnackbar.error(message: 'valid_pan_required_error'.tr);
      return;
    }
    // GSTIN optional hai — par bhara ho to format sahi hona chahiye.
    final gst = gstCtrl.text.trim().toUpperCase();
    if (gst.isNotEmpty && !TaxIdFormats.isValidGst(gst)) {
      AppSnackbar.error(message: 'valid_gst_error'.tr);
      return;
    }
    // Contact number zaroori hai — yahi OTP se badalne wala number hai.
    final phoneNo = phoneCtrl.text.trim();
    if (phoneNo.length != 10 || !RegExp(r'^[6-9]').hasMatch(phoneNo)) {
      AppSnackbar.error(message: 'valid_phone_required_error'.tr);
      return;
    }

    // WhatsApp optional hai — par bhara ho to poore 10 digit chahiye.
    final whatsapp = whatsappCtrl.text.trim();
    if (whatsapp.isNotEmpty && whatsapp.length != 10) {
      AppSnackbar.error(message: 'valid_whatsapp_error'.tr);
      return;
    }
    // PAN card photo optional hai — bina uske bhi submit chalega.
    if (gstCertificate.value == null) {
      AppSnackbar.error(message: 'upload_gst_certificate_error'.tr);
      return;
    }
    // State/city: dono ya koi nahi
    if ((selectedState.value == null) != (selectedCity.value == null)) {
      AppSnackbar.error(message: 'select_state_and_city_error'.tr);
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
          'phone': phoneNo,
          if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
          if (gst.isNotEmpty) 'gstNumber': gst,
          if (whatsapp.isNotEmpty) 'whatsappNumber': whatsapp,
          if (workAreaCtrl.text.trim().isNotEmpty)
            'workArea': workAreaCtrl.text.trim(),
          if (selectedState.value != null) ...{
            'workStateID': selectedState.value!.id,
            'workCityID': selectedCity.value!.id,
          },
        },
        panCardImage: panCardImage.value,
        gstCertificate: gstCertificate.value!,
        companyLogo: companyLogo.value,
      );

      if (res.success) {
        // userType persist — dobara registration na maange
        await SessionService.to.setUserType('vendor');
        // Navigate pehle, snackbar baad me — snackbar GetX me ek route
        // hai, isliye pehle dikhane par wo navigation ke saath hi gayab
        // ho jaata tha aur user ko confirmation kabhi dikhta hi nahi tha.
        Get.offAllNamed(AppRoutes.vendorHome);
        AppSnackbar.success(
            message: res.message ?? 'vendor_profile_created_success'.tr);
      } else {
        AppSnackbar.error(message: res.message ?? 'profile_create_failed'.tr);
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
    phoneCtrl.dispose();
    whatsappCtrl.dispose();
    workAreaCtrl.dispose();
    super.onClose();
  }
}
