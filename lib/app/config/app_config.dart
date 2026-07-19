/// ═══════════════════════════════════════════════════════════════════
///  APP CONFIG — Centralized configuration constants
/// ═══════════════════════════════════════════════════════════════════
/// Single source of truth for backend URLs, auth client IDs and timeouts.
/// Hardcoded values (baseUrl, Google serverClientId) yahan se aate hain —
/// controllers/services me hardcode mat karo.
class AppConfig {
  AppConfig._();

  // ── Backend ────────────────────────────────────────────────────────
  static const String baseUrl = 'https://sitelink-backend-4.onrender.com/api';

  // ── Google Sign-In (web client ID from Firebase Console → Auth →
  //    Sign-in method → Google → Web client ID). google_sign_in v7 ko
  //    Android pe serverClientId chahiye. ──────────────────────────────
  static const String googleServerClientId =
      '790297960615-tmed2v4alvo96nddmre49ncttr8tap7i.apps.googleusercontent.com';

  // ── Network timeouts ────────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 60);
}
