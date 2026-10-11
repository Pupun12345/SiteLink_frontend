import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/services/locale_service.dart';
import '../../../shared/presentation/views/change_phone_sheet.dart';
import '../../../shared/presentation/views/help_support_views.dart';
import '../controllers/worker_profile_controller.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../core/services/api_client.dart';
import '../../../shared/presentation/views/plan_status_banner.dart';
import 'edit_profile_view.dart';
import 'worker_documents_view.dart';
import 'worker_plans_view.dart';

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

  /// Shared helper — double-tap guard + loader wahin hai.
  Future<void> logout() => performLogout();

  /// Paid features (Contact Support) ka lock isse decide hota hai.
  /// Backend `hasActivePlan` live compute karke bhejta hai.
  final hasActivePlan = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPlanStatus();
  }

  /// Public hai kyunki plan khareedne ke baad `refreshAfterPlanChange()`
  /// ise bulata hai — warna Contact Support ka lock khula hi nahi dikhta.
  Future<void> loadPlanStatus() async {
    try {
      final res = await ProfileApiService().getMe();
      hasActivePlan.value = res.user?.hasActivePlan ?? false;
    } catch (_) {/* fail par locked hi rehta hai — backend bhi enforce karta hai */}
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
      appBar: GradientAppBar(title: 'settings_title'.tr),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.lg),
          children: [
            // ── Account ──────────────────────────────────────
            _SectionLabel(label: 'account_section'.tr),
            AppCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'edit_profile_tile'.tr,
                    onTap: () => Get.to(() => const EditProfileView()),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.phone_outlined,
                    title: 'change_phone_number'.tr,
                    onTap: () => showChangePhoneSheet(
                      context,
                      // Number badalne par Profile tab ka data refresh
                      onUpdated: (_) {
                        if (Get.isRegistered<WorkerProfileController>()) {
                          Get.find<WorkerProfileController>().fetchProfile();
                        }
                      },
                    ),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.badge_outlined,
                    title: 'my_documents'.tr,
                    onTap: () => Get.to(() => const WorkerDocumentsView()),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.workspace_premium_rounded,
                    title: 'sitelink_premium'.tr,
                    subtitle: 'premium_upgrade_subtitle'.tr,
                    onTap: () => Get.to(() => const WorkerPlansView()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ── Preferences ──────────────────────────────────
            _SectionLabel(label: 'preferences_section'.tr),
            AppCard(
              child: Column(
                children: [
                  Obx(() => _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'push_notifications'.tr,
                    trailing: Switch(
                      value: ctrl.notificationsEnabled.value,
                      onChanged: ctrl.toggleNotifications,
                      activeColor: AppColors.primary,
                    ),
                  )),
                  _Divider(),
                  Obx(() => _SettingsTile(
                    icon: Icons.language_outlined,
                    title: AppStrings.Language,
                    subtitle: ctrl.languageCode.value == 'hi'
                        ? AppStrings.Hindi
                        : AppStrings.English,
                    onTap: () => _showLanguageSheet(context, ctrl),
                  )),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ── Support ──────────────────────────────────────
            _SectionLabel(label: 'support_section'.tr),
            AppCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'help_faq_title'.tr,
                    onTap: () => Get.to(() => PolicyView(
                      title: 'help_faq_title'.tr,
                      content: _kHelpFaq,
                      policyType: 'HELP_AND_SUPPORT',
                    )),
                  ),
                  _Divider(),
                  // Contact Support paid feature hai ("Call & WhatsApp
                  // Support"). Entry chhupate nahi — lock ke saath dikhate
                  // hain, tap par Plans khulti hai. Chhupa dene se user ko
                  // pata hi nahi chalta ki feature hai.
                  Obx(() {
                    final locked = !ctrl.hasActivePlan.value;
                    return _SettingsTile(
                      icon: Icons.support_agent_outlined,
                      title: 'contact_support'.tr,
                      trailing: locked ? const PlanLockChip() : null,
                      onTap: () => locked
                          ? Get.to(() => const WorkerPlansView())
                          : Get.to(() => const ContactSupportView()),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ── Legal ─────────────────────────────────────────
            _SectionLabel(label: 'legal_section'.tr),
            AppCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: AppStrings.PrivacyPolicy,
                    onTap: () => Get.to(() => PolicyView(
                      title: AppStrings.PrivacyPolicy,
                      content: _kPrivacyPolicy,
                      policyType: 'PRIVACY_POLICY',
                    )),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'terms_of_service'.tr,
                    onTap: () => Get.to(() => PolicyView(
                      title: 'terms_of_service'.tr,
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
              label: AppStrings.Logout,
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
                Text('select_language_title'.tr, style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600)),
                const SizedBox(height: 14),
                Obx(() => Column(
                  children: [
                    _LanguageOption(
                      label: AppStrings.English,
                      code: 'en',
                      selected: ctrl.languageCode.value == 'en',
                      onTap: () { ctrl.setLanguage('en'); Get.back(); },
                    ),
                    const SizedBox(height: 8),
                    _LanguageOption(
                      label: AppStrings.Hindi,
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
  // `Get.dialog` (Flutter ka `showDialog` nahi): performLogout confirm
  // dialog ko `Get.isDialogOpen` dekh kar band karta hai, aur wo flag
  // sirf Get se khule dialogs par set hota hai. Vendor/legacy screens
  // bhi Get.dialog hi use karti hain.
  void _showLogoutDialog(BuildContext context, WorkerSettingsController ctrl) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: Text(AppStrings.Logout, style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
        content: Text(
          'logout_confirm_message'.tr,
          style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel_label'.tr, style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: ctrl.logout,
            child: Text(AppStrings.Logout, style: KTextStyle.poppins(fs: 13, c: Colors.red, fw: FontWeight.w600)),
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
const _kHelpFaq = '''
## Help & FAQ

Help content update ho raha hai — kripya thodi der baad dobara try karein,
ya **Contact Support** se humse seedha judein.
''';

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