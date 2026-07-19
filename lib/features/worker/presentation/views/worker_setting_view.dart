import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../shared/presentation/views/help_support_views.dart';
import 'edit_profile_view.dart';
import 'worker_documents_view.dart';
import 'worker_plans_view.dart';

// Worker-specific FAQ content (shared FaqView UI, apna content)
const _kWorkerFaqs = [
  ('How does SiteLink work?',
      'SiteLink connects workers with vendors through an admin-mediated system. Vendors post requirements, workers apply, and our admin assigns verified workers to ensure quality and trust.'),
  ('How do I get assigned to a job?',
      'Once you complete your profile and upload required documents, our admin team will verify your profile. After verification, you become eligible for job assignments.'),
  ('How long does profile verification take?',
      'Profile verification typically takes 24–48 hours after all documents are submitted.'),
  ('What if I need to report an issue on site?',
      'Use the "Report Issue" button on your Active Job screen to notify our team. We respond within 2 hours.'),
  ('How are payments processed?',
      'Payments are handled directly between you and the vendor. SiteLink provides the platform and admin support — payment terms are agreed upon at the time of assignment.'),
  ('Can I work for multiple vendors?',
      'You can only have one active job assignment at a time through SiteLink. Once a job is completed, you become available for new assignments.'),
];

