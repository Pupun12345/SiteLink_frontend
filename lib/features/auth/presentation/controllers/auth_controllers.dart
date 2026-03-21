import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../vendor/presentation/views/vendor_reg_view.dart';
import '../../../worker/presentation/views/worker_reg_views.dart';
import '../views/auth_views.dart';

// ═══════════════════════════════════════════════════════════════════
//  LANGUAGE CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class LanguageController extends GetxController {
  final selectedLanguage = 'hindi'.obs;

  void select(String lang) => selectedLanguage.value = lang;

  void proceed() {
    // TODO: save to GetStorage
    Get.off(() => const PhoneView());
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PHONE CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class PhoneController extends GetxController {
  final phoneCtrl = TextEditingController();
  final isLoading = false.obs;

  void sendOtp() async {
    if (phoneCtrl.text.length != 10) {
      Get.snackbar('Error', 'Enter a valid 10-digit number',
          backgroundColor: Colors.red.shade100, colorText: Colors.red.shade800);
      return;
    }
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // TODO: API call
    isLoading.value = false;
    Get.to(() => OtpView(phone: phoneCtrl.text));
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    super.onClose();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  OTP CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class OtpController extends GetxController {
  final String phone;
  OtpController({required this.phone});

  final List<TextEditingController> otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final isLoading = false.obs;
  final secondsLeft = 45.obs;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  void _startTimer() async {
    while (secondsLeft.value > 0) {
      await Future.delayed(const Duration(seconds: 1));
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

  void verify() async {
    if (otp.length < 6) return;
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // TODO: verify API
    isLoading.value = false;
    Get.off(() => const RoleSelectionView());
  }

  void resend() {
    secondsLeft.value = 45;
    _startTimer();
    // TODO: resend OTP API
  }

  @override
  void onClose() {
    for (var c in otpCtrls) c.dispose();
    for (var f in focusNodes) f.dispose();
    super.onClose();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ROLE CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class RoleController extends GetxController {
  final selectedRole = ''.obs; // 'vendor' | 'worker'

  void select(String role) => selectedRole.value = role;

  void proceed() {
    if (selectedRole.isEmpty) return;
    // TODO: save role
    if (selectedRole.value == 'vendor') {
      Get.off(() => const VendorRegistrationView());
    } else {
      Get.off(() => const WorkerReg1View());
    }
  }
}








