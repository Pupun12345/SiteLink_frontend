import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../shared/presentation/views/plan_status_banner.dart';
import '../../../shared/presentation/views/plans_theme.dart';
import '../controllers/vendor_plans_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR PLANS — Standard + Premium subscription (Stitch design)
// ═══════════════════════════════════════════════════════════════════
// Palette shared with WorkerPlansView via PlansTheme (same "Sitelink
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
        title: Text('worker_plans_title'.tr,
            style:
                KTextStyle.poppins(fs: 17, fw: FontWeight.w700, c: PlansTheme.ink)),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Obx(() {
            ctrl.isLoading.value; // plans load hone par rebuild trigger
            final sub = ctrl.subscription.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Active/expired plan status (kuch na ho to hidden) ─
                PlanStatusBanner(
                  sub: sub,
                  onCancelAutoPay: ctrl.cancelAutoPay,
                  cancelling: ctrl.cancellingAutoPay.value,
                ),
                if (sub.active || sub.isExpired) const SizedBox(height: 20),

                Text('vendor_plans_heading'.tr,
                    textAlign: TextAlign.center,
                    style: KTextStyle.poppins(
                        fs: 22, fw: FontWeight.w800, c: PlansTheme.ink)),
                const SizedBox(height: 10),
                const PlansBrandPill(),
                const SizedBox(height: 10),
                Text(
                  'vendor_plans_subtitle'.tr,
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
    final isActive = plan.isCurrentPlan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Chal raha plan visually alag — border green aur thoda motta.
        border: Border.all(
          color: isActive ? PlansTheme.activeGreen : PlansTheme.cardBorder,
          width: isActive ? 1.6 : 1,
        ),
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
          Row(children: [
            Expanded(
              child: Text('standard_plan_title'.tr,
                  style: KTextStyle.poppins(
                      fs: 18, fw: FontWeight.w800, c: PlansTheme.ink)),
            ),
            if (isActive) const ActivePlanBadge(),
          ]),
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
            'standard_plan_desc'.tr,
            style: KTextStyle.poppins(fs: 12.5, c: _indigo, height: 1.4),
          ),
          const SizedBox(height: 18),
          // Number backend ke `maxWorkers` se — job posting bhi isi se
          // rukti hai, to screen wahi vaada karti hai jo backend nibhata
          // hai. 0 = limit set nahi, tab line nahi dikhate.
          if (plan.maxWorkers > 0)
            _FeatureLine(
                text: 'feature_hire_up_to_workers'
                    .trParams({'count': '${plan.maxWorkers}'}),
                textColor: PlansTheme.ink),
          _FeatureLine(
              text: 'feature_access_verified_workers'.tr, textColor: PlansTheme.ink),
          _FeatureLine(
              text: 'feature_job_posting_facility'.tr, textColor: PlansTheme.ink),
          _FeatureLine(
              text: 'feature_call_whatsapp_support'.tr, textColor: PlansTheme.ink),
          const SizedBox(height: 8),
          Obx(() => _PlanButton(
                label: isActive
                    ? 'plan_extend_btn'.tr
                    : 'subscribe_now_btn'.tr,
                bg: PlansTheme.lavender,
                fg: PlansTheme.lavenderDark,
                loading: ctrl.subscribingStandard.value,
                onTap: ctrl.subscribeStandard,
              )),
          // Alag auto-pay button hata diya gaya: ab upar wala hi button
          // auto-payment chalu kar deta hai. Band karne ka rasta active
          // plan ke banner me hai.
          //
          // Ye line tap se PEHLE batati hai ki recurring mandate ban raha
          // hai — "Subscribe Now" par chup-chaap auto-debit lagana theek
          // nahi. Mandate pehle se chalu ho to line hat jaati hai, kyunki
          // tab button sirf ek baar ka extend karta hai.
          if (!ctrl.subscription.value.autoRenew) ...[
            const SizedBox(height: 8),
            Text(
              'autopay_cancel_anytime'.tr,
              textAlign: TextAlign.center,
              style: KTextStyle.poppins(fs: 11, c: PlansTheme.grey),
            ),
          ],
        ],
      ),
    );
  }

  // ── Premium Plan card (dark, RECOMMENDED) ──────────────────────────
  Widget _premiumCard(VendorPlansController ctrl) {
    final plan = ctrl.premiumPlan;
    final isActive = plan.isCurrentPlan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: PlansTheme.navy,
        borderRadius: BorderRadius.circular(16),
        // Navy card par border tabhi jab yahi plan chal raha ho.
        border: isActive
            ? Border.all(color: PlansTheme.activeGreen, width: 1.6)
            : null,
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
              child: Text('premium_plan_title'.tr,
                  style: KTextStyle.poppins(
                      fs: 18, fw: FontWeight.w800, c: Colors.white)),
            ),
            // Plan chal raha ho to "RECOMMENDED" ki jagah "ACTIVE" —
            // dono ek saath dikhana confusing hota hai.
            if (isActive)
              const ActivePlanBadge(onDark: true)
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PlansTheme.amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('recommended_badge'.tr,
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
            'premium_plan_desc'.tr,
            style:
                KTextStyle.poppins(fs: 12.5, c: PlansTheme.amber, height: 1.4),
          ),
          const SizedBox(height: 18),
          if (plan.maxWorkers > 0)
            _FeatureLine(
                text: 'feature_hire_up_to_workers'
                    .trParams({'count': '${plan.maxWorkers}'}),
                textColor: Colors.white),
          _FeatureLine(
              text: 'feature_priority_job_listing'.tr, textColor: Colors.white),
          _FeatureLine(
              text: 'feature_social_media_promotion'.tr, textColor: Colors.white),
          _FeatureLine(
              text: 'feature_community_marketing'.tr, textColor: Colors.white),
          _FeatureLine(
              text: 'feature_emergency_replacement'.tr,
              textColor: Colors.white),
          _FeatureLine(
              text: 'feature_access_verified_skilled_workers'.tr,
              textColor: Colors.white),
          _FeatureLine(
              text: 'feature_dedicated_call_whatsapp_support'.tr,
              textColor: Colors.white),
          _FeatureLine(
              text: 'feature_priority_customer_support'.tr, textColor: Colors.white),
          const SizedBox(height: 8),
          Obx(() => _PlanButton(
                label: isActive
                    ? 'plan_extend_btn'.tr
                    : 'upgrade_to_premium_btn'.tr,
                bg: PlansTheme.amber,
                fg: PlansTheme.navy,
                loading: ctrl.subscribingPremium.value,
                onTap: ctrl.subscribePremium,
              )),
          // Yahan bhi alag auto-pay button ki zaroorat nahi — upar wala
          // button hi mandate bana deta hai. Navy card hai isliye text
          // halka white, standard card wale grey ke bajaye.
          if (!ctrl.subscription.value.autoRenew) ...[
            const SizedBox(height: 8),
            Text(
              'autopay_cancel_anytime'.tr,
              textAlign: TextAlign.center,
              style: KTextStyle.poppins(
                  fs: 11, c: Colors.white.withValues(alpha: 0.65)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Why Choose Sitelink? card ───────────────────────────────────────
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
          Text('worker_plans_why_title'.tr,
              style: KTextStyle.poppins(
                  fs: 17, fw: FontWeight.w800, c: PlansTheme.ink)),
          const SizedBox(height: 18),
          _WhyRow(
            icon: Icons.verified_user_rounded,
            title: 'why_verified_workers_title'.tr,
            description: 'why_verified_workers_desc'.tr,
          ),
          const SizedBox(height: 16),
          _WhyRow(
            icon: Icons.bolt_rounded,
            title: 'why_fast_hiring_title'.tr,
            description: 'why_fast_hiring_desc'.tr,
          ),
          const SizedBox(height: 16),
          _WhyRow(
            icon: Icons.support_agent_rounded,
            title: 'why_reliable_support_title'.tr,
            description: 'why_reliable_support_desc'.tr,
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
        Text('footer_prices_note'.tr,
            style: KTextStyle.poppins(fs: 10.5, c: PlansTheme.grey)),
        const SizedBox(height: 3),
        Text('footer_autorenew_note'.tr,
            style: KTextStyle.poppins(fs: 10.5, c: PlansTheme.grey)),
        const SizedBox(height: 14),
        const Divider(color: PlansTheme.cardBorder, height: 1),
        const SizedBox(height: 14),
        const PlansCopyright(align: TextAlign.left),
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
