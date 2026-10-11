import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  TAX ID FORMATS — PAN / GSTIN ke shared format rules
// ═══════════════════════════════════════════════════════════════════
// PAN aur GSTIN har jagah ek hi tarah validate + format hone chahiye
// (vendor registration, edit company profile, …). Regex ya length
// kahin aur hardcode mat karo — yahin se lo.
class TaxIdFormats {
  TaxIdFormats._();

  // ── PAN: ABCDE1234F (5 letters + 4 digits + 1 letter) ─────────────
  static const int panLength = 10;
  static final RegExp panPattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  /// PAN ke 4th char entity type hota hai (P=individual, C=company,
  /// F=firm, H=HUF, T=trust …) aur 5th char surname/name ka pehla
  /// akshar — inko alag se check nahi kar rahe, sirf shape validate.
  static bool isValidPan(String value) =>
      panPattern.hasMatch(value.trim().toUpperCase());

  // ── GSTIN: 22ABCDE1234F1Z5 ────────────────────────────────────────
  //  [0-1]   state code (01-38)
  //  [2-11]  PAN
  //  [12]    entity number (1-9 / A-Z)
  //  [13]    hamesha 'Z'
  //  [14]    checksum (0-9 / A-Z)
  static const int gstLength = 15;
  static final RegExp gstPattern =
      RegExp(r'^[0-3][0-9][A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

  static bool isValidGst(String value) =>
      gstPattern.hasMatch(value.trim().toUpperCase());

  // ── Field ke input formatters ─────────────────────────────────────
  static List<TextInputFormatter> get panInput => [
        UpperCaseAlphanumericFormatter(),
        LengthLimitingTextInputFormatter(panLength),
      ];

  static List<TextInputFormatter> get gstInput => [
        UpperCaseAlphanumericFormatter(),
        LengthLimitingTextInputFormatter(gstLength),
      ];
}

/// Typing ke waqt hi CAPITAL kar deta hai aur space/symbol drop kar
/// deta hai — PAN/GSTIN dono sirf A-Z aur 0-9 allow karte hain.
class UpperCaseAlphanumericFormatter extends TextInputFormatter {
  static final RegExp _disallowed = RegExp(r'[^A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.toUpperCase().replaceAll(_disallowed, '');
    // Cursor ko utna hi peeche khiskao jitne chars gire hain, warna
    // beech me type karte waqt caret jump karta hai.
    final removed = newValue.text.length - cleaned.length;
    final offset = (newValue.selection.end - removed).clamp(0, cleaned.length);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
