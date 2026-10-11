import 'package:get/get.dart';
import '../../../../core/models/plan_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../shared/presentation/controllers/app_refresh.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR PLANS CONTROLLER — Standard + Premium subscription
// ═══════════════════════════════════════════════════════════════════
// GET /plans/plans (userType-filtered, same endpoint WorkerPlansView
// uses) se live price/id pull karte hain — plan name se match ("standard"
// / "premium"). API me plan na mile (abhi seed nahi hua ho) to design
// ke exact static price fallback (₹2,999 / ₹4,999) — WorkerPlansView
// jaisा hi resilience pattern.
class VendorPlansController extends GetxController {
  final _miscApi = MiscApiService();

  final isLoading = true.obs;
  final subscribingStandard = false.obs;
  final subscribingPremium  = false.obs;

  /// Cancel ka apna flag — subscribe wale ke saath share karne se spinner
  /// galat button par dikhta hai.
  final cancellingAutoPay  = false.obs;

  /// Usi `/plans/plans` call se — kaunsa plan chal raha hai aur kab tak.
  final subscription = const ActiveSubscription().obs;

  PlanModel? _standardFromApi;
  PlanModel? _premiumFromApi;

  // maxWorkers backend ke seedVendorPlans.js se milte hain (25 / 50). API
  // se plan aa jaye to wahi number dikhta hai, ye sirf fallback hai.
  static const _fallbackStandard = PlanModel(
      name: 'Standard Plan', price: 2999, duration: 'Month', maxWorkers: 25);
  static const _fallbackPremium = PlanModel(
      name: 'Premium Plan', price: 4999, duration: 'Month', maxWorkers: 50);

  PlanModel get standardPlan => _standardFromApi ?? _fallbackStandard;
  PlanModel get premiumPlan => _premiumFromApi ?? _fallbackPremium;

  @override
  void onInit() {
    super.onInit();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    isLoading.value = true;
    try {
      final res = await _miscApi.getPlans();
      if (res.success) {
        subscription.value = res.subscription;
        for (final p in res.data) {
          // Pehle backend ka `planType` dekho — wo authoritative hai
          // (enum: 'basic' | 'premium'). Naam par match karna nazuk tha:
          // yahan "standard" dhunda ja raha tha jabki backend "basic"
          // bhejta hai, isliye Standard plan kabhi match hi nahi hota tha
          // aur id-less fallback use ho jaata tha → payment fail.
          final type = (p.planType ?? '').toLowerCase();
          final name = (p.name ?? '').toLowerCase();
          final isPremium =
              type == 'premium' || (type.isEmpty && name.contains('premium'));
          final isBasic = type == 'basic' ||
              (type.isEmpty &&
                  (name.contains('standard') || name.contains('basic')));

          if (isPremium) {
            _premiumFromApi = p;
          } else if (isBasic) {
            _standardFromApi = p;
          }
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> subscribeStandard() =>
      _subscribe(standardPlan, subscribingStandard);
  Future<void> subscribePremium() =>
      _subscribe(premiumPlan, subscribingPremium);

  Future<void> _subscribe(PlanModel plan, RxBool flag) async {
    if (flag.value) return;
    flag.value = true;
    try {
      // Pehli baar plan lete hi auto-payment khud lag jaata hai — user ko
      // alag se chunna nahi padta. Band karne ka rasta banner me hamesha
      // maujood rehta hai (cancelAutoPay).
      //
      // Auto-renew pehle se chalu ho to dobara mandate NAHI banate: do
      // mandate ka matlab hai har cycle me do baar paisa katna. Us halat
      // me "Extend" ek baar ka payment hi rehta hai.
      final result = subscription.value.autoRenew
          ? await PaymentService.payForPlan(plan)
          : await PaymentService.subscribeWithAutoPay(plan);
      if (result.success) {
        AppSnackbar.success(message: result.message);
        // Nayi expiry turant banner/badge me dikhe.
        await _loadPlans();
        // Plan par depend karne wali baaki screens bhi — job quota aur
        // Contact Support ka lock. Warna paisa dene ke baad bhi purana
        // locked state dikhta rehta hai.
        await refreshAfterPlanChange();
      } else {
        AppSnackbar.error(message: result.message);
      }
    } finally {
      flag.value = false;
    }
  }

  // ── Auto-payment band karna ───────────────────────────────────────
  // Chalu karne ka alag method nahi hai — `_subscribe()` hi pehli baar
  // mandate bana deta hai. Yahan sirf band karne ka rasta hai, jo banner
  // se hamesha pahunch me rehta hai.

  Future<void> cancelAutoPay() async {
    if (cancellingAutoPay.value) return;
    cancellingAutoPay.value = true;
    try {
      final result = await PaymentService.cancelAutoPay();
      if (result.success) {
        AppSnackbar.success(message: result.message);
        // Plan band nahi hua — sirf autoRenew false hua. Reload isliye
        // ki banner se "Auto-renews" line hat jaye.
        await _loadPlans();
      } else {
        AppSnackbar.error(message: result.message);
      }
    } finally {
      cancellingAutoPay.value = false;
    }
  }
}
