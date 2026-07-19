// ═══════════════════════════════════════════════════════════════════
//  PAYMENT CONFIG — Razorpay public key
// ═══════════════════════════════════════════════════════════════════
// Sirf KEY_ID yahan — public/client-safe key hai (Razorpay checkout
// isi se khulta hai). KEY_SECRET **kabhi bhi** app me nahi aata — wo
// sirf backend ke .env me rehta hai, signature-verification ke liye
// (dekho docs/RAZORPAY_PAYMENT_API_GUIDE.md).
class RazorpayConfig {
  RazorpayConfig._();

  static const String keyId = 'rzp_test_T0CJxzVeZJBxqQ';
}
