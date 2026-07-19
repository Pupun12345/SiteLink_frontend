import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/auth_service.dart';
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
        // FCM token save-token endpoint pe bhi (fire & forget)
        if (deviceToken.isNotEmpty) {
          MiscApiService().saveFcmToken(deviceToken);
        }
        AppSnackbar.success(
            message: 'Welcome, ${result.displayName ?? 'User'}!');

        final userType = (response.user?.userType ?? '').toLowerCase();
        if (response.isNewUser == true || userType.isEmpty) {
          Get.offAllNamed(AppRoutes.role);
        } else if (userType == 'worker') {
          Get.offAllNamed(AppRoutes.workerHome);
        } else {
          Get.offAllNamed(AppRoutes.vendorHome);
        }
      } else {
        AppSnackbar.error(message: response.message ?? 'Google login failed');
      }
    } on AuthException catch (e) {
      AppSnackbar.error(message: e.message);
    } catch (e) {
      debugPrint('[GoogleAuth] error: $e');
      AppSnackbar.error(message: 'Google sign-in failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    await SessionService.to.clear();
    Get.offAllNamed(AppRoutes.language);
  }
}
