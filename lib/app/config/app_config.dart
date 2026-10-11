/// ═══════════════════════════════════════════════════════════════════
///  APP CONFIG — Centralized configuration constants
/// ═══════════════════════════════════════════════════════════════════
/// Single source of truth for backend URLs, auth client IDs and timeouts.
/// Hardcoded values (baseUrl, Google serverClientId) yahan se aate hain —
/// controllers/services me hardcode mat karo.
class AppConfig {
  AppConfig._();

  // ── Backend ────────────────────────────────────────────────────────
  static const String baseUrl = 'https://app-sitelink.smartnex.tech/api';

  /// Same host as [baseUrl] but without the `/api` prefix — for static
  /// file URLs like `/uploads/...` which the backend serves from its
  /// root, not under `/api`. Build every such URL off this (or off
  /// [baseUrl] for actual endpoints) instead of hardcoding the host
  /// anywhere else in the app.
  static String get mediaBaseUrl =>
      baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;

  // ── OTP ─────────────────────────────────────────────────────────
  /// OTP kitne digit ka hai. Backend ke `utils/otpUtils.js` me
  /// `OTP_LENGTH` isi ke barabar hona chahiye — wahan generate hota
  /// hai aur validate bhi, yahan sirf UI banti hai. Dono me alag hone
  /// par har OTP "invalid" ho jayega, isliye badlo to dono jagah.
  static const int otpLength = 4;

  // ── Google Sign-In (web client ID from Firebase Console → Auth →
  //    Sign-in method → Google → Web client ID). google_sign_in v7 ko
  //    Android pe serverClientId chahiye. ──────────────────────────────
  static const String googleServerClientId =
      '162479249381-hfo46jvgq4c65dju78s8q2obgjitscgr.apps.googleusercontent.com';

  // ── Deep links / share ──────────────────────────────────────────────
  /// Share kiye gaye link ka base. Ye backend ka public host hai (`/api`
  /// ke bina) — wahan `GET /p/:postId` ek preview page deta hai jo app
  /// installed hone par app khol deta hai, warna Play Store.
  ///
  /// Asli https domain milte hi sirf yahi badalna hoga — baaki sab
  /// (manifest, backend) usi host se chalta hai.
  static String get shareBaseUrl => mediaBaseUrl;

  /// App ka apna URL scheme — `sitelink://post/<id>`. Custom scheme
  /// https domain ke bina bhi chalta hai, isliye yahi primary deep link
  /// hai; http link uske upar ek layer hai jo chat me clickable dikhta hai.
  static const String appScheme = 'sitelink';

  /// Ek post ka shareable link.
  static String postShareUrl(String postId) => '$shareBaseUrl/p/$postId';

  /// Ek job ka shareable link — vendor aur worker dono yahi bhejte hain.
  static String jobShareUrl(String jobId) => '$shareBaseUrl/j/$jobId';

  // ── Store listings (force-update ke liye) ───────────────────────────
  static const String androidPackage = 'com.sitelink.sitelink';
  static const String iosAppId = ''; // App Store Connect ka numeric id — live hone par bharo

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';
  static String get appStoreUrl =>
      iosAppId.isEmpty ? '' : 'https://apps.apple.com/app/id$iosAppId';

  // ── Network timeouts ────────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 60);
}
