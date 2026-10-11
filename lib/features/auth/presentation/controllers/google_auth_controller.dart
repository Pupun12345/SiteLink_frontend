import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  GOOGLE AUTH CONTROLLER
// ═══════════════════════════════════════════════════════════════════
// Google → Firebase handshake AuthService me centralize hai. Yeh controller
// sirf backend login + session save + role-based navigation handle karta hai.
class GoogleAuthController extends GetxController {
  final isLoading = false.obs;
  final _authApi = AuthApiService();

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final result = await AuthService.instance.signInWithGoogle();

      // FCM device token (push notifications) — optional, fail ho to ignore
      String deviceToken = '';
      try {
        deviceToken = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (_) {/* FCM unavailable */}

      final response = await _authApi.googleLogin(
        result.firebaseIdToken,
        deviceToken: deviceToken,
      );

      if (response.success && response.token != null) {
        await SessionService.to
            .saveSession(token: response.token!, user: response.user);
        // FCM token save-token endpoint pe bhi — debug me token +
        // SUCCESS/FAILED log hota hai (fire & forget).
        NotificationService.instance
            .syncTokenIfLoggedIn(label: 'google-login');
        AppSnackbar.success(
            message: 'welcome_user_greeting'
                .trParams({'name': result.displayName ?? 'default_user_name'.tr}));

        final userType = (response.user?.userType ?? '').toLowerCase();
        if (response.isNewUser == true || userType.isEmpty) {
          Get.offAllNamed(AppRoutes.role);
        } else if (userType == 'worker') {
          Get.offAllNamed(AppRoutes.workerHome);
          DeepLinkService.instance.resumePending();
        } else {
          Get.offAllNamed(AppRoutes.vendorHome);
          DeepLinkService.instance.resumePending();
        }
      } else {
        AppSnackbar.error(message: response.message ?? 'google_login_failed'.tr);
      }
    } on AuthException catch (e) {
      AppSnackbar.error(message: e.message);
    } catch (e) {
      debugPrint('[GoogleAuth] error: $e');
      AppSnackbar.error(message: 'google_signin_failed_retry'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // Yahan ek `signOut()` pada tha jise koi call nahi karta tha, aur wo
  // backend ka token blacklist (MiscApiService().logout()) bhi skip kar
  // deta tha. Logout ke liye core/services/logout_service.dart ka
  // `performLogout()` use karo — guard, loader aur poora sequence wahan hai.
}
