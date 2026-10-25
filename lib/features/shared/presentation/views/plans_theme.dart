import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  PLANS THEME — "Sitelink Plans" sub-brand palette (worker + vendor)
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

  /// Abhi chal rahe plan ka accent — card border aur ACTIVE badge.
  /// Purchase palette (amber/navy) se alag rakha hai taaki "ye tumhara
  /// hai" aur "ye khareedo" nazar me hi alag dikhein.
  static const Color activeGreen = Color(0xFF10B981);

  // "Sitelink • A product of Smartnex Technologies" pill — halka neela,
  // taaki amber (khareedo) aur green (active) se alag dikhe.
  static const Color brandPillBg     = Color(0xFFEEF3FB);
  static const Color brandPillBorder = Color(0xFFB9C8E2);
  static const Color brandPillInk    = Color(0xFF1E3A5F);
}

/// Dono plans screens ke upar wali brand line. Worker design me ye
/// CAPITALS me hai, vendor design me normal case — isliye [uppercase].
class PlansBrandPill extends StatelessWidget {
  final bool uppercase;
  const PlansBrandPill({super.key, this.uppercase = false});

  @override
  Widget build(BuildContext context) {
    final text = 'plans_brand_pill'.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: PlansTheme.brandPillBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PlansTheme.brandPillBorder),
      ),
      child: Text(
        uppercase ? text.toUpperCase() : text,
        textAlign: TextAlign.center,
        style: KTextStyle.poppins(
          fs: 10.5,
          fw: FontWeight.w600,
          c: PlansTheme.brandPillInk,
          letterSpacing: uppercase ? 1.1 : 0.4,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Plans screens ke sabse neeche ki copyright line.
class PlansCopyright extends StatelessWidget {
  final TextAlign align;
  const PlansCopyright({super.key, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return Text(
      'plans_copyright'.tr,
      textAlign: align,
      style: KTextStyle.poppins(
          fs: 10.5, fw: FontWeight.w600, c: PlansTheme.ink, height: 1.4),
    );
  }
}
