/// ═══════════════════════════════════════════════════════════════════
///  APP CONFIG MODELS — GET /api/app-config (public)
/// ═══════════════════════════════════════════════════════════════════

/// GET /api/legal/support-contact ka result.
///
/// Contact Support paid feature hai — plan na ho to backend 403 +
/// `SUBSCRIPTION_REQUIRED` deta hai. Isliye screen ko teen states me
/// farq karna padta hai: contact mil gaya, plan chahiye, ya admin ne
/// abhi kuch set hi nahi kiya. Sirf ek khaali map se teeno alag nahi
/// hote the.
class SupportContactResult {
  /// phone / whatsapp / email / hoursWeekday / ... — admin-managed.
  final Map<String, String> contact;

  /// Backend ka machine-readable error code, e.g. 'SUBSCRIPTION_REQUIRED'.
  final String? code;
  final String? message;

  const SupportContactResult({
    this.contact = const {},
    this.code,
    this.message,
  });

  /// Plan lena zaroori hai — screen locked state dikha kar Plans par bhejti hai.
  bool get needsSubscription => code == 'SUBSCRIPTION_REQUIRED';

  /// Koi ek bhi contact channel mila?
  bool get hasAnyContact => ['phone', 'whatsapp', 'email']
      .any((k) => (contact[k] ?? '').trim().isNotEmpty);
}

/// Admin panel se set hone wala maintenance notice. App dashboard par
/// ek dismissible info dialog ke roop me dikhta hai.
class MaintenanceInfo {
  final bool enabled;
  final String title;
  final String message;

  /// Maintenance kab tak (optional) — null ho to app "till ..." line
  /// nahi dikhata.
  final DateTime? until;

  /// Admin ne notice last kab badla. App isi se decide karta hai ki
  /// user ne jo dialog pehle dismiss kiya tha wahi notice hai ya naya.
  final String stamp;

  const MaintenanceInfo({
    required this.enabled,
    required this.title,
    required this.message,
    this.until,
    this.stamp = '',
  });

  factory MaintenanceInfo.fromJson(Map<String, dynamic> json) {
    final untilRaw = json['until']?.toString();
    return MaintenanceInfo(
      enabled: json['enabled'] == true,
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      until: (untilRaw == null || untilRaw.isEmpty)
          ? null
          : DateTime.tryParse(untilRaw),
      stamp: (json['updatedAt'] ?? '').toString(),
    );
  }
}
