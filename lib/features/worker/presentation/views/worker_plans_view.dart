import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/plan_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../shared/presentation/views/plan_status_banner.dart';
import '../../../shared/presentation/views/plans_theme.dart';
import '../../../shared/presentation/controllers/app_refresh.dart';

// ═══════════════════════════════════════════════════════════════════
//  SITELINK PLANS — Worker Premium subscription page
// ═══════════════════════════════════════════════════════════════════
// Design reference ke hisaab se: amber accent + navy CTA + white cards.
// Palette ab shared (PlansTheme) — vendor plans screen bhi wahi use
// karta hai taaki dono "Sitelink Plans" screens consistent dikhein.
const _amber      = PlansTheme.amber;
const _amberDark  = PlansTheme.amberDark;
const _amberSoft  = PlansTheme.amberSoft;
const _navy       = PlansTheme.navy;
const _ink        = PlansTheme.ink;
const _grey       = PlansTheme.grey;
const _cardBorder = PlansTheme.cardBorder;

class WorkerPlansView extends StatefulWidget {
  const WorkerPlansView({super.key});

  @override
  State<WorkerPlansView> createState() => _WorkerPlansViewState();
}

class _WorkerPlansViewState extends State<WorkerPlansView> {
  // Backend plan (GET /plans/plans) — na mile to static ₹299/Year fallback
  PlanModel? _plan;
  bool _subscribing = false;

  /// Cancel ka apna flag — `_subscribing` share karne se spinner galat
  /// button par dikhta hai.
  bool _cancellingAutoPay = false;

  /// Usi call se aati hai — plan active hai ya nahi aur kab tak.
  ActiveSubscription _sub = const ActiveSubscription();

  num get _price => _plan?.price ?? 299;
  String get _duration => _plan?.duration ?? 'Year';

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _upgrade() async {
    if (_subscribing) return;
    setState(() => _subscribing = true);
    final plan = _plan ??
        PlanModel(price: _price, duration: _duration, name: 'Worker Premium');
    // Pehli baar plan lete hi auto-payment khud lag jaata hai. Auto-renew
    // pehle se chalu ho to dobara mandate NAHI banate — do mandate se har
    // cycle me do baar paisa kat jaata.
    final result = _sub.autoRenew
        ? await PaymentService.payForPlan(plan)
        : await PaymentService.subscribeWithAutoPay(plan);
    if (!mounted) return;
    setState(() => _subscribing = false);
    if (result.success) {
      AppSnackbar.success(message: result.message);
      // Nayi expiry turant banner me dikhe — warna user ko lagta hai
      // paisa kat gaya par plan chala hi nahi.
      _loadPlan();
      // Plan par depend karne wali baaki screens bhi — Contact Support
      // ka lock aur profile ka data.
      refreshAfterPlanChange();
    } else {
      AppSnackbar.error(message: result.message);
    }
  }

