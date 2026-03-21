import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER HOME CONTROLLER
//  Only handles bottom nav tab switching
// ═══════════════════════════════════════════════════════════════════
class WorkerHomeController extends GetxController {
  final tabIndex     = 0.obs;
  final hasActiveJob = true.obs;

  void changeTab(int i) => tabIndex.value = i;
}