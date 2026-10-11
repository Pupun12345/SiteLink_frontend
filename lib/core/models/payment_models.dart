// ═══════════════════════════════════════════════════════════════════
//  PAYMENT MODELS — Razorpay order create + verify
// ═══════════════════════════════════════════════════════════════════

/// POST /payments/create-order response — Razorpay order details jo
/// checkout kholne ke liye chahiye.
class CreateOrderResponse {
  final bool success;
  final String? message;
  final String? orderId; // Razorpay order_id (order_xxxxx)
  final num? amount;     // paise me (backend Razorpay se jaisा milta hai)
  final String? currency; // 'INR'
  final String? keyId;    // backend se bhi aa sakta hai (fallback: RazorpayConfig.keyId)

  const CreateOrderResponse({
    required this.success,
    this.message,
    this.orderId,
    this.amount,
    this.currency,
    this.keyId,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final d = data is Map ? data : json;
    return CreateOrderResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      orderId: (d['orderId'] ?? d['order_id'] ?? d['id'])?.toString(),
      amount: d['amount'] is num
          ? d['amount'] as num
          : num.tryParse(d['amount']?.toString() ?? ''),
      currency: d['currency']?.toString(),
      keyId: (d['keyId'] ?? d['key_id'] ?? d['key'])?.toString(),
    );
  }
}

/// POST /payments/verify-payment response.
class VerifyPaymentResponse {
  final bool success;
  final String? message;
  final DateTime? expiryDate;

  const VerifyPaymentResponse({
    required this.success,
    this.message,
    this.expiryDate,
  });

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final d = data is Map ? data : json;
    return VerifyPaymentResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      expiryDate: DateTime.tryParse(
          (d['expiryDate'] ?? d['expiresAt'] ?? '').toString()),
    );
  }
}

/// POST /payments/create-subscription response (auto-payment).
///
/// Order ke bajaye `subscriptionId` aata hai — Razorpay checkout ko
/// `subscription_id` bhejte hain, `order_id` nahi. Amount sirf display
/// ke liye hai; asli charge Razorpay plan se hota hai.
class CreateSubscriptionResponse {
  final bool success;
  final String? message;
  final String? subscriptionId; // sub_xxxxx
  final String? planName;
  final num? amount; // paise me
  final String? currency;
  final String? keyId;

  const CreateSubscriptionResponse({
    required this.success,
    this.message,
    this.subscriptionId,
    this.planName,
    this.amount,
    this.currency,
    this.keyId,
  });

  factory CreateSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final d = data is Map ? data : json;
    return CreateSubscriptionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      subscriptionId:
          (d['subscriptionId'] ?? d['subscription_id'] ?? d['id'])?.toString(),
      planName: d['planName']?.toString(),
      amount: d['amount'] is num
          ? d['amount'] as num
          : num.tryParse(d['amount']?.toString() ?? ''),
      currency: d['currency']?.toString(),
      keyId: (d['keyId'] ?? d['key_id'] ?? d['key'])?.toString(),
    );
  }
}

/// POST /payments/cancel-subscription response.
///
/// `activeTill` important hai: auto-pay band hone ke baad bhi plan usi
/// tareekh tak chalta hai (Razorpay par cancel_at_cycle_end), isliye UI
/// ko "abhi band ho gaya" nahi dikhana chahiye.
class CancelAutoPayResponse {
  final bool success;
  final String? message;
  final DateTime? activeTill;

  const CancelAutoPayResponse({
    required this.success,
    this.message,
    this.activeTill,
  });

  factory CancelAutoPayResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final d = data is Map ? data : json;
    return CancelAutoPayResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      activeTill: DateTime.tryParse((d['activeTill'] ?? '').toString()),
    );
  }
}
