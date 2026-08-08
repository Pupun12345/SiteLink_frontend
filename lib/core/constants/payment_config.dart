// ═══════════════════════════════════════════════════════════════════
//  PAYMENT CONFIG — Razorpay public key
// ═══════════════════════════════════════════════════════════════════
// Sirf KEY_ID yahan — public/client-safe key hai (Razorpay checkout
// isi se khulta hai). KEY_SECRET **kabhi bhi** app me nahi aata — wo
// sirf backend ke .env me rehta hai, signature-verification ke liye
// (dekho docs/RAZORPAY_PAYMENT_API_GUIDE.md).
class RazorpayConfig {
  RazorpayConfig._();

  // Sirf fallback hai — normally backend `createOrder` response me `keyId`
  // bhejta hai (PaymentService wahi prefer karta hai). Ye tabhi use hota
  // hai jab backend keyId na bheje, isliye ise backend ke .env wale
  // RAZORPAY_KEY_ID ke saath sync rakhna zaroori hai.
  static const String keyId = 'rzp_test_TKLVMznjJpwl5i';
}
