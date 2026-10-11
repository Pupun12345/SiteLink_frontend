import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/config/app_config.dart';
import '../../app/routes/app_routes.dart';
import 'session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  DEEP LINK SERVICE — bahar se aaye link ko sahi screen tak pahunchana
// ═══════════════════════════════════════════════════════════════════
// Do tarah ke link support karte hain, dono ek hi jagah pahunchte hain:
//
//   sitelink://post/<id>              custom scheme (hamesha kaam karta)
//   http(s)://<host>/p/<id>           chat me clickable, App Link
//
// Do raaste bhi hain jinse link aata hai:
//   • app band thi  → `getInitialLink()` (cold start)
//   • app khuli thi → `uriLinkStream` (warm)
// Dono ek hi handler pe jaate hain.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  /// Login se pehle aaya link — user pehle auth karega, uske baad yahan
  /// se uthaya jaayega. Warna link kho jaata hai aur user ko wo post
  /// kabhi nahi milti jiske liye usne app install ki thi.
  Uri? _pending;

  /// `main()` me `runApp` ke baad ek baar. Idempotent hai.
  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial, fromColdStart: true);
      _sub = _appLinks.uriLinkStream.listen(
        _handle,
        onError: (e) => debugPrint('[DeepLink] stream error: $e'),
      );
    } catch (e) {
      debugPrint('[DeepLink] init failed: $e');
    }
  }

  /// Login/registration poora hone ke baad call karo — agar user kisi
  /// link se aaya tha to ab usi post pe pahunch jaayega.
  void resumePending() {
    final uri = _pending;
    if (uri == null) return;
    _pending = null;
    _route(uri);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  void _handle(Uri uri, {bool fromColdStart = false}) {
    debugPrint('[DeepLink] received: $uri (cold: $fromColdStart)');
    // Logged out user ko post pe bhejne ka fayda nahi — screen pe API
    // 401 dega. Link sambhal ke rakho, auth ke baad khol denge.
    // (Cold start pe binding abhi register na hui ho to bhi pending.)
    if (!Get.isRegistered<SessionService>() ||
        !SessionService.to.isLoggedIn) {
      _pending = uri;
      return;
    }
    // Cold start pe navigator abhi ready nahi hota — ek frame ruk jao.
    if (fromColdStart) {
      Future.delayed(const Duration(milliseconds: 400), () => _route(uri));
    } else {
      _route(uri);
    }
  }

  void _route(Uri uri) {
    final target = parseLink(uri);
    if (target == null) {
      debugPrint('[DeepLink] samajh nahi aaya, ignore: $uri');
      return;
    }
    switch (target.kind) {
      case DeepLinkKind.post:
        Get.toNamed(AppRoutes.postDetail, arguments: target.id);
      case DeepLinkKind.job:
        // Job detail screen worker/vendor dono ke liye ek hi hai —
        // wahi shared link kholta hai, chahe kisne bhi bheja ho.
        Get.toNamed(AppRoutes.workerJobDetail,
            arguments: {'apiId': target.id});
    }
  }

  /// Dono link shapes samajhta hai:
  ///   sitelink://post/<id>  /  https://host/p/<id>   → post
  ///   sitelink://job/<id>   /  https://host/j/<id>   → job
  ///
  /// `static` + public isliye ki iska test likhna aasaan rahe.
  static DeepLinkTarget? parseLink(Uri uri) {
    final segments =
        uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();

    // Custom scheme — kind host me, id pehle segment me
    if (uri.scheme == AppConfig.appScheme) {
      if (segments.isEmpty) return null;
      final kind = _kindFromWord(uri.host);
      return kind == null ? null : DeepLinkTarget(kind, segments.first);
    }

    // Web link — kind pehle segment me, id doosre me
    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        segments.length >= 2) {
      final kind = _kindFromWord(segments.first);
      return kind == null ? null : DeepLinkTarget(kind, segments[1]);
    }
    return null;
  }

  /// Chhota (`p`/`j`) aur poora (`post`/`job`) dono roop chalte hain —
  /// share link chhota bhejta hai, par purane/manually type kiye link
  /// bhi na toote.
  static DeepLinkKind? _kindFromWord(String word) {
    switch (word.toLowerCase()) {
      case 'p':
      case 'post':
        return DeepLinkKind.post;
      case 'j':
      case 'job':
        return DeepLinkKind.job;
      default:
        return null;
    }
  }
}

enum DeepLinkKind { post, job }

class DeepLinkTarget {
  final DeepLinkKind kind;
  final String id;
  const DeepLinkTarget(this.kind, this.id);
}
