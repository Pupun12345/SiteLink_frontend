import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
//  PLANS THEME — "SiteLink Plans" sub-brand palette (worker + vendor)
// ═══════════════════════════════════════════════════════════════════
// Worker aur vendor dono ke subscription screens isi ek palette se
// consistent dikhte hain (design reference ke exact shades).
class PlansTheme {
  PlansTheme._();

  static const Color amber      = Color(0xFFF5A623);
  static const Color amberDark  = Color(0xFF7A5200);
  static const Color amberSoft  = Color(0xFFFFF4E0);
  static const Color navy       = Color(0xFF16202E);
  static const Color ink        = Color(0xFF111827);
  static const Color grey       = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);

  // Vendor "Standard Plan" CTA — soft blue-lavender (Premium ka amber
  // CTA se visually distinct rakhne ke liye).
  static const Color lavender     = Color(0xFFDCE3F0);
  static const Color lavenderDark = Color(0xFF1E3A5F);
}
