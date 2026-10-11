import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  ROLE CONTROLLER — vendor / worker selection → registration
// ═══════════════════════════════════════════════════════════════════
class RoleController extends GetxController {
  final selectedRole = ''.obs; // 'vendor' | 'worker'

  /// "Change number" chalu hai — do baar tap / back se do logout na ho.
  final isLeaving = false.obs;

  /// Jis number/email se abhi login hua hai. Role screen pe dikhate hain
  /// taaki user ko saaf pata rahe wo kis account se aage badh raha hai —
  /// galat number ho to back se badal sake.
  String get loggedInAs {
    final user = SessionService.to.user;
    final phone = user?.phone ?? '';
    if (phone.isNotEmpty) return '+91 $phone';
    return user?.email ?? '';
  }

  void select(String role) => selectedRole.value = role;

  void proceed() {
    if (selectedRole.isEmpty) return;
    if (selectedRole.value == 'vendor') {
      Get.toNamed(AppRoutes.vendorRegistration);
    } else {
      Get.toNamed(AppRoutes.workerReg1);
    }
  }

  /// Back / "Change number" — wapas phone screen pe.
  ///
  /// Is screen tak user OTP verify karke aata hai, yaani session me token
  /// pehle se pada hai par registration adhoora hai. Isliye sirf navigate
  /// karna kaafi nahi — poora sign-out karke bhejte hain, warna agli baar
  /// splash isi adhoore session ko logged-in maan lega aur user phir yahin
  /// aa girega.
  Future<void> changeNumber() async {
    if (isLeaving.value) return;
    isLeaving.value = true;
    try {
      await MiscApiService()
          .logout(); // token blacklist (fail ho to bhi chalega)
      await AuthService.instance.signOut(); // Google/Firebase session
      await SessionService.to.clear();
      Get.offAllNamed(AppRoutes.phone);
    } finally {
      isLeaving.value = false;
    }
  }
}
