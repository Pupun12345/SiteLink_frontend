// ═══════════════════════════════════════════════════════════════════
//  PLAN MODELS — GET /api/plans/plans (userType-filtered)
// ═══════════════════════════════════════════════════════════════════
// Response shape backend-driven hai, isliye parsing flexible rakhi hai —
// common keys (name/title, price/amount, duration/validity, features/benefits).

class PlanModel {
  final String? id;
  final String? name;
  final num? price;
  final String? duration; // 'yearly' / '1 Year' / etc.
  final String? description;
  final List<String> features;
  final String? userType;
  final String? planType; // backend enum: 'basic' | 'premium'

  /// Vendor plan me har mahine kitne workers post ho sakte hain. Backend
  /// isi number se job posting rokta hai, isliye screen par bhi yahi
  /// dikhana hai, hardcoded nahi. 0 = limit set nahi / worker plan.
  final int maxWorkers;

  /// Yahi plan abhi chal raha hai? Backend flag deta hai (subscription ke
  /// `planId` se match karke) — app ko naam/price se guess nahi karna padta.
  final bool isCurrentPlan;

  /// Real backend plan hai? Sirf inhi par payment ho sakta hai — order
  /// banane ke liye backend ko asli `planId` chahiye. Static/fallback
  /// PlanModel (sirf display price ke liye) me id nahi hoti.
  bool get isPayable => (id ?? '').isNotEmpty;

  const PlanModel({
    this.id,
    this.name,
    this.price,
    this.duration,
    this.description,
    this.features = const [],
    this.userType,
    this.planType,
    this.maxWorkers = 0,
    this.isCurrentPlan = false,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    num? parsePrice(dynamic v) =>
        v is num ? v : num.tryParse(v?.toString() ?? '');
    List<String> parseFeatures(dynamic v) {
      if (v is! List) return const [];
      return v
          .map((e) => e is Map
              ? (e['title'] ?? e['name'] ?? e['text'])?.toString() ?? ''
              : e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return PlanModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: (json['name'] ?? json['title'] ?? json['planName'])?.toString(),
      price: parsePrice(json['price'] ?? json['amount']),
      duration:
          (json['duration'] ?? json['validity'] ?? json['period'])?.toString(),
      description: json['description']?.toString(),
      features: parseFeatures(json['features'] ?? json['benefits']),
      userType: json['userType']?.toString(),
      planType: json['planType']?.toString(),
      maxWorkers: int.tryParse(json['maxWorkers']?.toString() ?? '') ?? 0,
      isCurrentPlan: json['isCurrentPlan'] == true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACTIVE SUBSCRIPTION — GET /api/plans/plans ka `subscription` block
// ═══════════════════════════════════════════════════════════════════
// Plans list ke saath hi aata hai, isliye Plans screen ko ek hi call me
// pata chal jaata hai ki koi plan chal raha hai ya nahi aur kab tak.
class ActiveSubscription {
  /// Abhi chal raha hai (status active + expiry future me).
  final bool active;

  /// 'active' | 'expired' | 'none'
  final String status;

  final String? planId;
  final String? planName;
  final String? frequency; // 'monthly' | 'yearly'
  final num? amount;

  final DateTime? startedAt;
  final DateTime? expiresAt;

  /// Aaj se expiry tak ke poore din. Aaj expire ho raha ho to 1.
  final int daysRemaining;

  /// 7 din ya kam bache — UI amber "renew soon" state dikhati hai.
  /// Auto-pay chalu ho to backend ise false bhejta hai: paise khud kat
  /// jayenge, user ko bekaar me "renew karo" nahi bolna chahiye.
  final bool expiringSoon;

  /// Auto-payment chalu hai? Razorpay har cycle par khud charge karega.
  /// UI isi se "Auto-renews" badge aur "Cancel auto-payment" dikhati hai.
  final bool autoRenew;

  const ActiveSubscription({
    this.active = false,
    this.status = 'none',
    this.planId,
    this.planName,
    this.frequency,
    this.amount,
    this.startedAt,
    this.expiresAt,
    this.daysRemaining = 0,
    this.expiringSoon = false,
    this.autoRenew = false,
  });

  /// Pehle kabhi plan liya tha par ab khatam ho chuka hai.
  bool get isExpired => !active && status == 'expired';

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      final s = v?.toString();
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s)?.toLocal();
    }

    return ActiveSubscription(
      active: json['active'] == true,
      status: json['status']?.toString() ?? 'none',
      planId: json['planId']?.toString(),
      planName: json['planName']?.toString(),
      frequency: json['frequency']?.toString(),
      amount: json['amount'] is num
          ? json['amount'] as num
          : num.tryParse(json['amount']?.toString() ?? ''),
      startedAt: parseDate(json['startedAt']),
      expiresAt: parseDate(json['expiresAt']),
      daysRemaining: (json['daysRemaining'] is num)
          ? (json['daysRemaining'] as num).toInt()
          : int.tryParse(json['daysRemaining']?.toString() ?? '') ?? 0,
      expiringSoon: json['expiringSoon'] == true,
      autoRenew: json['autoRenew'] == true,
    );
  }
}

class PlansResponse {
  final bool success;
  final String? message;
  final List<PlanModel> data;

  /// User ki apni subscription — purane backend se na aaye to default
  /// "none" (screen pehle jaisi hi dikhti hai, koi banner nahi).
  final ActiveSubscription subscription;

  const PlansResponse({
    required this.success,
    this.message,
    this.data = const [],
    this.subscription = const ActiveSubscription(),
  });

  factory PlansResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = raw is List ? raw : (raw is Map ? (raw['plans'] as List?) : null);
    final sub = json['subscription'];
    return PlansResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: list
              ?.whereType<Map>()
              .map((e) => PlanModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      subscription: sub is Map
          ? ActiveSubscription.fromJson(Map<String, dynamic>.from(sub))
          : const ActiveSubscription(),
    );
  }
}
