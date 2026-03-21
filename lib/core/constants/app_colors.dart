import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand ──────────────────────────────────────────────
  static const Color primary        = Color(0xFFE65100); // Deep Orange
  static const Color primaryDark    = Color(0xFFBF3600); // Pressed / Dark
  static const Color secondary      = Color(0xFFF9A825); // Amber Yellow

  // ── Backgrounds ────────────────────────────────────────────────
  static const Color scaffoldBg     = Color(0xFFF5F5F5);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color selectionBg    = Color(0xFFFFF3E0); // orange tint card

  // ── Text ───────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF757575);
  static const Color textHint       = Color(0xFF9E9E9E);
  static const Color textMuted      = Color(0xFFBDBDBD);

  // ── Status ─────────────────────────────────────────────────────
  static const Color success        = Color(0xFF2E7D32);
  static const Color successLight   = Color(0xFFE8F5E9);
  static const Color error          = Color(0xFFC62828);
  static const Color errorLight     = Color(0xFFFFEBEE);
  static const Color warning        = Color(0xFFFF8F00);
  static const Color warningLight   = Color(0xFFFFF3E0);
  static const Color info           = Color(0xFF1565C0);
  static const Color infoLight      = Color(0xFFE3F2FD);

  // ── Divider / Border ───────────────────────────────────────────
  static const Color divider        = Color(0xFFE0E0E0);
  static const Color border         = Color(0xFFE0E0E0);
  static const Color borderFocus    = Color(0xFFE65100);

  // ── Gradient Stops ─────────────────────────────────────────────
  static const List<Color> primaryGradient = [primary, primaryDark];

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Shadows ────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primary.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  // ── Role Colors ────────────────────────────────────────────────
  static const Color vendorColor    = Color(0xFF1565C0);
  static const Color workerColor    = Color(0xFF2E7D32);
}
