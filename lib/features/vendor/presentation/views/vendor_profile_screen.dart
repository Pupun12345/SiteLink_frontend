import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../shared/presentation/views/help_support_views.dart';
import '../../../shared/presentation/views/my_posts_view.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';
import '../controllers/vendor_profile_controller.dart';
import '../../../../core/services/logout_service.dart';
import '../../../shared/presentation/views/plan_status_banner.dart';
import 'edit_vendor_profile_view.dart';
import 'vendor_plans_view.dart';

const _kVendorHelpFaq = '''
## Help & FAQ

Help content update ho raha hai — kripya thodi der baad dobara try karein,
ya **Contact Support** se humse seedha judein.
''';

const _kVendorPrivacyPolicy = '''
Last updated: March 2026

1. INFORMATION WE COLLECT
Sitelink collects information you provide directly, such as your company name, contact person details, PAN, GST number, company documents, and job postings when you register as a Vendor on our platform.

2. HOW WE USE YOUR INFORMATION
We use the information we collect to:
• Verify your business identity and eligibility to post jobs
• Match your job postings with suitable workers
• Communicate with you about applicants and hiring
• Improve our platform and services

3. INFORMATION SHARING
We share your company profile and job details (title, location, pay, requirements) publicly with workers browsing jobs. Applicant details (worker profiles) are shared with you only after they apply to your job. We do not sell your business data to third parties.

4. DOCUMENT SECURITY
Documents such as PAN card and GST certificate are stored securely and used solely for business verification purposes. Access is restricted to authorised Sitelink admin staff only.

5. DATA RETENTION
We retain your account information for as long as your account is active or as needed to provide services. You may request deletion of your account by contacting support.

6. YOUR RIGHTS
You have the right to access, update, or delete your personal and business information. Contact support@sitelink.in to exercise these rights.

7. CONTACT US
For privacy-related queries, contact: privacy@sitelink.in
''';

