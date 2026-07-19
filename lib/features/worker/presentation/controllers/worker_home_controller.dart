import 'package:get/get.dart';
import '../../../../core/services/notification_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER HOME CONTROLLER
//  Only handles bottom nav tab switching
// ═══════════════════════════════════════════════════════════════════
class WorkerHomeController extends GetxController {
  final tabIndex     = 0.obs;
  final hasActiveJob = true.obs;

  void changeTab(int i) => tabIndex.value = i;

  @override
  void onInit() {
    super.onInit();
    HomeTabSwitcher.register(changeTab);
  }

  @override
  void onClose() {
    HomeTabSwitcher.unregister(changeTab);
    super.onClose();
  }
}