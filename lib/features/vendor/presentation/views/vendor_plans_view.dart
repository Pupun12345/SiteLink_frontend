import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../shared/presentation/views/plans_theme.dart';
import '../controllers/vendor_plans_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR PLANS — Standard + Premium subscription (Stitch design)
// ═══════════════════════════════════════════════════════════════════
// Palette shared with WorkerPlansView via PlansTheme (same "SiteLink
// Plans" sub-brand). Indigo/blue accents yahin file-local hain (design
// reference me sirf vendor screen par use hue hain).
const _indigo    = Color(0xFF6366F1);
const _iconChipBg = Color(0xFFE0EAFF);
const _iconChipFg = Color(0xFF3B5BDB);

class VendorPlansView extends StatelessWidget {
  const VendorPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VendorPlansController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: PlansTheme.ink),
          onPressed: Get.back,
        ),
        title: Text('SiteLink Plans',
            style:
                KTextStyle.poppins(fs: 17, fw: FontWeight.w700, c: PlansTheme.ink)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: PlansTheme.ink),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Obx(() {
            ctrl.isLoading.value; // plans load hone par rebuild trigger
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Vendor Plans',
                    textAlign: TextAlign.center,
                    style: KTextStyle.poppins(
                        fs: 22, fw: FontWeight.w800, c: PlansTheme.ink)),
                const SizedBox(height: 8),
                Text(
                  'Select a plan to start hiring verified workers\nfor your projects.',
                  textAlign: TextAlign.center,
                  style: KTextStyle.poppins(
                      fs: 12.5, c: PlansTheme.grey, height: 1.5),
                ),
                const SizedBox(height: 24),
                _standardCard(ctrl),
                const SizedBox(height: 18),
                _premiumCard(ctrl),
                const SizedBox(height: 28),
                _whyChooseCard(),
                const SizedBox(height: 16),
                _footerNotes(),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Standard Plan card ────────────────────────────────────────────
  Widget _standardCard(VendorPlansController ctrl) {
    final plan = ctrl.standardPlan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PlansTheme.cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Standard Plan',
              style: KTextStyle.poppins(
                  fs: 18, fw: FontWeight.w800, c: PlansTheme.ink)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹${plan.price ?? 2999}',
                  style: KTextStyle.poppins(
                      fs: 28, fw: FontWeight.w800, c: PlansTheme.ink)),
              const SizedBox(width: 4),
              Text('/${plan.duration ?? 'Month'}',
                  style: KTextStyle.poppins(fs: 13, c: PlansTheme.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ideal for companies with regular manpower requirements.',
            style: KTextStyle.poppins(fs: 12.5, c: _indigo, height: 1.4),
          ),
          const SizedBox(height: 18),
          const _FeatureLine(
              text: 'Hire up to 50 Workers/Month', textColor: PlansTheme.ink),
          const _FeatureLine(
              text: 'Access to Verified Workers', textColor: PlansTheme.ink),
          const _FeatureLine(
              text: 'Job Posting Facility', textColor: PlansTheme.ink),
          const _FeatureLine(
              text: 'Call & WhatsApp Support', textColor: PlansTheme.ink),
          const SizedBox(height: 8),
          Obx(() => _PlanButton(
                label: 'Subscribe Now',
                bg: PlansTheme.lavender,
                fg: PlansTheme.lavenderDark,
                loading: ctrl.subscribingStandard.value,
                onTap: ctrl.subscribeStandard,
              )),
        ],
      ),
    );
  }

  // ── Premium Plan card (dark, RECOMMENDED) ──────────────────────────
  Widget _premiumCard(VendorPlansController ctrl) {
    final plan = ctrl.premiumPlan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: PlansTheme.navy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Premium Plan',
                  style: KTextStyle.poppins(
                      fs: 18, fw: FontWeight.w800, c: Colors.white)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PlansTheme.amber,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('RECOMMENDED',
                  style: KTextStyle.poppins(
                      fs: 9.5,
                      fw: FontWeight.w700,
                      c: PlansTheme.amberDark,
                      letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹${plan.price ?? 4999}',
                  style: KTextStyle.poppins(
                      fs: 28, fw: FontWeight.w800, c: Colors.white)),
              const SizedBox(width: 4),
              Text('/${plan.duration ?? 'Month'}',
                  style: KTextStyle.poppins(fs: 13, c: Colors.white60)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Best for companies with large-scale hiring requirements.',
            style:
                KTextStyle.poppins(fs: 12.5, c: PlansTheme.amber, height: 1.4),
          ),
          const SizedBox(height: 18),
          const _FeatureLine(
              text: 'Hire up to 100 Workers/Month', textColor: Colors.white),
          const _FeatureLine(
              text: 'Priority Job Listing', textColor: Colors.white),
          const _FeatureLine(
              text: 'Social Media Promotion', textColor: Colors.white),
          const _FeatureLine(
              text: 'Community Marketing', textColor: Colors.white),
          const _FeatureLine(
              text: 'Emergency Worker Replacement (48h)',
              textColor: Colors.white),
          const _FeatureLine(
              text: 'Access to Verified & Skilled Workers',
              textColor: Colors.white),
          const _FeatureLine(
              text: 'Dedicated Call & WhatsApp Support',
              textColor: Colors.white),
          const _FeatureLine(
              text: 'Priority Customer Support', textColor: Colors.white),
          const SizedBox(height: 8),
          Obx(() => _PlanButton(
                label: 'Upgrade to Premium',
                bg: PlansTheme.amber,
                fg: PlansTheme.navy,
                loading: ctrl.subscribingPremium.value,
                onTap: ctrl.subscribePremium,
              )),
        ],
      ),
    );
  }

  // ── Why Choose SiteLink? card ───────────────────────────────────────
  Widget _whyChooseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PlansTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why Choose SiteLink?',
              style: KTextStyle.poppins(
                  fs: 17, fw: FontWeight.w800, c: PlansTheme.ink)),
          const SizedBox(height: 18),
          const _WhyRow(
            icon: Icons.verified_user_rounded,
            title: 'Verified Workers',
            description:
                'Every worker is identity-verified and skill-assessed.',
          ),
          const SizedBox(height: 16),
          const _WhyRow(
            icon: Icons.bolt_rounded,
            title: 'Fast Hiring',
            description:
                'Fill roles quickly with our extensive worker database.',
          ),
          const SizedBox(height: 16),
          const _WhyRow(
            icon: Icons.support_agent_rounded,
            title: 'Reliable Support',
            description:
                'Dedicated assistance throughout your hiring process.',
          ),
        ],
      ),
    );
  }

  // ── Footer disclaimer ────────────────────────────────────────────
  Widget _footerNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('* Prices are exclusive of applicable taxes.',
            style: KTextStyle.poppins(fs: 10.5, c: PlansTheme.grey)),
        const SizedBox(height: 3),
        Text('* Subscription auto-renews unless cancelled.',
            style: KTextStyle.poppins(fs: 10.5, c: PlansTheme.grey)),
      ],
    );
  }
}

// ── Feature checklist line (orange circular check + text) ───────────
class _FeatureLine extends StatelessWidget {
  final String text;
  final Color textColor;
  const _FeatureLine({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
                color: PlansTheme.amber, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style:
                    KTextStyle.poppins(fs: 12.5, c: textColor, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ── "Why Choose" icon + title + description row ─────────────────────
class _WhyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _WhyRow(
      {required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: _iconChipBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 19, color: _iconChipFg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: KTextStyle.poppins(
                      fs: 13.5, fw: FontWeight.w700, c: PlansTheme.ink)),
              const SizedBox(height: 3),
              Text(description,
                  style: KTextStyle.poppins(
                      fs: 11.5, c: PlansTheme.grey, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Full-width plan CTA button (loading-aware) ───────────────────────
class _PlanButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final bool loading;
  final VoidCallback onTap;
  const _PlanButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: loading
                ? Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: fg),
                    ),
                  )
                : Center(
                    child: Text(label,
                        style: KTextStyle.poppins(
                            fs: 14, fw: FontWeight.w700, c: fg)),
                  ),
          ),
        ),
      ),
    );
  }
}