// ═══════════════════════════════════════════════════════════════════
//  SETTINGS CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class WorkerSettingsController extends GetxController {
  final notificationsEnabled = true.obs;
  // Current app language se init — 'en' | 'hi'
  final languageCode = (LocaleService.to.isHindi ? 'hi' : 'en').obs;

  void toggleNotifications(bool v) => notificationsEnabled.value = v;

  /// Language select — locale live switch + persist + backend sync.
  void setLanguage(String code) {
    languageCode.value = code;
    LocaleService.to.setLanguage(code == 'hi' ? 'hindi' : 'english');
  }

  Future<void> logout() async {
    // Backend token blacklist (fail ho to bhi local logout hota hai)
    await MiscApiService().logout();
    await AuthService.instance.signOut();
    await SessionService.to.clear();
    Get.offAllNamed(AppRoutes.language);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WORKER SETTINGS VIEW
// ═══════════════════════════════════════════════════════════════════
class WorkerSettingsView extends StatelessWidget {
  const WorkerSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WorkerSettingsController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'Settings'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.lg),
          children: [
            // ── Account ──────────────────────────────────────
            _SectionLabel(label: 'Account'),
            AppCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    onTap: () => Get.to(() => const EditProfileView()),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.phone_outlined,
                    title: 'Change Phone Number',
                    onTap: () {
                      // TODO: phone change flow
                    },
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.badge_outlined,
                    title: 'My Documents',
                    onTap: () => Get.to(() => const WorkerDocumentsView()),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.workspace_premium_rounded,
                    title: 'SiteLink Premium',
                    subtitle: 'Upgrade — ₹299/Year',
                    onTap: () => Get.to(() => const WorkerPlansView()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ── Preferences ──────────────────────────────────
            _SectionLabel(label: 'Preferences'),
            AppCard(
              child: Column(
                children: [
                  Obx(() => _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    trailing: Switch(
                      value: ctrl.notificationsEnabled.value,
                      onChanged: ctrl.toggleNotifications,
                      activeColor: AppColors.primary,
                    ),
                  )),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () => _showLanguageSheet(context, ctrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ── Support ──────────────────────────────────────
            _SectionLabel(label: 'Support'),
            AppCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & FAQ',
                    onTap: () => Get.to(
                        () => const FaqView(faqs: _kWorkerFaqs)),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Contact Support',
                    onTap: () => Get.to(() => const ContactSupportView()),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.star_outline_rounded,
                    title: 'Rate the App',
                    onTap: () {
                      // TODO: launch store URL
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ── Legal ─────────────────────────────────────────
            _SectionLabel(label: 'Legal'),
            AppCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => Get.to(() => const PolicyView(
                      title: 'Privacy Policy',
                      content: _kPrivacyPolicy,
                      policyType: 'PRIVACY_POLICY',
                    )),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => Get.to(() => const PolicyView(
                      title: 'Terms of Service',
                      content: _kTermsOfService,
                      policyType: 'TERMS_AND_CONDITIONS',
                    )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.lg),

            // ── App version ───────────────────────────────────
            Center(
              child: Text(
                '${AppStrings.SiteLink}  v1.0.0',
                style: KTextStyle.poppins(fs: 11, c: AppColors.textHint),
              ),
            ),
            const SizedBox(height: AppDimens.lg),

            // ── Logout ────────────────────────────────────────
            CustomButton(
              label: 'Logout',
              isOutlined: true,
              onTap: () => _showLogoutDialog(context, ctrl),
            ),
            const SizedBox(height: AppDimens.lg),
          ],
        ),
      ),
    );
  }

  // ── Language bottom sheet ─────────────────────────────────────
  void _showLanguageSheet(BuildContext context, WorkerSettingsController ctrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXxl)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Select Language', style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600)),
                const SizedBox(height: 14),
                Obx(() => Column(
                  children: [
                    _LanguageOption(
                      label: 'English',
                      code: 'en',
                      selected: ctrl.languageCode.value == 'en',
                      onTap: () { ctrl.setLanguage('en'); Get.back(); },
                    ),
                    const SizedBox(height: 8),
                    _LanguageOption(
                      label: 'Hindi',
                      code: 'hi',
                      selected: ctrl.languageCode.value == 'hi',
                      onTap: () { ctrl.setLanguage('hi'); Get.back(); },
                    ),
                  ],
                )),
                const SizedBox(height: AppDimens.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logout confirm dialog ─────────────────────────────────────
  void _showLogoutDialog(BuildContext context, WorkerSettingsController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: Text('Logout', style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
        content: Text(
          'Are you sure you want to logout?',
          style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('Cancel', style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: ctrl.logout,
            child: Text('Logout', style: KTextStyle.poppins(fs: 13, c: Colors.red, fw: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED SETTINGS WIDGETS  (private to this file)
// ═══════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label.toUpperCase(),
        style: KTextStyle.poppins(fs: 11, fw: FontWeight.w600, c: AppColors.textHint)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KTextStyle.poppins(fs: 14)),
                  if (subtitle != null)
                    Text(subtitle!, style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.divider, indent: 50);
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary.withOpacity(0.4) : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Text(label, style: KTextStyle.poppins(fs: 14, fw: selected ? FontWeight.w600 : FontWeight.normal)),
            const Spacer(),
            if (selected) const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  POLICY TEXT CONTENT
// ═══════════════════════════════════════════════════════════════════
const _kPrivacyPolicy = '''
Last updated: March 2026

1. INFORMATION WE COLLECT
SiteLink collects information you provide directly to us, such as your name, phone number, Aadhaar number, work experience, and profile photo when you register as a Worker on our platform.

2. HOW WE USE YOUR INFORMATION
We use the information we collect to:
• Verify your identity and work eligibility
• Match you with suitable job assignments
• Communicate with you about your assignments
• Improve our platform and services

3. INFORMATION SHARING
We share your profile information (name, skills, experience) with vendors only after an admin approves a job assignment. We do not sell your personal data to third parties.

4. DOCUMENT SECURITY
Documents such as Aadhaar cards and experience letters are stored securely and used solely for identity verification purposes. Access is restricted to authorised SiteLink admin staff only.

5. DATA RETENTION
We retain your account information for as long as your account is active or as needed to provide services. You may request deletion of your account by contacting support.

6. YOUR RIGHTS
You have the right to access, update, or delete your personal information. Contact support@sitelink.in to exercise these rights.

7. CONTACT US
For privacy-related queries, contact: privacy@sitelink.in
''';

const _kTermsOfService = '''
Last updated: March 2026

1. ACCEPTANCE OF TERMS
By using the SiteLink platform, you agree to be bound by these Terms of Service.

2. WORKER ELIGIBILITY
To register as a Worker on SiteLink, you must:
• Be at least 18 years of age
• Possess valid identity documents
• Have genuine work skills and experience as declared

3. PLATFORM ROLE
SiteLink acts as an intermediary platform. We do not directly employ workers or vendors. Job assignments are facilitated through our admin team to ensure quality and trust.

4. ADMIN ASSIGNMENT MODEL
Workers cannot directly contact vendors through SiteLink. All assignments are made by our admin team after verifying both worker and vendor profiles.

5. WORKER RESPONSIBILITIES
• Maintain accurate and up-to-date profile information
• Report for assigned jobs on time as agreed
• Behave professionally at all work sites
• Report any issues through the SiteLink platform

6. PLATFORM FEES
SiteLink currently offers its platform services free of charge to workers. This may be subject to change with prior notice.

7. TERMINATION
SiteLink reserves the right to suspend or terminate accounts that violate these terms or engage in fraudulent activity.

8. CONTACT
For terms-related queries, contact: legal@sitelink.in
''';