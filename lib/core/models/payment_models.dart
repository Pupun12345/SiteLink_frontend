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
