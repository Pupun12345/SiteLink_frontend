import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/language_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  SPLASH CONTROLLER
// ═══════════════════════════════════════════════════════════════════
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
    Get.off(() => const LanguageView());
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LANGUAGE CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class LanguageController extends GetxController {
  final selectedLanguage = 'hindi'.obs; // 'hindi' | 'english'

  void select(String lang) => selectedLanguage.value = lang;

  void proceed() {
    // TODO: persist language via GetStorage
    Get.off(() => const _PhonePlaceholder()); // replaced below
  }
}

// placeholder — replaced in actual wiring
class _PhonePlaceholder extends StatelessWidget {
  const _PhonePlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold();
}
