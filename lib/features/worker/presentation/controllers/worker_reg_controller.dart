import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/worker_reg_views.dart';

class WorkerRegController extends GetxController {
  // Step 1
  final nameCtrl       = TextEditingController();
  final dobCtrl        = TextEditingController();
  final cityCtrl       = TextEditingController();
  final gender         = 'Male'.obs;

  // Step 2
  final primarySkill      = ''.obs;
  final additionalSkills  = <String>[].obs;
  final experienceYears   = 3.obs;
  final expDescCtrl       = TextEditingController();

  // Step 3
  final workCityCtrl      = TextEditingController();
  final preferredAreaCtrl = TextEditingController();
  final willRelocate      = true.obs;
  final salaryType        = 'daily'.obs;
  final salaryCtrl        = TextEditingController();

  // Document
  final selectedIdType  = 'Aadhaar'.obs;
  final idProofUploaded = false.obs;
  final workPhotos      = <String>[].obs;

  void submitStep3() {
    Get.to(() => const DocumentUploadView());
  }

  void submitDocuments() {
    // TODO: API call to submit profile
    Get.off(() => const ProfilePendingView());
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    dobCtrl.dispose();
    cityCtrl.dispose();
    expDescCtrl.dispose();
    workCityCtrl.dispose();
    preferredAreaCtrl.dispose();
    salaryCtrl.dispose();
    super.onClose();
  }
}
