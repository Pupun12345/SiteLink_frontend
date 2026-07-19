import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/shared_widgets.dart';

// Support contact — ek jagah, taaki number badalna ho to yahin se.
const String _kSupportPhone = '+918000000000';
const String _kSupportWhatsapp = '918000000001';
const String _kSupportEmail = 'support@sitelink.in';

Future<void> _launch(Uri uri) async {
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) AppSnackbar.error(message: 'Nahi khul paaya');
  } catch (_) {
    AppSnackbar.error(message: 'Is action ke liye koi app nahi mili');
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELP / SUPPORT / POLICY — worker aur vendor dono use karte hain
// ═══════════════════════════════════════════════════════════════════
// UI identical hai dono roles pe — sirf FAQ list aur policy text alag
// (role-specific content caller se aata hai). Community feed jaisa hi
// "shared component, role apna content pass kare" pattern.

// ── FAQ view ─────────────────────────────────────────────────────
class FaqView extends StatelessWidget {
  final String title;
  final List<(String, String)> faqs;
  const FaqView({super.key, this.title = 'Help & FAQ', required this.faqs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: title),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppDimens.lg),
          itemCount: faqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
          itemBuilder: (_, i) => _FaqCard(faq: faqs[i]),
        ),
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final (String, String) faq;
  const _FaqCard({required this.faq});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.faq.$1,
                  style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600),
                ),
              ),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Text(
              widget.faq.$2,
              style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Contact support view ────────────────────────────────────────────
// Same support team dono roles ke liye — content role-agnostic hai.
class ContactSupportView extends StatelessWidget {
  const ContactSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'Contact Support'),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            children: [
              AppCard(
                child: Column(
                  children: [
                    _ContactOption(
                      icon: Icons.phone_rounded,
                      title: 'Call Support',
                      subtitle: '+91 80000 00000',
                      color: AppColors.success,
                      onTap: () => _launch(Uri.parse('tel:$_kSupportPhone')),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _ContactOption(
                      icon: Icons.chat_rounded,
                      title: 'WhatsApp',
                      subtitle: '+91 80000 00001',
                      color: const Color(0xFF25D366),
                      onTap: () => _launch(
                          Uri.parse('https://wa.me/$_kSupportWhatsapp')),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _ContactOption(
                      icon: Icons.email_outlined,
                      title: 'Email Support',
                      subtitle: 'support@sitelink.in',
                      color: AppColors.info,
                      onTap: () =>
                          _launch(Uri.parse('mailto:$_kSupportEmail')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Support Hours',
                        style:
                            KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _InfoRow(
                        label: 'Monday – Saturday',
                        value: '9:00 AM – 7:00 PM'),
                    const SizedBox(height: 6),
                    _InfoRow(
                        label: 'Sunday', value: '10:00 AM – 4:00 PM'),
                    const SizedBox(height: 6),
                    _InfoRow(
                        label: 'Emergency', value: '24/7 on WhatsApp'),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              const _InfoBannerCard(
                icon: Icons.access_time_rounded,
                text: 'Average response time: under 2 hours',
              ),
            ],
          ),
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

// ── Policy view (Privacy Policy + Terms of Service) ──────────────────
// [content] static fallback hai. Agar [policyType] diya ho, backend se
// (GET /legal/policies) latest content fetch hota hai — mile to wo dikhta
// hai, warna static fallback. Isse page kabhi blank nahi hota.
class PolicyView extends StatefulWidget {
  final String title;
  final String content;
  final String? policyType; // 'PRIVACY_POLICY' | 'TERMS_AND_CONDITIONS'
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
                  child: Text(
                    _content,
                    style:
                        KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
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
