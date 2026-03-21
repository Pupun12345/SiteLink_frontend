import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewRequestController extends GetxController {
  final selectedRoles   = <String>[].obs;
  final quantities      = <String, int>{}.obs;
  final cityCtrl        = TextEditingController();
  final areaCtrl        = TextEditingController();
  final startDateCtrl   = TextEditingController();
  final duration        = ''.obs;
  final specialReqCtrl  = TextEditingController();
  final isLoading       = false.obs;

  void incrementQty(String role) {
    quantities[role] = (quantities[role] ?? 1) + 1;
  }

  void decrementQty(String role) {
    if ((quantities[role] ?? 1) > 1) {
      quantities[role] = (quantities[role] ?? 1) - 1;
    }
  }

  void submitRequest() async {
    if (selectedRoles.isEmpty) {
      Get.snackbar('Error', 'Please select at least one role',
          backgroundColor: const Color(0xFFFFEBEE), colorText: const Color(0xFFC62828));
      return;
    }
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // TODO: API
    isLoading.value = false;
    Get.back();
    Get.snackbar('Success ✅', 'Request submitted! Admin will respond within 24 hours.',
        backgroundColor: const Color(0xFFE8F5E9), colorText: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3));
  }

  @override
  void onClose() {
    cityCtrl.dispose();
    areaCtrl.dispose();
    startDateCtrl.dispose();
    specialReqCtrl.dispose();
    super.onClose();
  }
}
