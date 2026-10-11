import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/app_config_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../vendor/presentation/views/vendor_plans_view.dart';
import '../../../worker/presentation/views/worker_plans_view.dart';

Future<void> _launch(Uri uri) async {
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) AppSnackbar.error(message: 'action_could_not_open'.tr);
  } catch (_) {
    AppSnackbar.error(message: 'no_app_for_action'.tr);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELP / SUPPORT / POLICY — worker aur vendor dono use karte hain
// ═══════════════════════════════════════════════════════════════════
// UI identical hai dono roles pe — content backend se (admin-managed)
// aata hai, "shared component, role apna policyType pass kare" pattern.

// ── Contact support view — 100% admin-managed (PlatformSettings.supportContact)
class ContactSupportView extends StatefulWidget {
  const ContactSupportView({super.key});

  @override
  State<ContactSupportView> createState() => _ContactSupportViewState();
}

class _ContactSupportViewState extends State<ContactSupportView> {
  SupportContactResult _res = const SupportContactResult();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await LegalApiService().getSupportContact();
    if (!mounted) return;
    setState(() {
      _res = res;
      _loading = false;
    });
  }

  String? _v(String key) {
    final v = _res.contact[key]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Plan lene ke baad wapas aate hi contact khul jaana chahiye,
  /// isliye return par dobara load karte hain.
  Future<void> _openPlans() async {
    final isVendor = SessionService.to.userType == 'vendor';
    await Get.to(() =>
        isVendor ? const VendorPlansView() : const WorkerPlansView());
    if (!mounted) return;
    setState(() => _loading = true);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final phone = _v('phone');
    final whatsapp = _v('whatsapp');
    final email = _v('email');
    final hoursWeekday = _v('hoursWeekday');
    final hoursSunday = _v('hoursSunday');
    final emergencyNote = _v('emergencyNote');
    final avgResponseTime = _v('avgResponseTime');
    final hasAnyContact = phone != null || whatsapp != null || email != null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'contact_support'.tr),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            // Paid feature — plan na ho to contact ki jagah locked state.
            : _res.needsSubscription
                ? _SupportLocked(
                    message: _res.message,
                    onViewPlans: _openPlans,
                  )
                : !hasAnyContact
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.lg),
                      child: Text(
                        'support_contact_soon'.tr,
                        textAlign: TextAlign.center,
                        style: KTextStyle.poppins(
                            fs: 13, c: AppColors.textSecondary),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: Column(
                      children: [
                        AppCard(
                          child: Column(
                            children: [
                              if (phone != null) ...[
                                _ContactOption(
                                  icon: Icons.phone_rounded,
                                  title: 'call_support_label'.tr,
                                  subtitle: phone,
                                  color: AppColors.success,
                                  onTap: () =>
                                      _launch(Uri.parse('tel:$phone')),
                                ),
                                if (whatsapp != null || email != null)
                                  const Divider(
                                      height: 1, color: AppColors.divider),
                              ],
                              if (whatsapp != null) ...[
                                _ContactOption(
                                  icon: Icons.chat_rounded,
                                  title: 'whatsapp'.tr,
                                  subtitle: whatsapp,
                                  color: const Color(0xFF25D366),
                                  onTap: () => _launch(Uri.parse(
                                      'https://wa.me/${whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}')),
                                ),
                                if (email != null)
                                  const Divider(
                                      height: 1, color: AppColors.divider),
                              ],
                              if (email != null)
                                _ContactOption(
                                  icon: Icons.email_outlined,
                                  title: 'email_support_label'.tr,
                                  subtitle: email,
                                  color: AppColors.info,
                                  onTap: () =>
                                      _launch(Uri.parse('mailto:$email')),
                                ),
                            ],
                          ),
                        ),
                        if (hoursWeekday != null || hoursSunday != null) ...[
                          const SizedBox(height: AppDimens.lg),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('support_hours_label'.tr,
                                    style: KTextStyle.poppins(
                                        fs: 14, fw: FontWeight.w600)),
                                const SizedBox(height: 10),
                                if (hoursWeekday != null) ...[
                                  _InfoRow(
                                      label: 'monday_saturday_label'.tr,
                                      value: hoursWeekday),
                                  const SizedBox(height: 6),
                                ],
                                if (hoursSunday != null) ...[
                                  _InfoRow(label: 'sunday_label'.tr, value: hoursSunday),
                                  const SizedBox(height: 6),
                                ],
                                if (emergencyNote != null)
                                  _InfoRow(
                                      label: 'emergency_label'.tr,
                                      value: emergencyNote),
                              ],
                            ),
                          ),
                        ],
                        if (avgResponseTime != null) ...[
                          const SizedBox(height: AppDimens.lg),
                          _InfoBannerCard(
                            icon: Icons.access_time_rounded,
                            text: 'average_response_time'
                                .trParams({'time': avgResponseTime}),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ── Contact Support locked — plan nahi hai ──────────────────────────
// Sirf "nahi milega" mat bolo: kya milega aur kaise milega, dono
// dikhao, aur Plans ek tap door ho.
class _SupportLocked extends StatelessWidget {
  final String? message;
  final Future<void> Function() onViewPlans;

  const _SupportLocked({required this.message, required this.onViewPlans});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'support_locked_title'.tr,
              textAlign: TextAlign.center,
              style: KTextStyle.poppins(fs: 17, fw: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              (message ?? '').trim().isNotEmpty
                  ? message!.trim()
                  : 'support_locked_msg'.tr,
              textAlign: TextAlign.center,
              style: KTextStyle.poppins(
                  fs: 13, c: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'view_plans_btn'.tr,
                onTap: onViewPlans,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
                  Text(subtitle,
                      style: KTextStyle.poppins(
                          fs: 12, c: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(label,
                  style: KTextStyle.poppins(
                      fs: 12, c: AppColors.textSecondary))),
          Text(value,
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500)),
        ],
      );
}

class _InfoBannerCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBannerCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style:
                        KTextStyle.poppins(fs: 12, c: AppColors.primary))),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  CONTENT SANITIZER — legacy double-escaped data (kabhi kabhi content
//  save hote waqt already-escaped string paste ho jaata hai, jisse DB
//  me literal `\n` / `\"` characters store ho jaate hain, real newline
//  ke bajaye). Display se pehle normalize karte hain taaki purana bhi
//  aur naya (clean) dono content sahi render ho.
// ═══════════════════════════════════════════════════════════════════
String _sanitizeContent(String raw) {
  return raw
      .replaceAll(r'\r\n', '\n')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\"', '"')
      .replaceAll(r"\'", "'");
}

// ── Policy view (Privacy Policy / Terms of Service / Help & FAQ) ─────
// [content] static fallback hai. Agar [policyType] diya ho, backend se
// (GET /legal/policies) latest content fetch hota hai — mile to wo dikhta
// hai, warna static fallback. Isse page kabhi blank nahi hota. Content
// Markdown format me hota hai (admin panel se likha jaata hai) — yahan
// properly render hota hai, raw '#'/'**'/'-' symbols nahi dikhte.
class PolicyView extends StatefulWidget {
  final String title;
  final String content;
  final String? policyType; // 'PRIVACY_POLICY' | 'TERMS_AND_CONDITIONS' | 'HELP_AND_SUPPORT'
  const PolicyView({
    super.key,
    required this.title,
    required this.content,
    this.policyType,
  });

  @override
  State<PolicyView> createState() => _PolicyViewState();
}

class _PolicyViewState extends State<PolicyView> {
  late String _content = widget.content;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.policyType != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final map = await LegalApiService().getPolicies();
    final fetched = map[widget.policyType];
    if (!mounted) return;
    setState(() {
      if (fetched != null && fetched.trim().isNotEmpty) _content = fetched;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loading)
              const LinearProgressIndicator(
                  minHeight: 2, color: AppColors.primary),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: AppCard(
                  child: MarkdownBlock(
                    data: _sanitizeContent(_content),
                    selectable: false,
                    config: MarkdownConfig(configs: [
                      PConfig(
                        textStyle: KTextStyle.poppins(
                            fs: 13, c: AppColors.textSecondary, height: 1.5),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
