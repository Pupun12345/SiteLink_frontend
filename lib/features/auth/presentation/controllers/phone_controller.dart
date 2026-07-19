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
      AppSnackbar.error(message: 'Enter a valid 10-digit number');
      return;
    }
    isLoading.value = true;
    try {
      final response = await _authApi.sendRegisterOtp(phoneCtrl.text);
      if (response.success) {
        AppSnackbar.success(message: response.message ?? 'OTP sent successfully');
        // phone ko Get.arguments ke through OTP screen ko pass karte hain
        Get.toNamed(AppRoutes.otp, arguments: phoneCtrl.text);
      } else {
        AppSnackbar.error(message: response.message ?? 'Failed to send OTP');
      }
    } catch (_) {
      AppSnackbar.error(message: 'Error: Unable to send OTP');
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
