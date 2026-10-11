import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  PHONE CONTROLLER — phone number → send OTP
// ═══════════════════════════════════════════════════════════════════
class PhoneController extends GetxController {
  final phoneCtrl = TextEditingController();
  final isLoading = false.obs;
  final _authApi = AuthApiService();

  Future<void> sendOtp() async {
    if (phoneCtrl.text.length != 10) {
      AppSnackbar.error(message: 'enter_valid_mobile_error'.tr);
      return;
    }
    isLoading.value = true;
    try {
      final response = await _authApi.sendRegisterOtp(phoneCtrl.text);
      if (response.success) {
        // `message` non-nullable hai (backend na bheje to "") — `??` dead
        // tha, isliye khaali message par blank snackbar dikhta tha.
        AppSnackbar.success(
            message: response.message.isNotEmpty
                ? response.message
                : 'otp_sent_successfully'.tr);
        // phone ko Get.arguments ke through OTP screen ko pass karte hain
        Get.toNamed(AppRoutes.otp, arguments: phoneCtrl.text);
      } else {
        AppSnackbar.error(
            message: response.message.isNotEmpty
                ? response.message
                : 'otp_send_failed'.tr);
      }
    } catch (_) {
      AppSnackbar.error(message: 'send_otp_error_generic'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    super.onClose();
  }
}
