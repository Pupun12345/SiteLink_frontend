import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/payment_config.dart';
import '../models/plan_models.dart';
import 'api_client.dart';
import 'session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  PAYMENT SERVICE — Razorpay checkout orchestration (shared)
// ═══════════════════════════════════════════════════════════════════
// Worker aur Vendor dono ke "Plans" screen isi ek jagah se subscribe
// karte hain — order-create → Razorpay checkout → verify-payment, teeno
// steps yahan encapsulate hain. Razorpay SDK event-based hai, isliye
// Completer se ek clean `Future<PaymentResult>` bana diya — caller ko
// bas `await` karke result dikhana hai.
class PaymentResult {
  final bool success;
  final String message;
  const PaymentResult({required this.success, required this.message});
}

class PaymentService {
  PaymentService._();

  static final _paymentApi = PaymentApiService();

  static Future<PaymentResult> payForPlan(PlanModel plan) async {
    final planId = plan.id;
    if (planId == null || planId.isEmpty) {
      return const PaymentResult(
          success: false, message: 'Plan available nahi hai — dobara try karein');
    }

    // ── Step 1: backend se Razorpay order banwao ──────────────────
    final orderRes = await _paymentApi.createOrder(planId);
    if (!orderRes.success || (orderRes.orderId ?? '').isEmpty) {
      return PaymentResult(
          success: false,
          message: orderRes.message ?? 'Order create nahi ho paya');
    }

    final completer = Completer<PaymentResult>();
    final razorpay = Razorpay();

    void finish(PaymentResult result) {
      if (!completer.isCompleted) completer.complete(result);
      razorpay.clear();
    }

    // ── Step 2: checkout success → Step 3: backend se signature verify ──
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) async {
      final verifyRes = await _paymentApi.verifyPayment(
        planId: planId,
        razorpayOrderId: r.orderId ?? orderRes.orderId!,
        razorpayPaymentId: r.paymentId ?? '',
        razorpaySignature: r.signature ?? '',
      );
      finish(PaymentResult(
        success: verifyRes.success,
        message: verifyRes.message ??
            (verifyRes.success
                ? 'Subscription activated!'
                : 'Payment verify nahi hua'),
      ));
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      finish(PaymentResult(
        success: false,
        message: (r.message ?? '').isNotEmpty
            ? r.message!
            : 'Payment cancel ya fail ho gaya',
      ));
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      finish(PaymentResult(
        success: false,
        message: '${r.walletName ?? 'Wallet'} abhi supported nahi hai',
      ));
    });

    final user = SessionService.to.user;
    final amountPaise =
        (orderRes.amount ?? ((plan.price ?? 0) * 100)).toInt();

    final options = {
      'key': orderRes.keyId ?? RazorpayConfig.keyId,
      'amount': amountPaise,
      'currency': orderRes.currency ?? 'INR',
      'order_id': orderRes.orderId,
      'name': 'SiteLink',
      'description': plan.name ?? 'Subscription',
      'prefill': {
        'contact': user?.phone ?? '',
        'email': user?.email ?? '',
      },
      'theme': {'color': '#F97316'},
    };

    try {
      razorpay.open(options);
    } catch (e) {
      if (kDebugMode) print('[PaymentService] open error: $e');
      finish(const PaymentResult(
          success: false, message: 'Checkout khulne me error aayi'));
    }

    return completer.future;
  }
}
