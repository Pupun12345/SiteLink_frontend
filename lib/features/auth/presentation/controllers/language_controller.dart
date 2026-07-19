import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/locale_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  LANGUAGE CONTROLLER (onboarding)
// ═══════════════════════════════════════════════════════════════════
class LanguageController extends GetxController {
  // Current app language se initialize (default english).
  final selectedLanguage = LocaleService.to.language.obs; // 'hindi' | 'english'

  /// Live preview — chunte hi UI language badal jaati hai.
  void select(String lang) {
    selectedLanguage.value = lang;
    LocaleService.to.setLanguage(lang);
  }

  void proceed() {
    LocaleService.to.setLanguage(selectedLanguage.value);
    Get.offNamed(AppRoutes.phone);
  }
}
