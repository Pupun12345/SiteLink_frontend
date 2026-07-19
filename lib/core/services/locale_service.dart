import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'api_client.dart';
import 'session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  LOCALE SERVICE — app language (hindi/english) ka single source
// ═══════════════════════════════════════════════════════════════════
// Storage key 'language' backward-compatible hai (onboarding pehle isi
// key me likhta tha). setLanguage locale live switch karta hai
// (Get.updateLocale), persist karta hai, aur logged-in ho to backend
// (POST /profile/language) bhi sync karta hai.
class LocaleService extends GetxService {
  static LocaleService get to => Get.find<LocaleService>();

  final GetStorage _box = GetStorage();
  static const _kLanguage = 'language';

  static const Locale _en = Locale('en', 'US');
  static const Locale _hi = Locale('hi', 'IN');

  /// Stored language — 'hindi' | 'english' (default english).
  String get language =>
      (_box.read<String>(_kLanguage) ?? 'english').toLowerCase() == 'hindi'
          ? 'hindi'
          : 'english';

  bool get isHindi => language == 'hindi';

  Locale get currentLocale => isHindi ? _hi : _en;

  /// User ne language chuni — persist + live switch + backend sync.
  Future<void> setLanguage(String lang) async {
    final normalized = lang.toLowerCase() == 'hindi' ? 'hindi' : 'english';
    await _box.write(_kLanguage, normalized);
    Get.updateLocale(currentLocale);
    if (SessionService.to.isLoggedIn) {
      // fire & forget — UI ko block nahi karta
      MiscApiService().saveLanguage(normalized);
    }
  }

  /// getMe se aayi server-side language apply (cross-device restore).
  /// Sirf tab jab valid ho aur current se alag ho — backend ko dobara
  /// nahi bhejta (loop avoid).
  void applyFromProfile(String? serverLang) {
    final normalized = (serverLang ?? '').toLowerCase();
    if (normalized != 'hindi' && normalized != 'english') return;
    if (normalized == language) return;
    _box.write(_kLanguage, normalized);
    Get.updateLocale(currentLocale);
  }
}
