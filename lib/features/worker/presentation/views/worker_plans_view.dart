import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/plan_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../shared/presentation/views/plans_theme.dart';

// ═══════════════════════════════════════════════════════════════════
//  SITELINK PLANS — Worker Premium subscription page
// ═══════════════════════════════════════════════════════════════════
// Design reference ke hisaab se: amber accent + navy CTA + white cards.
// Palette ab shared (PlansTheme) — vendor plans screen bhi wahi use
// karta hai taaki dono "SiteLink Plans" screens consistent dikhein.
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
    final result = await PaymentService.payForPlan(plan);
    if (!mounted) return;
    setState(() => _subscribing = false);
    if (result.success) {
      AppSnackbar.success(message: result.message);
    } else {
      AppSnackbar.error(message: result.message);
    }
  }

  Future<void> _loadPlan() async {
    final res = await MiscApiService().getPlans();
    if (mounted && res.success && res.data.isNotEmpty) {
      setState(() => _plan = res.data.first);
    }
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
        title: Text('SiteLink Plans',
            style: KTextStyle.poppins(fs: 17, fw: FontWeight.w700, c: _ink)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: _ink),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    Text('WORKER PREMIUM',
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
                'Increase your chances\nof getting hired.',
                textAlign: TextAlign.center,
                style: KTextStyle.poppins(
                    fs: 24, fw: FontWeight.w800, c: _ink, height: 1.25),
              ),
              const SizedBox(height: 12),
              Text(
                'Upgrade to SiteLink Premium to unlock\nverified skill ratings, priority shortlisting,\nand dedicated support.',
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
              const _FeatureCard(
                icon: Icons.workspace_premium_outlined,
                title: 'Skill Rating & Verification',
                description:
                    'Get a verified skill rating based on your actual site experience, leading to prioritized shortlisting by top contractors.',
                highlighted: true,
                tag: 'Top Priority',
              ),
              const SizedBox(height: 14),
              const _FeatureCard(
                icon: Icons.trending_up_rounded,
                title: 'Priority Job Shortlisting',
                description:
                    'Your profile appears higher in search results, giving you significantly higher visibility to actively hiring companies.',
              ),
              const SizedBox(height: 14),
              const _FeatureCard(
                icon: Icons.shield_outlined,
                title: 'Emergency Job Support',
                description:
                    'Receive priority assistance when you need urgent job placements or encounter on-site issues.',
              ),
              const SizedBox(height: 14),
              const _FeatureCard(
                icon: Icons.support_agent_rounded,
                title: 'Call & WhatsApp Support',
                description:
                    'Direct line to our support team for any queries, application help, or immediate assistance via Call or WhatsApp.',
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
                  Text('Ready to stand\nout?',
                      textAlign: TextAlign.center,
                      style: KTextStyle.poppins(
                          fs: 24,
                          fw: FontWeight.w800,
                          c: Colors.white,
                          height: 1.25)),
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
                                    Text('Upgrade Now - ₹$_price/Yr',
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
                  const SizedBox(height: 12),
                  Text('Secure payment. Instant activation.',
                      style: KTextStyle.poppins(
                          fs: 10.5,
                          c: Colors.white.withValues(alpha: 0.45),
                          letterSpacing: 0.6)),
                ]),
              ),
              const SizedBox(height: 36),

              // ── Why Choose SiteLink ─────────────────────────────
              Text('Why Choose SiteLink?',
                  textAlign: TextAlign.center,
                  style: KTextStyle.poppins(
                      fs: 18, fw: FontWeight.w800, c: _ink)),
              const SizedBox(height: 24),
              const _WhyItem(
                icon: Icons.engineering_outlined,
                title: 'Industry Standard',
                description:
                    'Built for the realities of industrial and construction work environments.',
              ),
              const SizedBox(height: 24),
              const _WhyItem(
                icon: Icons.phonelink_lock_outlined,
                title: 'Secure & Verified',
                description:
                    'Rigorous verification processes protect both workers and contractors.',
              ),
              const SizedBox(height: 24),
              const _WhyItem(
                icon: Icons.groups_outlined,
                title: 'Direct Connections',
                description:
                    'Cut out middlemen. Connect directly with hiring managers and top firms.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature card ────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool highlighted; // amber left border (Top Priority card)
  final String? tag;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.highlighted = false,
    this.tag,
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
          const SizedBox(height: 6),
          Text(description,
              style: KTextStyle.poppins(fs: 12.5, c: _grey, height: 1.5)),
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
