import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand ──────────────────────────────────────────────
  static const Color primary        = Color(0xFFF97316); // Orange
  static const Color primaryLight   = Color(0xFFFFEDD5); // Light Orange
  static const Color secondary      = Color(0xFFFACC15); // Soft Yellow

  // ── Backgrounds ────────────────────────────────────────────────
  static const Color scaffoldBg     = Color(0xFFFFFBF7); // Warm light
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color selectionBg    = Color(0xFFFFF7ED); // very light orange

  // ── Text ───────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1C1917); // Warm black
  static const Color textSecondary  = Color(0xFF44403C);
  static const Color textHint       = Color(0xFF78716C);
  static const Color textMuted      = Color(0xFFA8A29E);

  // ── Status ─────────────────────────────────────────────────────
  static const Color success        = Color(0xFF16A34A);
  static const Color successLight   = Color(0xFFDCFCE7);
  static const Color error          = Color(0xFFDC2626);
  static const Color errorLight     = Color(0xFFFEE2E2);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningLight   = Color(0xFFFEF3C7);
  static const Color info           = Color(0xFFF97316);
  static const Color infoLight      = Color(0xFFFFEDD5);

  // ── Divider / Border ───────────────────────────────────────────
  static const Color divider        = Color(0xFFE7E5E4);
  static const Color border         = Color(0xFFE7E5E4);
  static const Color borderFocus    = Color(0xFFF97316);

  // ── Gradient Stops ─────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFBF7)
  ];

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFFFFFBF7), Color(0xFFFFF7ED)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Shadows ────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Role Colors (minimal change, same usage safe) ──────────────
  static const Color vendorColor    = Color(0xFFF97316);
  static const Color workerColor    = Color(0xFF16A34A);
}