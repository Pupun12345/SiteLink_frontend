import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class KTextStyle {
  KTextStyle._();

  static TextStyle _build({
    required TextStyle Function({TextStyle? textStyle}) font,
    double fs = 14,
    Color c = AppColors.textPrimary,
    FontWeight fw = FontWeight.normal,
    FontStyle fontStyle = FontStyle.normal,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
    double? wordSpacing,
    Color? decorationColor,
  }) {
    return font().copyWith(
      fontSize: fs,
      color: c,
      fontWeight: fw,
      fontStyle: fontStyle,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
      wordSpacing: wordSpacing,
      decorationColor: decorationColor,
    );
  }

  static TextStyle poppins({
    double fs = 14,
    Color c = AppColors.textPrimary,
    FontWeight fw = FontWeight.normal,
    FontStyle fontStyle = FontStyle.normal,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
    double? wordSpacing,
    Color? decorationColor,
  }) =>
      _build(
        font: GoogleFonts.poppins,
        fs: fs,
        c: c,
        fw: fw,
        fontStyle: fontStyle,
        decoration: decoration,
        letterSpacing: letterSpacing,
        height: height,
        wordSpacing: wordSpacing,
        decorationColor: decorationColor,
      );
}

// ── Semantic shortcuts ─────────────────────────────────────────────────────
extension KTextStyleX on KTextStyle {
  // Headings
  static TextStyle get displayLarge => KTextStyle.poppins(fs: 32, fw: FontWeight.bold);
  static TextStyle get headingLarge => KTextStyle.poppins(fs: 20, fw: FontWeight.bold);
  static TextStyle get headingMedium => KTextStyle.poppins(fs: 18, fw: FontWeight.w600);
  static TextStyle get headingSmall => KTextStyle.poppins(fs: 16, fw: FontWeight.w600);

  // Body
  static TextStyle get bodyLarge => KTextStyle.poppins(fs: 15, fw: FontWeight.normal);
  static TextStyle get bodyMedium => KTextStyle.poppins(fs: 13, fw: FontWeight.normal, c: AppColors.textSecondary);
  static TextStyle get bodySmall => KTextStyle.poppins(fs: 12, fw: FontWeight.normal, c: AppColors.textSecondary);
  static TextStyle get bodyXSmall => KTextStyle.poppins(fs: 11, fw: FontWeight.normal, c: AppColors.textHint);

  // Labels
  static TextStyle get labelPrimary => KTextStyle.poppins(fs: 15, fw: FontWeight.w600, c: Colors.white);
  static TextStyle get labelSection => KTextStyle.poppins(fs: 14, fw: FontWeight.w600, c: AppColors.textPrimary);
  static TextStyle get labelHint => KTextStyle.poppins(fs: 12, fw: FontWeight.normal, c: AppColors.textSecondary);
  static TextStyle get labelField => KTextStyle.poppins(fs: 12, fw: FontWeight.w500, c: AppColors.textSecondary);

  // Status
  static TextStyle get badgeText => KTextStyle.poppins(fs: 11, fw: FontWeight.bold);
  static TextStyle get chipText => KTextStyle.poppins(fs: 11, fw: FontWeight.w500);

  // App bar
  static TextStyle get appBarTitle => KTextStyle.poppins(fs: 18, fw: FontWeight.w600, c: Colors.white);
}
