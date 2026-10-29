import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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

  // ═════════════════════════════════════════════════════════════════
  //  ALLOWED PAYMENT METHODS — role ke hisaab se
  // ═════════════════════════════════════════════════════════════════
  // Vendor  → Card + Netbanking
  // Worker  → UPI  + Card
  //
  // Razorpay ke `method` block me har method ko EXPLICITLY false karna
  // padta hai. Sirf chahne wale ko true karna kaafi nahi — jo key
  // chhodi jaati hai wo default se enabled reh jaati hai aur checkout
  // par dikhti rehti hai.
  static Map<String, bool> _allowedMethods() {
    final isVendor = SessionService.to.userType == 'vendor';
    return {
      'card': true, // dono ke liye
      'upi': !isVendor,
      'netbanking': isVendor,
      // Baaki sab band — na worker ko chahiye na vendor ko.
      'wallet': false,
      'emi': false,
      'paylater': false,
      'cardless_emi': false,
    };
  }

  // ═════════════════════════════════════════════════════════════════
  //  EMAIL / PHONE — checkout par user se nahi maangte
  // ═════════════════════════════════════════════════════════════════
  // Email: Sitelink ke users phone se login karte hain, aksar email
  // hota hi nahi — box hamesha chhupa.
  //
  // Phone: Razorpay ko number chahiye hi (UPI / auto-pay mandate isi par
  // banta hai), isliye login wala number peeche se bhejte hain aur box
  // chhupa dete hain. Number na ho (sirf Google login) to box dikhana
  // padta hai — chhupa ke khaali bhejne par checkout fail ho jaata.
  static Map<String, Object> _contactOptions(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    final local = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final hasPhone = local.length == 10;
    return {
      'prefill': {
        if (hasPhone) 'contact': '+91$local',
      },
      'hidden': {
        'email': true,
        'contact': hasPhone,
      },
    };
  }

  static Future<PaymentResult> payForPlan(PlanModel plan) async {
    // Sirf backend se aaye real plan par payment ho sakti hai — order
    // banane ke liye asli planId chahiye. Screens par jo static fallback
    // price dikhti hai uska koi id nahi hota.
    final planId = plan.id;
    if (planId == null || planId.isEmpty) {
      if (kDebugMode) {
        print('[PaymentService] plan has no id — backend se plans load '
            'nahi hue (GET /plans/plans check karo)');
      }
      return PaymentResult(
          success: false, message: 'plan_not_available_error'.tr);
    }

    // ── Step 1: backend se Razorpay order banwao ──────────────────
    final orderRes = await _paymentApi.createOrder(planId);
    if (!orderRes.success || (orderRes.orderId ?? '').isEmpty) {
      if (kDebugMode) {
        print('[PaymentService] createOrder failed: ${orderRes.message}');
      }
      return PaymentResult(
          success: false,
          message: orderRes.message ?? 'order_create_failed'.tr);
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
                ? 'subscription_activated_msg'.tr
                : 'payment_verify_failed'.tr),
      ));
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (kDebugMode) {
        print('[PaymentService] checkout error ${r.code}: ${r.message}');
      }
      finish(PaymentResult(
        success: false,
        message: (r.message ?? '').isNotEmpty
            ? r.message!
            : 'payment_cancelled_error'.tr,
      ));
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      finish(PaymentResult(
        success: false,
        message: 'wallet_not_supported'.tr,
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
      // Role ke hisaab se: vendor → card+netbanking, worker → upi+card.
      'method': _allowedMethods(),
      'name': 'Sitelink',
      'description': plan.name ?? 'Subscription',
      // Email aur phone ka box nahi dikhate (_contactOptions dekho).
      ..._contactOptions(user?.phone),
      'theme': {'color': '#F97316'},
    };

    try {
      razorpay.open(options);
    } catch (e) {
      if (kDebugMode) print('[PaymentService] open error: $e');
      finish(PaymentResult(
          success: false, message: 'checkout_open_error'.tr));
    }

    return completer.future;
  }

  // ═════════════════════════════════════════════════════════════════
  //  AUTO-PAYMENT — Razorpay Subscriptions
  // ═════════════════════════════════════════════════════════════════
  // `payForPlan` se alag rakha gaya hai kyunki checkout options hi
  // different hain: `order_id` ki jagah `subscription_id` jaata hai,
  // aur success response me `subscriptionId` milti hai (orderId nahi).
  //
  // User ek baar mandate authorize karta hai, uske baad Razorpay har
  // cycle par khud charge karta hai — app khuli hone ki zaroorat nahi.
  // Renewals backend ko webhook se pata chalte hain.

  /// Auto-payment chalu karo. User kabhi bhi `cancelAutoPay()` se band
  /// kar sakta hai.
  static Future<PaymentResult> subscribeWithAutoPay(PlanModel plan) async {
    final planId = plan.id;
    if (planId == null || planId.isEmpty) {
      if (kDebugMode) {
        print('[PaymentService] plan has no id — backend se plans load '
            'nahi hue (GET /plans/plans check karo)');
      }
      return PaymentResult(
          success: false, message: 'plan_not_available_error'.tr);
    }

    // ── Step 1: backend se Razorpay subscription banwao ────────────
    final subRes = await _paymentApi.createSubscription(planId);
    if (!subRes.success || (subRes.subscriptionId ?? '').isEmpty) {
      if (kDebugMode) {
        print('[PaymentService] createSubscription failed: ${subRes.message}');
      }
      return PaymentResult(
        success: false,
        message: subRes.message ?? 'autopay_start_failed'.tr,
      );
    }

    final completer = Completer<PaymentResult>();
    final razorpay = Razorpay();

    void finish(PaymentResult result) {
      if (!completer.isCompleted) completer.complete(result);
      razorpay.clear();
    }

    // ── Step 2: mandate authorize → Step 3: backend se verify ──────
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse r) async {
      // Subscription checkout me Razorpay `subscriptionId` bhejta hai;
      // kuch SDK versions me ye null aata hai, isliye backend se jo id
      // mili thi wahi fallback hai.
      final verifyRes = await _paymentApi.verifySubscription(
        planId: planId,
        razorpaySubscriptionId: subRes.subscriptionId!,
        razorpayPaymentId: r.paymentId ?? '',
        razorpaySignature: r.signature ?? '',
      );
      finish(PaymentResult(
        success: verifyRes.success,
        message: verifyRes.message ??
            (verifyRes.success
                ? 'autopay_activated_msg'.tr
                : 'payment_verify_failed'.tr),
      ));
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (kDebugMode) {
        print('[PaymentService] autopay checkout error ${r.code}: ${r.message}');
      }
      finish(PaymentResult(
        success: false,
        message: (r.message ?? '').isNotEmpty
            ? r.message!
            : 'payment_cancelled_error'.tr,
      ));
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      finish(PaymentResult(success: false, message: 'wallet_not_supported'.tr));
    });

    final user = SessionService.to.user;

    final options = {
      'key': subRes.keyId ?? RazorpayConfig.keyId,
      // `subscription_id` hone par Razorpay khud recurring mandate ka
      // UI dikhata hai (UPI Autopay / card e-mandate). `amount` yahan
      // nahi bhejte — plan se aata hai; bhejne par checkout error deta hai.
      'subscription_id': subRes.subscriptionId,
      'currency': subRes.currency ?? 'INR',
      // Wahi role-based restriction. Dhyan rahe recurring mandate har
      // method par nahi banta — netbanking par e-mandate chahiye hota
      // hai, jo Razorpay account par alag se enable karwana padta hai.
      'method': _allowedMethods(),
      'name': 'Sitelink',
      'description': subRes.planName ?? plan.name ?? 'Subscription',
      // Mandate phone number par register hota hai — number peeche se
      // jaata hai, box nahi dikhta (_contactOptions dekho).
      ..._contactOptions(user?.phone),
      'theme': {'color': '#F97316'},
    };

    try {
      razorpay.open(options);
    } catch (e) {
      if (kDebugMode) print('[PaymentService] autopay open error: $e');
      finish(PaymentResult(success: false, message: 'checkout_open_error'.tr));
    }

    return completer.future;
  }

  /// Auto-payment band karo.
  ///
  /// Plan turant band nahi hota — jis period ka paisa de diya hai wo
  /// milta rahega (backend Razorpay par `cancel_at_cycle_end` bhejta
  /// hai). Bas aage paise nahi katenge.
  static Future<PaymentResult> cancelAutoPay() async {
    final res = await _paymentApi.cancelSubscription();
    return PaymentResult(
      success: res.success,
      message: res.message ??
          (res.success ? 'autopay_cancelled_msg'.tr : 'autopay_cancel_failed'.tr),
    );
  }
}