const _kVendorTermsOfService = '''
Last updated: March 2026

1. ACCEPTANCE OF TERMS
By using the Sitelink platform, you agree to be bound by these Terms of Service.

2. VENDOR ELIGIBILITY
To register as a Vendor on Sitelink, you must:
• Represent a genuine, registered business or hiring entity
• Provide valid PAN and (where applicable) GST documentation
• Have a genuine requirement to hire workers through the platform

3. PLATFORM ROLE
Sitelink acts as an intermediary platform. We do not directly employ workers or guarantee hiring outcomes. Job postings and applications are facilitated through our platform, with admin oversight to ensure quality and trust.

4. JOB POSTING RULES
• Job postings must accurately describe the role, pay, and requirements
• Fraudulent, misleading, or discriminatory job postings are not allowed
• Sitelink reserves the right to remove any job posting that violates these terms

5. VENDOR RESPONSIBILITIES
• Maintain accurate and up-to-date company information
• Review applicants fairly and respond within a reasonable time
• Honor the pay and terms stated in your job posting
• Behave professionally with workers at all times

6. PLATFORM FEES
Sitelink currently offers its platform services free of charge to vendors. This may be subject to change with prior notice. Optional premium plans may be introduced for additional visibility.

7. TERMINATION
Sitelink reserves the right to suspend or terminate accounts that violate these terms, post fraudulent jobs, or engage in unfair hiring practices.

8. CONTACT
For terms-related queries, contact: legal@sitelink.in
''';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR PROFILE SCREEN — real /api/profile/me (vendor)
// ═══════════════════════════════════════════════════════════════════
class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VendorProfileController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.profile.value == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final p = ctrl.profile.value;
        return RefreshIndicator(
          onRefresh: ctrl.refreshAll,
          color: AppColors.primary,
          edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              _buildAppBar(ctrl),
              _buildHeroHeader(p),
              _buildStatsRow(ctrl),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.lg, AppDimens.lg, AppDimens.lg, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _companyInfo(p),
                    const SizedBox(height: AppDimens.md),
                    _myPosts(ctrl),
                    const SizedBox(height: AppDimens.md),
                    _documents(context, p),
                    const SizedBox(height: AppDimens.md),
                    _support(context, p?.hasActivePlan ?? false),
                    const SizedBox(height: AppDimens.md),
                    _legal(context),
                    const SizedBox(height: AppDimens.md),
                    _settings(context),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.lg),
                  child: Center(
                    child: Text('Sitelink  v1.0.0',
                        style: KTextStyle.poppins(
                            fs: 11, c: AppColors.textHint)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── AppBar (pinned, gradient) ────────────────────────────────────
  Widget _buildAppBar(VendorProfileController ctrl) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
      ),
      title: Text('company_profile'.tr,
          style: KTextStyle.poppins(
              fs: 18, fw: FontWeight.w600, c: Colors.white)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () async {
            final changed = await Get.to(() => const EditVendorProfileView());
            if (changed == true) ctrl.fetchProfile();
          },
        ),
      ],
    );
  }

  // ── Hero header (logo + company + verified + location) ──────────
  Widget _buildHeroHeader(MyProfile? p) {
    final logoUrl =
        WorkerFeedController.fullUrl(p?.companyLogo ?? p?.profileImage);
    final company = (p?.companyName ?? '').isNotEmpty
        ? p!.companyName!
        : (p?.name ?? 'Company');
    final verified = p?.isVerified ?? false;
    final location = [p?.workCity, p?.workState]
        .where((e) => (e ?? '').isNotEmpty)
        .join(', ');

    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, 0, AppDimens.lg, AppDimens.xl),
        child: Column(children: [
          // Logo par koi tick badge nahi — verified status neeche wale
          // chip se hi dikhta hai ("Verified vendor" / "Verification
          // pending"), do jagah dikhana repeat tha.
          AvatarCircle(
            initials: _initials(company),
            size: 80,
            imageUrl: logoUrl,
          ),
          const SizedBox(height: 12),
          Text(company,
              style: KTextStyle.poppins(
                  fs: 20, fw: FontWeight.w700, c: Colors.white),
              textAlign: TextAlign.center),
          if ((p?.name ?? '').isNotEmpty || (p?.designation ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [p?.name, p?.designation]
                  .where((e) => (e ?? '').isNotEmpty)
                  .join(' · '),
              style: KTextStyle.poppins(fs: 12, c: Colors.white70),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusMax),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                verified
                    ? Icons.verified_rounded
                    : Icons.hourglass_top_rounded,
                size: 14,
                color: verified ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                verified ? 'verified_vendor_label'.tr : 'verification_pending_title'.tr,
                style: KTextStyle.poppins(
                    fs: 12,
                    fw: FontWeight.w600,
                    c: verified ? AppColors.success : AppColors.warning),
              ),
            ]),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: Colors.white60),
              const SizedBox(width: 3),
              Text(location,
                  style: KTextStyle.poppins(fs: 12, c: Colors.white70)),
            ]),
          ],
        ]),
      ),
    );
  }

  // ── Stats (posted jobs + posts) ──────────────────────────────────
  Widget _buildStatsRow(VendorProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Obx(() => Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
            child: Row(children: [
              _StatCell(
                  label: 'jobs_posted_label'.tr, value: '${ctrl.myJobsCount.value}'),
              _StatDivider(),
              _StatCell(
                  label: 'active_status_label'.tr, value: '${ctrl.activeJobsCount.value}'),
              _StatDivider(),
              _StatCell(
                label: 'posts_label'.tr,
                value: '${ctrl.postsCount.value}',
                onTap: () => _openMyPosts(ctrl),
              ),
            ]),
          )),
    );
  }

  // ── My Posts — apna alag page (profile screen se sirf navigate) ────
  void _openMyPosts(VendorProfileController ctrl) {
    Get.to(() => MyPostsView(
          posts: ctrl.posts,
          isLoading: ctrl.isLoadingPosts,
          onRefresh: ctrl.fetchMyPosts,
          onDelete: (postId) {
            if (Get.isRegistered<WorkerFeedController>()) {
              Get.find<WorkerFeedController>().deletePost(postId);
            }
            ctrl.removePostLocally(postId);
          },
        ));
  }

  // ── Company info card ───────────────────────────────────────────
  Widget _companyInfo(MyProfile? p) {
    final location = [p?.workCity, p?.workState]
        .where((e) => (e ?? '').isNotEmpty)
        .join(', ');
    final memberSince = p?.createdAt != null
        ? '${_month(p!.createdAt!.month)} ${p.createdAt!.year}'
        : '';
    final rows = <(IconData, String, String)>[
      (Icons.phone_android_outlined, 'phone_label'.tr, p?.phone ?? ''),
      (Icons.email_outlined, 'email_label'.tr, p?.email ?? ''),
      (Icons.chat_outlined, 'whatsapp'.tr, p?.whatsappNumber ?? ''),
      (Icons.location_on_outlined, 'location_label'.tr, location),
      (Icons.map_outlined, 'work_area'.tr, p?.workArea ?? ''),
      (Icons.receipt_long_outlined, 'gst_label'.tr, p?.gstNumber ?? ''),
      (Icons.badge_outlined, 'pan_label'.tr, p?.panNumber ?? ''),
      (Icons.language_outlined, 'website_label'.tr, p?.website ?? ''),
      (Icons.calendar_today_rounded, 'member_since_label'.tr, memberSince),
    ].where((r) => r.$3.isNotEmpty).toList();

    return _Card(
      title: 'company_info_section'.tr,
      icon: Icons.business_rounded,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _InfoRow(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
          ],
        ],
      ),
    );
  }

  // ── Documents ───────────────────────────────────────────────────
  Widget _documents(BuildContext context, MyProfile? p) {
    final docs = <(String, String?)>[
      ('pan_card_label'.tr, p?.panCardImage),
      ('gst_certificate_label'.tr, p?.gstCertificate),
      ('company_logo_label'.tr, p?.companyLogo),
    ];
    return _Card(
      title: 'documents_label'.tr,
      icon: Icons.folder_outlined,
      child: Column(
        children: [
          for (int i = 0; i < docs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _DocRow(
              label: docs[i].$1,
              url: WorkerFeedController.fullUrl(docs[i].$2),
              onView: (url) => _viewImage(context, url),
            ),
          ],
        ],
      ),
    );
  }

  void _viewImage(BuildContext context, String url) {
    Get.dialog(
      Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: Image.network(url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 54)),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: Get.back,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Support (Help & FAQ / Contact Support) ───────────────────────
  // ── My Posts — apna alag page (clearly tappable tile) ─────────────
  Widget _myPosts(VendorProfileController ctrl) {
    return _Card(
      title: 'my_posts_label'.tr,
      icon: Icons.dynamic_feed_rounded,
      child: _actionTile(
        icon: Icons.post_add_rounded,
        label: 'view_my_posts'.tr,
        trailing: Obx(() => Text('${ctrl.postsCount.value}',
            style: KTextStyle.poppins(
                fs: 12.5, fw: FontWeight.w600, c: AppColors.textHint))),
        onTap: () => _openMyPosts(ctrl),
      ),
    );
  }

  Widget _support(BuildContext context, bool hasActivePlan) {
    return _Card(
      title: 'support_section'.tr,
      icon: Icons.support_agent_outlined,
      child: Column(children: [
        _actionTile(
          icon: Icons.workspace_premium_rounded,
          label: 'sitelink_premium_plans_label'.tr,
          onTap: () => Get.to(() => const VendorPlansView()),
        ),
        _actionDivider(),
        _actionTile(
          icon: Icons.help_outline_rounded,
          label: 'help_faq_title'.tr,
          onTap: () => Get.to(() => PolicyView(
                title: 'help_faq_title'.tr,
                content: _kVendorHelpFaq,
                policyType: 'HELP_AND_SUPPORT',
              )),
        ),
        _actionDivider(),
        // Contact Support paid feature hai. Entry chhupate nahi — lock ke
        // saath dikhate hain, tap par Plans khulti hai.
        _actionTile(
          icon: Icons.support_agent_outlined,
          label: 'contact_support'.tr,
          trailing: hasActivePlan ? null : const PlanLockChip(),
          onTap: () => hasActivePlan
              ? Get.to(() => const ContactSupportView())
              : Get.to(() => const VendorPlansView()),
        ),
      ]),
    );
  }

  // ── Legal (Privacy Policy / Terms of Service) ────────────────────
  Widget _legal(BuildContext context) {
    return _Card(
      title: 'legal_section'.tr,
      icon: Icons.gavel_rounded,
      child: Column(children: [
        _actionTile(
          icon: Icons.privacy_tip_outlined,
          label: 'privacy_policy'.tr,
          onTap: () => Get.to(() => PolicyView(
                title: 'privacy_policy'.tr,
                content: _kVendorPrivacyPolicy,
                policyType: 'PRIVACY_POLICY',
              )),
        ),
        _actionDivider(),
        _actionTile(
          icon: Icons.description_outlined,
          label: 'terms_of_service'.tr,
          onTap: () => Get.to(() => PolicyView(
                title: 'terms_of_service'.tr,
                content: _kVendorTermsOfService,
                policyType: 'TERMS_AND_CONDITIONS',
              )),
        ),
      ]),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: KTextStyle.poppins(fs: 13)),
          ),
          if (trailing != null) ...[trailing, const SizedBox(width: 6)],
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint),
        ]),
      ),
    );
  }

  Widget _actionDivider() =>
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Divider(height: 1, color: AppColors.divider),
      );

  // ── Settings (language + logout) ─────────────────────────────────
  Widget _settings(BuildContext context) {
    return _Card(
      title: 'account_section'.tr,
      icon: Icons.settings_outlined,
      child: Column(children: [
        InkWell(
          onTap: () => _showLanguageSheet(context),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.language_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('language'.tr,
                    style: KTextStyle.poppins(fs: 13)),
              ),
              Text(LocaleService.to.isHindi ? 'हिंदी' : 'English',
                  style: KTextStyle.poppins(
                      fs: 12.5,
                      fw: FontWeight.w600,
                      c: AppColors.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
            ]),
          ),
        ),
        _actionDivider(),
        const SizedBox(height: 8),
        _LogoutButton(),
      ]),
    );
  }

  // ── Language bottom sheet ────────────────────────────────────────
  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('select_language_title'.tr,
                  style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
              const SizedBox(height: 14),
              _langOption('english'.tr, 'english', !LocaleService.to.isHindi),
              const SizedBox(height: 10),
              _langOption('hindi'.tr, 'hindi', LocaleService.to.isHindi),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langOption(String label, String lang, bool selected) {
    return InkWell(
      onTap: () {
        LocaleService.to.setLanguage(lang);
        Get.back();
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectionBg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }

  String _initials(String s) {
    final parts =
        s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

// ── Reusable card wrapper ─────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(icon, size: 15, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    // Label upar, value neeche full-width wrap ke saath — lambi values
    // (address, website, phone with code) ab ellipsis se katengi nahi.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: KTextStyle.poppins(fs: 12, c: AppColors.textHint)),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            value,
            style: KTextStyle.poppins(fs: 12.5, fw: FontWeight.w500),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  final String label;
  final String url;
  final void Function(String) onView;
  const _DocRow(
      {required this.label, required this.url, required this.onView});

  @override
  Widget build(BuildContext context) {
    final has = url.isNotEmpty;
    return Row(children: [
      const Icon(Icons.description_outlined,
          size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: KTextStyle.poppins(fs: 13))),
      if (has)
        GestureDetector(
          onTap: () => onView(url),
          child: Row(children: [
            Text('view_label'.tr,
                style: KTextStyle.poppins(
                    fs: 12, fw: FontWeight.w600, c: AppColors.primary)),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.primary),
          ]),
        )
      else
        Text('not_uploaded_label'.tr,
            style: KTextStyle.poppins(fs: 11.5, c: AppColors.textHint)),
    ]);
  }
}

// ── Logout button ─────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        label: 'logout'.tr,
        isOutlined: true,
        onTap: () => Get.dialog(
          AlertDialog(
            title: Text('logout_confirm_title'.tr,
                style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
            content: Text('logout_confirm_message'.tr,
                style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: Get.back, child: Text('cancel_label'.tr)),
              TextButton(
                // Dialog band karna + guard + loader sab performLogout
                // ke andar — yahan sirf trigger.
                onPressed: performLogout,
                child: Text('logout'.tr,
                    style: KTextStyle.poppins(
                        fs: 13, fw: FontWeight.w600, c: AppColors.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat cell + divider (stats row) ─────────────────────────────────
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _StatCell({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(children: [
            Text(value,
                style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: KTextStyle.poppins(fs: 10, c: AppColors.textHint),
                    textAlign: TextAlign.center),
                if (onTap != null) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 12, color: AppColors.textHint),
                ],
              ],
            ),
          ]),
        ),
      );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.divider);
}
