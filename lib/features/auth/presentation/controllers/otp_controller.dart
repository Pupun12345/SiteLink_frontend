import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  OTP CONTROLLER — verify OTP, save session, route by role
// ═══════════════════════════════════════════════════════════════════
class OtpController extends GetxController {
  // phone Get.arguments se aata hai (PhoneController ne pass kiya)
  late final String phone;

  final List<TextEditingController> otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final isLoading = false.obs;
  final secondsLeft = 45.obs;
  final _authApi = AuthApiService();

  /// FCM device token backend me save (login ke baad, fail-safe).
  Future<void> _saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken() ?? '';
      if (token.isNotEmpty) await MiscApiService().saveFcmToken(token);
    } catch (_) {/* FCM unavailable — ignore */}
  }

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
    if (otp.length < 6) {
      AppSnackbar.error(message: 'Please enter complete OTP');
      return;
    }
    isLoading.value = true;
    try {
      final response = await _authApi.verifyOtp(phone, otp);
      if (response.success && response.token != null) {
        await SessionService.to
            .saveSession(token: response.token!, user: response.user);
        _saveFcmToken(); // push notifications ke liye (fire & forget)
        AppSnackbar.success(message: 'OTP verified successfully');
        _navigateByRole(response.user?.userType);
      } else {
        AppSnackbar.error(
            message: response.message ?? 'Invalid OTP. Please try again.');
      }
    } catch (_) {
      AppSnackbar.error(message: 'Error: Unable to verify OTP');
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateByRole(String? userTypeRaw) {
    final userType = (userTypeRaw ?? '').toLowerCase();
    if (userType == 'worker') {
      Get.offAllNamed(AppRoutes.workerHome);
    } else if (userType == 'vendor') {
      Get.offAllNamed(AppRoutes.vendorHome);
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
        AppSnackbar.success(message: 'OTP resent successfully');
      } else {
        AppSnackbar.error(message: response.message ?? 'Failed to resend OTP');
      }
    } catch (_) {
      AppSnackbar.error(message: 'Error: Unable to resend OTP');
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
