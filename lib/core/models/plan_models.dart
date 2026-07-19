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

  const PlanModel({
    this.id,
    this.name,
    this.price,
    this.duration,
    this.description,
    this.features = const [],
    this.userType,
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
    );
  }
}

class PlansResponse {
  final bool success;
  final String? message;
  final List<PlanModel> data;

  const PlansResponse({required this.success, this.message, this.data = const []});

  factory PlansResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = raw is List ? raw : (raw is Map ? (raw['plans'] as List?) : null);
    return PlansResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: list
              ?.whereType<Map>()
              .map((e) => PlanModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}
