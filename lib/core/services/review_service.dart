import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';

// ═══════════════════════════════════════════════════════════════════
//  APP REVIEW — Play Store ka in-app rating prompt
// ═══════════════════════════════════════════════════════════════════
// Rating tabhi maangte hain jab user ne abhi kuch acha kiya ho — post
// daali, job post ki, ya job par apply kiya. Us waqt user ka experience
// achha hota hai, isliye rating bhi behtar milti hai. App khulte hi
// maangna ulta padta hai.
//
// SIRF EK BAAR maangte hain. User ne ek baar dekh liya (chahe rating di
// ho ya nahi), dobara nahi poochte — baar-baar poochna irritating hai
// aur Play ki apni guideline bhi yahi kehti hai.
//
// ── Do baatein jo Google ke API ki hain, hamare control me nahi ─────
//
// 1. `requestReview()` GARANTEE nahi karta ki dialog dikhega. Play ka
//    apna quota hai (per user, per app, time-based). Aur API ye bhi
//    nahi batata ki dialog dikha ya nahi — jaan-boojh kar, taaki app
//    rating dene par kuch reward na de sake.
//
// 2. Ye sirf Play Store se install hui app me chalta hai. Debug ya
//    sideloaded build me kuch nahi hota.
//
// Isliye flag TABHI set karte hain jab `isAvailable()` true ho — warna
// debug testing me hi hamara "ek baar" wala mauka jal jaata aur asli
// user ko prompt kabhi milta hi nahi.
class ReviewService {
  ReviewService._();

  static const _kAsked = 'hasAskedForAppReview';

  static final GetStorage _box = GetStorage();
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Pehle hi maang chuke hain?
  static bool get alreadyAsked => _box.read<bool>(_kAsked) ?? false;

  /// Kisi achhe kaam ke turant baad bulao (post bani, job post hui,
  /// apply hua). Khud hi decide karta hai ki maangna hai ya nahi —
  /// caller ko koi check nahi karna.
  ///
  /// Kabhi throw nahi karta: rating maangna ek "nice to have" hai, uski
  /// wajah se asli kaam ka flow nahi tootna chahiye.
  static Future<void> maybeAsk() async {
    if (alreadyAsked) return;

    try {
      // Play Store se install nahi hui (debug/sideload) — chhod do aur
      // flag bhi mat lagao, taaki asli install par mauka bacha rahe.
      if (!await _inAppReview.isAvailable()) return;

      // Flag pehle set karte hain: `requestReview()` ke baad set karne
      // par, agar user prompt par hi app band kar de to hum dobara
      // maang baithte.
      await _box.write(_kAsked, true);
      await _inAppReview.requestReview();
    } catch (e) {
      if (kDebugMode) print('[Review] requestReview failed: $e');
    }
  }
}
