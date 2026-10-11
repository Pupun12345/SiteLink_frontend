// ═══════════════════════════════════════════════════════════════════
//  MASK SECRET — debug logs me credentials poore print na ho
// ═══════════════════════════════════════════════════════════════════
// Firebase ID token, app JWT, FCM token — ye sab bearer credentials
// hain. Debug logs regularly copy-paste kiye jaate hain (bug report,
// chat, screenshot), aur poora token wahan chala jaaye to jiske paas
// pahunche wo us user ban sakta hai jab tak token valid hai.
//
// Prefix + suffix + length debug karne ke liye kaafi hai: token badla
// hai ya wahi hai, khaali hai ya nahi, ye sab pata chal jaata hai.

/// `"eyJhbGciOi…kzdF8 (len 812)"` — masked form for logs.
/// Khaali/chhoti value par masking ka koi matlab nahi, waise hi wapas.
String maskSecret(String? value, {int visible = 8}) {
  final v = value ?? '';
  if (v.isEmpty) return '(empty)';
  // Itni chhoti value credential hone ke liye kaafi nahi.
  if (v.length <= visible * 2) return '(len ${v.length})';
  return '${v.substring(0, visible)}…${v.substring(v.length - 5)} (len ${v.length})';
}
