import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';

// ═══════════════════════════════════════════════════════════════════
//  ROLE CONTROLLER — vendor / worker selection → registration
// ═══════════════════════════════════════════════════════════════════
class RoleController extends GetxController {
  final selectedRole = ''.obs; // 'vendor' | 'worker'

  void select(String role) => selectedRole.value = role;

  void proceed() {
    if (selectedRole.isEmpty) return;
    if (selectedRole.value == 'vendor') {
      Get.toNamed(AppRoutes.vendorRegistration);
    } else {
      Get.toNamed(AppRoutes.workerReg1);
    }
  }
}
