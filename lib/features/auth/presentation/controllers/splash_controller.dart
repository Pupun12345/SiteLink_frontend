import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/logout_service.dart';
import '../../../worker/presentation/controllers/worker_reg_controller.dart';

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
    NotificationService.instance.syncTokenIfLoggedIn(label: 'app-start');

    await _syncUserTypeFromServer(session);

    // Token expire nikla (401) → logout_service session saaf karke login
    // khol raha hai. Uske poora hone tak ruko aur home mat kholo.
    while (isLoggingOut) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!session.isLoggedIn) return;

    switch (session.userType) {
      case 'worker':
        Get.offAllNamed(AppRoutes.workerHome);
        DeepLinkService.instance.resumePending();
        break;
      case 'vendor':
        Get.offAllNamed(AppRoutes.vendorHome);
        DeepLinkService.instance.resumePending();
        break;
      default:
        Get.offAllNamed(AppRoutes.role);
        await _resumeWorkerRegistration();
    }
  }

  /// Phone par yaad role (worker / vendor) server se milao. Account kabhi
  /// worker se shuru hua aur baad me vendor ban gaya (ya ulta) to session
  /// purana role yaad rakhta tha — vendor ko worker ki screens dikhti thi
  /// (khaali skill, galat profile). Server jaldi jawab na de / net na ho
  /// to jo yaad hai wahi chalne do — app ka khulna nahi rukna chahiye.
  Future<void> _syncUserTypeFromServer(SessionService session) async {
    final local = session.userType;
    if (local != 'worker' && local != 'vendor') return;
    try {
      final me = await ProfileApiService()
          .getMe()
          .timeout(const Duration(seconds: 4));
      final server = (me.user?.userType ?? '').toLowerCase();
      if (me.success &&
          (server == 'worker' || server == 'vendor') &&
          server != local) {
        await session.setUserType(server);
      }
    } catch (_) {/* offline / slow — local role se hi chalo */}
  }

  /// Registration adhoora tha (aksar gallery khulte waqt Android ne app
  /// band kar diya) → user ko usi step par wapas le jao. Stack poora
  /// banate hain (Role → Step1 → … → current), taaki back button sahi
  /// chale. Step 1 ki screen hi WorkerRegController ko `Get.put` karti
  /// hai, isliye har push ke baad ek frame rukte hain.
  Future<void> _resumeWorkerRegistration() async {
    final step = WorkerRegController.pendingDraftStep();
    if (step == null) return;
    const order = [
      AppRoutes.workerReg1,
      AppRoutes.workerReg2,
      AppRoutes.workerReg3,
      AppRoutes.documentUpload,
    ];
    final last = order.indexOf(step);
    if (last < 0) return;
    for (var i = 0; i <= last; i++) {
      await WidgetsBinding.instance.endOfFrame;
      Get.toNamed(order[i]);
    }
  }
}
