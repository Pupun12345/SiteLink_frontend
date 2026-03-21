import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/vendor_home_view.dart';

class VendorRegController extends GetxController {
  final companyNameCtrl   = TextEditingController();
  final contactPersonCtrl = TextEditingController();
  final designationCtrl   = TextEditingController();
  final workAreaCtrl      = TextEditingController();
  final gstCtrl           = TextEditingController();
  final city              = ''.obs;
  final isLoading         = false.obs;

  void submit() async {
    if (companyNameCtrl.text.isEmpty || contactPersonCtrl.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all required fields',
          backgroundColor: const Color(0xFFFFEBEE),
          colorText: const Color(0xFFC62828));
      return;
    }
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // TODO: API
    isLoading.value = false;
    Get.offAll(() => const VendorHomeView());
  }

  @override
  void onClose() {
    companyNameCtrl.dispose();
    contactPersonCtrl.dispose();
    designationCtrl.dispose();
    workAreaCtrl.dispose();
    gstCtrl.dispose();
    super.onClose();
  }
}
