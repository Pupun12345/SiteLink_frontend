import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  SPLASH CONTROLLER — auto-login (session-based) redirect
// ═══════════════════════════════════════════════════════════════════
// Pehle yeh stale version token ko ignore karke hamesha Language pe bhejta
// tha. Ab SessionService se logged-in user ko seedha dashboard bhejta hai.
class SplashController extends GetxController {
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    isLoading.value = false;

    final session = SessionService.to;
    if (!session.isLoggedIn) {
      Get.offAllNamed(AppRoutes.language);
      return;
    }

    // Token login ke baad hi bheja gaya tha — cold-start par dobara sync
    // taaki rotate/stale token backend me pura rahe. Fire-and-forget.
    NotificationService.instance.syncTokenIfLoggedIn();

    switch (session.userType) {
      case 'worker':
        Get.offAllNamed(AppRoutes.workerHome);
        break;
      case 'vendor':
        Get.offAllNamed(AppRoutes.vendorHome);
        break;
      default:
        Get.offAllNamed(AppRoutes.role);
    }
  }
}
