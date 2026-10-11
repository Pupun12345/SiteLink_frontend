import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  OTP CONTROLLER — verify OTP, save session, route by role
// ═══════════════════════════════════════════════════════════════════
class OtpController extends GetxController {
  // phone Get.arguments se aata hai (PhoneController ne pass kiya)
  late final String phone;

  final List<TextEditingController> otpCtrls = List.generate(
      AppConfig.otpLength, (_) => TextEditingController());
  final List<FocusNode> focusNodes =
      List.generate(AppConfig.otpLength, (_) => FocusNode());
  final isLoading = false.obs;
  final secondsLeft = 45.obs;
  final _authApi = AuthApiService();

  @override
  void onInit() {
    phone = (Get.arguments as String?) ?? '';
    super.onInit();
    _startTimer();
  }

  void _startTimer() async {
    secondsLeft.value = 45;
    while (secondsLeft.value > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (isClosed) return;
      secondsLeft.value--;
    }
  }

  void onOtpChanged(String val, int index) {
    if (val.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (val.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  String get otp => otpCtrls.map((c) => c.text).join();

  Future<void> verify() async {
    if (otp.length < AppConfig.otpLength) {
      AppSnackbar.error(message: 'enter_complete_otp_error'.tr);
      return;
    }
    isLoading.value = true;
    try {
      final response = await _authApi.verifyOtp(phone, otp);
      if (response.success && response.token != null) {
        await SessionService.to
            .saveSession(token: response.token!, user: response.user);
        // Push notifications ke liye FCM token backend ko bhejo — fire &
        // forget, par debug me token + SUCCESS/FAILED dono log hote hain.
        NotificationService.instance.syncTokenIfLoggedIn(label: 'otp-login');
        AppSnackbar.success(message: 'otp_verified_success'.tr);
        _navigateByRole(response.user?.userType);
      } else {
        AppSnackbar.error(
            message: response.message ?? 'invalid_otp_retry_error'.tr);
      }
    } catch (_) {
      AppSnackbar.error(message: 'verify_otp_error_generic'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateByRole(String? userTypeRaw) {
    final userType = (userTypeRaw ?? '').toLowerCase();
    if (userType == 'worker') {
      Get.offAllNamed(AppRoutes.workerHome);
      DeepLinkService.instance.resumePending();
    } else if (userType == 'vendor') {
      Get.offAllNamed(AppRoutes.vendorHome);
      DeepLinkService.instance.resumePending();
    } else {
      // Naya user — role select karna hai
      Get.offAllNamed(AppRoutes.role);
    }
  }

  Future<void> resend() async {
    _startTimer();
    try {
      final response = await _authApi.resendOtp(phone);
      if (response.success) {
        AppSnackbar.success(message: 'otp_resent_success'.tr);
      } else {
        // `message` non-nullable hai aur backend na bheje to "" hota hai —
        // `??` yahan kabhi nahi chalta tha, isliye blank snackbar aata tha.
        AppSnackbar.error(
            message: response.message.isNotEmpty
                ? response.message
                : 'resend_otp_failed'.tr);
      }
    } catch (_) {
      AppSnackbar.error(message: 'resend_otp_error_generic'.tr);
    }
  }

  @override
  void onClose() {
    for (final c in otpCtrls) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.onClose();
  }
}
