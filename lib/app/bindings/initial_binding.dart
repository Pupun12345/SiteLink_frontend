import 'package:get/get.dart';
import '../../core/services/api_services.dart'; // RestApi yahan define hai
import '../../core/services/auth_service.dart';
import '../../core/services/maintenance_service.dart';
import '../../core/services/session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  INITIAL BINDING — app-wide singletons (GetMaterialApp.initialBinding)
// ═══════════════════════════════════════════════════════════════════
// Pehle route build hone se pehle register ho jaate hain, isliye saare
// controllers/services inhe `Get.find` se safely use kar sakte hain.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SessionService>(SessionService(), permanent: true);
    Get.put<RestApi>(RestApi(), permanent: true);
    Get.put<AuthService>(AuthService.instance, permanent: true);
    // RestApi ke BAAD — MaintenanceService uspe depend karta hai.
    Get.put<MaintenanceService>(MaintenanceService(), permanent: true);
  }
}
