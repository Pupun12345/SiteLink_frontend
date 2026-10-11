import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  LOGOUT — poore app me ek hi jagah se
// ═══════════════════════════════════════════════════════════════════
// Pehle ye sequence teen jagah copy-paste thi (worker settings, vendor
// profile, legacy profile screen) aur kisi me bhi double-tap guard nahi
// tha. Worker wala dialog band bhi nahi karta tha, isliye user "Logout"
// baar-baar dabata tha aur har tap poora logout chala deta tha — kai
// API calls, kai navigation.
//
// Ab: ek in-flight guard + blocking loader. Kitni baar bhi tap ho,
// logout ek hi baar chalta hai.

/// Logout chal raha hai? Module-level hai (kisi controller pe nahi) taaki
/// guard un screens par bhi lage jinke paas apna controller nahi hai.
bool _loggingOut = false;

/// Abhi logout chal raha hai — UI isse button disable kar sakta hai.
bool get isLoggingOut => _loggingOut;

/// Poora logout: backend token blacklist → Firebase/Google sign-out →
/// local session clear → language screen.
///
/// Confirm dialog khula ho to pehle use band karta hai, phir ek
/// non-dismissible loader dikhata hai. Ek baar me ek hi logout chalta
/// hai; chalu hone par baaki taps ignore ho jaate hain.
///
/// Koi step fail ho to bhi local session clear hota hai aur user bahar
/// nikal jaata hai — warna user "aadha logged in" atak jaata (token
/// local me pada, par backend/Firebase ka state alag).
Future<void> performLogout() async {
  if (_loggingOut) return;
  _loggingOut = true;

  // Confirm dialog band karo — warna loader uske upar khulega.
  if (Get.isDialogOpen ?? false) Get.back();

  Get.dialog(
    const _LogoutLoader(),
    barrierDismissible: false,
  );

  try {
    // Ye khud errors nigal leta hai (fail par false deta hai).
    await MiscApiService().logout();
  } catch (e) {
    if (kDebugMode) print('[Logout] backend logout failed: $e');
  }

  try {
    await AuthService.instance.signOut();
  } catch (e) {
    // Firebase/Google sign-out fail ho jaaye to bhi local logout zaroori.
    if (kDebugMode) print('[Logout] firebase sign-out failed: $e');
  }

  try {
    await SessionService.to.clear();
  } catch (e) {
    if (kDebugMode) print('[Logout] session clear failed: $e');
  }

  // Loader band karo, phir bahar. `offAllNamed` stack saaf kar deta hai,
  // par loader ko explicitly band karna zyada predictable hai.
  if (Get.isDialogOpen ?? false) Get.back();

  _loggingOut = false;
  Get.offAllNamed(AppRoutes.language);
}

// ── Blocking loader ─────────────────────────────────────────────────
// `PopScope(canPop: false)` — Android back se loader band na ho, warna
// user logout ke beech me hi wapas screen par aa jaata hai.
class _LogoutLoader extends StatelessWidget {
  const _LogoutLoader();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                'logging_out_label'.tr,
                style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