  /// Auto-payment band karo. Confirm poochte hain kyunki ye paisa-related
  /// action hai aur galti se tap ho jaana easy hai.
  Future<void> _cancelAutoPay() async {
    if (_cancellingAutoPay) return;

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('autopay_cancel_title'.tr,
            style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700, c: _ink)),
        content: Text('autopay_cancel_confirm'.tr,
            style: KTextStyle.poppins(fs: 13, c: _grey, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('autopay_keep_btn'.tr,
                style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600, c: _grey)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('autopay_cancel_btn'.tr,
                style: KTextStyle.poppins(
                    fs: 13, fw: FontWeight.w700, c: const Color(0xFFB91C1C))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancellingAutoPay = true);
    final result = await PaymentService.cancelAutoPay();
    if (!mounted) return;
    setState(() => _cancellingAutoPay = false);
    if (result.success) {
      AppSnackbar.success(message: result.message);
      _loadPlan();
    } else {
      AppSnackbar.error(message: result.message);
    }
  }

  Future<void> _loadPlan() async {
    final res = await MiscApiService().getPlans();
    if (!mounted || !res.success) return;
    setState(() {
      if (res.data.isNotEmpty) _plan = res.data.first;
      _sub = res.subscription;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: Get.back,
        ),
        title: Text('worker_plans_title'.tr,
            style: KTextStyle.poppins(fs: 17, fw: FontWeight.w700, c: _ink)),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Active/expired plan status (kuch na ho to hidden) ─
              PlanStatusBanner(
                sub: _sub,
                fallbackPlanName: _plan?.name ?? 'Worker Premium',
                onCancelAutoPay: _cancelAutoPay,
                cancelling: _cancellingAutoPay,
              ),
              if (_sub.active || _sub.isExpired) const SizedBox(height: 20),

              // ── "Sitelink • A product of Smartnex" ──────────────
              const PlansBrandPill(uppercase: true),
              const SizedBox(height: 14),

              // ── WORKER PREMIUM pill ─────────────────────────────
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.military_tech_rounded,
                        size: 14, color: _amberDark),
                    const SizedBox(width: 6),
                    Text('worker_plans_badge'.tr,
                        style: KTextStyle.poppins(
                            fs: 11,
                            fw: FontWeight.w700,
                            c: _amberDark,
                            letterSpacing: 1.2)),
                  ]),
                ),
              ),
              const SizedBox(height: 18),

              // ── Headline ────────────────────────────────────────
              Text(
                'worker_plans_headline'.tr,
                textAlign: TextAlign.center,
                style: KTextStyle.poppins(
                    fs: 24, fw: FontWeight.w800, c: _ink, height: 1.25),
              ),
              const SizedBox(height: 12),
              Text(
                'worker_plans_subheadline'.tr,
                textAlign: TextAlign.center,
                style: KTextStyle.poppins(fs: 13, c: _grey, height: 1.5),
              ),
              const SizedBox(height: 18),

              // ── Price ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₹$_price',
                      style: KTextStyle.poppins(
                          fs: 34, fw: FontWeight.w800, c: _ink)),
                  const SizedBox(width: 6),
                  Text('/ $_duration',
                      style: KTextStyle.poppins(fs: 13, c: _grey)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Feature cards ───────────────────────────────────
              _FeatureCard(
                icon: Icons.workspace_premium_outlined,
                title: 'worker_plans_feature1_title'.tr,
                description: 'worker_plans_feature1_desc'.tr,
                highlighted: true,
                tag: 'worker_plans_feature1_tag'.tr,
              ),
              const SizedBox(height: 14),
              // Design me ye card baaki se alag hai: description ki jagah
              // teen chhote points, isliye `bullets`.
              _FeatureCard(
                icon: Icons.shield_rounded,
                title: 'worker_plans_family_title'.tr,
                highlighted: true,
                tag: 'worker_plans_family_tag'.tr,
                bullets: [
                  _Bullet(Icons.verified_outlined,
                      'worker_plans_family1_label'.tr,
                      'worker_plans_family1_text'.tr),
                  _Bullet(Icons.volunteer_activism_outlined,
                      'worker_plans_family2_label'.tr,
                      'worker_plans_family2_text'.tr),
                  _Bullet(Icons.bolt_rounded,
                      'worker_plans_family3_label'.tr,
                      'worker_plans_family3_text'.tr),
                ],
              ),
              const SizedBox(height: 14),
              _FeatureCard(
                icon: Icons.trending_up_rounded,
                title: 'worker_plans_feature2_title'.tr,
                description: 'worker_plans_feature2_desc'.tr,
              ),
              const SizedBox(height: 14),
              _FeatureCard(
                icon: Icons.shield_outlined,
                title: 'worker_plans_feature3_title'.tr,
                description: 'worker_plans_feature3_desc'.tr,
              ),
              const SizedBox(height: 14),
              _FeatureCard(
                icon: Icons.support_agent_rounded,
                title: 'worker_plans_feature4_title'.tr,
                description: 'worker_plans_feature4_desc'.tr,
              ),
              const SizedBox(height: 24),

              // ── Navy CTA card ───────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Text(
                      _sub.active
                          ? 'plan_cta_headline_active'.tr
                          : 'worker_plans_cta_headline'.tr,
                      textAlign: TextAlign.center,
                      style: KTextStyle.poppins(
                          fs: 24,
                          fw: FontWeight.w800,
                          c: Colors.white,
                          height: 1.25)),
                  if (_sub.active && _sub.expiresAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'plan_cta_extend_note'.tr,
                      textAlign: TextAlign.center,
                      style: KTextStyle.poppins(
                          fs: 12,
                          c: Colors.white.withValues(alpha: 0.65),
                          height: 1.45),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: _amber,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _subscribing ? null : _upgrade,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _subscribing
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.2, color: _navy),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        _sub.active
                                            ? 'plan_renew_btn'.trParams(
                                                {'price': '$_price'})
                                            : 'worker_plans_upgrade_btn'
                                                .trParams({'price': '$_price'}),
                                        style: KTextStyle.poppins(
                                            fs: 14,
                                            fw: FontWeight.w700,
                                            c: _navy)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 18, color: _navy),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  // Alag auto-pay button hata diya gaya — upar wala button
                  // hi auto-payment chalu kar deta hai.
                  //
                  // Ye line tap se PEHLE batati hai ki recurring mandate
                  // ban raha hai. Mandate chalu ho to hat jaati hai, kyunki
                  // tab button sirf ek baar ka extend karta hai.
                  if (!_sub.autoRenew) ...[
                    const SizedBox(height: 10),
                    Text(
                      'autopay_cancel_anytime'.tr,
                      textAlign: TextAlign.center,
                      style: KTextStyle.poppins(fs: 11, c: _grey),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text('worker_plans_secure_note'.tr,
                      style: KTextStyle.poppins(
                          fs: 10.5,
                          c: Colors.white.withValues(alpha: 0.45),
                          letterSpacing: 0.6)),
                ]),
              ),
              const SizedBox(height: 36),

              // ── Why Choose Sitelink ─────────────────────────────
              Text('worker_plans_why_title'.tr,
                  textAlign: TextAlign.center,
                  style: KTextStyle.poppins(
                      fs: 18, fw: FontWeight.w800, c: _ink)),
              const SizedBox(height: 24),
              _WhyItem(
                icon: Icons.engineering_outlined,
                title: 'worker_plans_why1_title'.tr,
                description: 'worker_plans_why1_desc'.tr,
              ),
              const SizedBox(height: 24),
              _WhyItem(
                icon: Icons.phonelink_lock_outlined,
                title: 'worker_plans_why2_title'.tr,
                description: 'worker_plans_why2_desc'.tr,
              ),
              const SizedBox(height: 24),
              _WhyItem(
                icon: Icons.groups_outlined,
                title: 'worker_plans_why3_title'.tr,
                description: 'worker_plans_why3_desc'.tr,
              ),
              const SizedBox(height: 32),

              // ── Footer ──────────────────────────────────────────
              const Divider(color: _cardBorder, height: 1),
              const SizedBox(height: 20),
              Text('worker_plans_footer_about'.tr,
                  textAlign: TextAlign.center,
                  style: KTextStyle.poppins(fs: 12, c: _ink, height: 1.5)),
              const SizedBox(height: 8),
              const PlansCopyright(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature card ────────────────────────────────────────────────────
/// Feature card ke andar ka ek point: icon + bold label + baaki text.
class _Bullet {
  final IconData icon;
  final String label;
  final String text;
  const _Bullet(this.icon, this.label, this.text);
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final bool highlighted; // amber left border (Top Priority card)
  final String? tag;

  /// Description ki jagah points (Family Protection card).
  final List<_Bullet> bullets;

  const _FeatureCard({
    required this.icon,
    required this.title,
    this.description,
    this.highlighted = false,
    this.tag,
    this.bullets = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Note: rounded corners + non-uniform border allowed nahi, isliye
    // uniform border + amber left-strip Stack se paint hoti hai.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        if (highlighted)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: _amber),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(highlighted ? 22 : 18, 18, 18, 18),
          child: _content(),
        ),
      ]),
    );
  }

  Widget _content() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _amberSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: _amberDark),
            ),
            const Spacer(),
            if (tag != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _amberSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag!,
                    style: KTextStyle.poppins(
                        fs: 10.5, fw: FontWeight.w600, c: _amberDark)),
              ),
          ]),
          const SizedBox(height: 14),
          Text(title,
              style:
                  KTextStyle.poppins(fs: 16, fw: FontWeight.w800, c: _ink)),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(description!,
                style: KTextStyle.poppins(fs: 12.5, c: _grey, height: 1.5)),
          ],
          for (final b in bullets) ...[
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(b.icon, size: 15, color: _amberDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '${b.label} ',
                        style: KTextStyle.poppins(
                            fs: 12.5, fw: FontWeight.w700, c: _ink,
                            height: 1.5)),
                    TextSpan(
                        text: b.text,
                        style: KTextStyle.poppins(
                            fs: 12.5, c: _grey, height: 1.5)),
                  ]),
                ),
              ),
            ]),
          ],
        ]);
  }
}

// ── "Why Choose" item ───────────────────────────────────────────────
class _WhyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _WhyItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _amberSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 26, color: _amberDark),
      ),
      const SizedBox(height: 12),
      Text(title,
          style: KTextStyle.poppins(fs: 14.5, fw: FontWeight.w700, c: _ink)),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(description,
            textAlign: TextAlign.center,
            style: KTextStyle.poppins(fs: 12, c: _grey, height: 1.5)),
      ),
    ]);
  }
}
