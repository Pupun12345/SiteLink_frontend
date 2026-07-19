import 'package:get/get.dart';
import '../../../../core/models/plan_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_snackbar.dart';

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

  PlanModel? _standardFromApi;
  PlanModel? _premiumFromApi;

  static const _fallbackStandard =
      PlanModel(name: 'Standard Plan', price: 2999, duration: 'Month');
  static const _fallbackPremium =
      PlanModel(name: 'Premium Plan', price: 4999, duration: 'Month');

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
        for (final p in res.data) {
          final n = (p.name ?? '').toLowerCase();
          if (n.contains('premium')) {
            _premiumFromApi = p;
          } else if (n.contains('standard')) {
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
      final result = await PaymentService.payForPlan(plan);
      if (result.success) {
        AppSnackbar.success(message: result.message);
      } else {
        AppSnackbar.error(message: result.message);
      }
    } finally {
      flag.value = false;
    }
  }
}
