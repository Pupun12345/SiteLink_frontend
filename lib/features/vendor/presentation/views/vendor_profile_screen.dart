import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../shared/presentation/views/help_support_views.dart';
import '../../../shared/presentation/views/my_post_card.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';
import '../controllers/vendor_profile_controller.dart';
import 'edit_vendor_profile_view.dart';
import 'vendor_plans_view.dart';

// ── Vendor-specific FAQ content (shared FaqView UI, apna content) ──
const _kVendorFaqs = [
  ('How does SiteLink work for vendors?',
      'Vendors post job requirements on SiteLink. Verified workers apply, and you can review each applicant\'s profile and confirm the ones you want to hire — directly from the app.'),
  ('How do I post a job?',
      'Go to My Posted Jobs → tap the + button → fill role, pay, experience, and amenities → submit. Your account must be verified before jobs go live.'),
  ('How long does vendor verification take?',
      'Account verification (PAN, GST, company details) typically takes 24–48 hours after submission.'),
  ('How do I confirm a worker who applied?',
      'Open the job → tap "Applicants" → review the worker\'s profile, experience and cover letter → tap Confirm to hire, or Reject to decline.'),
  ('Can I edit or delete a posted job?',
      'You can delete a job anytime from My Posted Jobs (3-dot menu). Editing an existing job is not supported yet — post a new one instead.'),
  ('How are payments handled?',
      'Payments are settled directly between you and the worker. SiteLink provides the platform and admin support — payment terms are agreed upon at the time of hiring.'),
];

const _kVendorPrivacyPolicy = '''
Last updated: March 2026

1. INFORMATION WE COLLECT
SiteLink collects information you provide directly, such as your company name, contact person details, PAN, GST number, company documents, and job postings when you register as a Vendor on our platform.

2. HOW WE USE YOUR INFORMATION
We use the information we collect to:
• Verify your business identity and eligibility to post jobs
• Match your job postings with suitable workers
• Communicate with you about applicants and hiring
• Improve our platform and services

3. INFORMATION SHARING
We share your company profile and job details (title, location, pay, requirements) publicly with workers browsing jobs. Applicant details (worker profiles) are shared with you only after they apply to your job. We do not sell your business data to third parties.

4. DOCUMENT SECURITY
Documents such as PAN card and GST certificate are stored securely and used solely for business verification purposes. Access is restricted to authorised SiteLink admin staff only.

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
By using the SiteLink platform, you agree to be bound by these Terms of Service.

2. VENDOR ELIGIBILITY
To register as a Vendor on SiteLink, you must:
• Represent a genuine, registered business or hiring entity
• Provide valid PAN and (where applicable) GST documentation
• Have a genuine requirement to hire workers through the platform

3. PLATFORM ROLE
SiteLink acts as an intermediary platform. We do not directly employ workers or guarantee hiring outcomes. Job postings and applications are facilitated through our platform, with admin oversight to ensure quality and trust.

4. JOB POSTING RULES
• Job postings must accurately describe the role, pay, and requirements
• Fraudulent, misleading, or discriminatory job postings are not allowed
• SiteLink reserves the right to remove any job posting that violates these terms

5. VENDOR RESPONSIBILITIES
• Maintain accurate and up-to-date company information
• Review applicants fairly and respond within a reasonable time
• Honor the pay and terms stated in your job posting
• Behave professionally with workers at all times

6. PLATFORM FEES
SiteLink currently offers its platform services free of charge to vendors. This may be subject to change with prior notice. Optional premium plans may be introduced for additional visibility.

7. TERMINATION
SiteLink reserves the right to suspend or terminate accounts that violate these terms, post fraudulent jobs, or engage in unfair hiring practices.

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
          onRefresh: ctrl.fetchProfile,
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
                    _documents(context, p),
                    const SizedBox(height: AppDimens.md),
                    _support(context),
                    const SizedBox(height: AppDimens.md),
                    _legal(context),
                    const SizedBox(height: AppDimens.md),
                    _settings(context),
                  ]),
                ),
              ),
              _buildPostsHeader(),
              _buildPostsList(ctrl),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.lg),
                  child: Center(
                    child: Text('SiteLink  v1.0.0',
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
      title: Text('Company Profile',
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
          Stack(children: [
            AvatarCircle(
              initials: _initials(company),
              size: 80,
              imageUrl: logoUrl,
            ),
            if (verified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
          ]),
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
                verified ? 'Verified Vendor' : 'Verification Pending',
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
                  label: 'Jobs Posted', value: '${ctrl.myJobsCount.value}'),
              _StatDivider(),
              _StatCell(
                  label: 'Active', value: '${ctrl.activeJobsCount.value}'),
              _StatDivider(),
              _StatCell(label: 'Posts', value: '${ctrl.postsCount.value}'),
            ]),
          )),
    );
  }

  // ── Posts header ──────────────────────────────────────────────────
  Widget _buildPostsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.md),
        child: Row(children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text('My Posts',
              style: KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Posts list — vendor apne bhi community posts (shared feed) ──
  Widget _buildPostsList(VendorProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final myPosts = ctrl.posts;

        if (myPosts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.post_add_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No posts yet',
                      style: KTextStyle.poppins(
                          fs: 13, c: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Share something from the Home feed',
                      style: KTextStyle.poppins(
                          fs: 12, c: AppColors.textHint)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (int i = 0; i < myPosts.length; i++)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.lg,
                  0,
                  AppDimens.lg,
                  i == myPosts.length - 1 ? AppDimens.xl : AppDimens.md,
                ),
                child: MyPostCard(
                  post: myPosts[i],
                  onDelete: () => _confirmDeletePost(myPosts[i].id, ctrl),
                ),
              ),
          ],
        );
      }),
    );
  }

  // ── Delete-post confirm dialog ───────────────────────────────────
  void _confirmDeletePost(String? postId, VendorProfileController ctrl) {
    if (postId == null) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Post Delete Karo?',
            style: KTextStyle.poppins(fs: 15, fw: FontWeight.w600)),
        content: Text(
            'Yeh post permanently delete ho jaayega. Kya aap sure hain?',
            style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              if (Get.isRegistered<WorkerFeedController>()) {
                Get.find<WorkerFeedController>().deletePost(postId);
              }
              ctrl.removePostLocally(postId); // profile list turant update
            },
            child: Text('Delete',
                style: KTextStyle.poppins(
                    fs: 13, fw: FontWeight.w600, c: Colors.red.shade600)),
          ),
        ],
      ),
    );
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
      (Icons.phone_android_outlined, 'Phone', p?.phone ?? ''),
      (Icons.email_outlined, 'Email', p?.email ?? ''),
      (Icons.chat_outlined, 'WhatsApp', p?.whatsappNumber ?? ''),
      (Icons.location_on_outlined, 'Location', location),
      (Icons.map_outlined, 'Work Area', p?.workArea ?? ''),
      (Icons.receipt_long_outlined, 'GST', p?.gstNumber ?? ''),
      (Icons.badge_outlined, 'PAN', p?.panNumber ?? ''),
      (Icons.language_outlined, 'Website', p?.website ?? ''),
      (Icons.calendar_today_rounded, 'Member Since', memberSince),
    ].where((r) => r.$3.isNotEmpty).toList();

    return _Card(
      title: 'Company Info',
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
      ('PAN Card', p?.panCardImage),
      ('GST Certificate', p?.gstCertificate),
      ('Company Logo', p?.companyLogo),
    ];
    return _Card(
      title: 'Documents',
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

  // ── Support (Help & FAQ / Contact Support / Rate App) ────────────
  Widget _support(BuildContext context) {
    return _Card(
      title: 'Support',
      icon: Icons.support_agent_outlined,
      child: Column(children: [
        _actionTile(
          icon: Icons.workspace_premium_rounded,
          label: 'SiteLink Premium — Plans',
          onTap: () => Get.to(() => const VendorPlansView()),
        ),
        _actionDivider(),
        _actionTile(
          icon: Icons.help_outline_rounded,
          label: 'Help & FAQ',
          onTap: () =>
              Get.to(() => const FaqView(faqs: _kVendorFaqs)),
        ),
        _actionDivider(),
        _actionTile(
          icon: Icons.support_agent_outlined,
          label: 'Contact Support',
          onTap: () => Get.to(() => const ContactSupportView()),
        ),
        _actionDivider(),
        _actionTile(
          icon: Icons.star_outline_rounded,
          label: 'Rate the App',
          onTap: () {/* TODO: launch store URL */},
        ),
      ]),
    );
  }

  // ── Legal (Privacy Policy / Terms of Service) ────────────────────
  Widget _legal(BuildContext context) {
    return _Card(
      title: 'Legal',
      icon: Icons.gavel_rounded,
      child: Column(children: [
        _actionTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          onTap: () => Get.to(() => const PolicyView(
                title: 'Privacy Policy',
                content: _kVendorPrivacyPolicy,
                policyType: 'PRIVACY_POLICY',
              )),
        ),
        _actionDivider(),
        _actionTile(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          onTap: () => Get.to(() => const PolicyView(
                title: 'Terms of Service',
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
      title: 'Account',
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
                child: Text('Language / भाषा',
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
              Text('Select Language / भाषा चुनें',
                  style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
              const SizedBox(height: 14),
              _langOption('English', 'english', !LocaleService.to.isHindi),
              const SizedBox(height: 10),
              _langOption('हिंदी', 'hindi', LocaleService.to.isHindi),
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
            Text('View',
                style: KTextStyle.poppins(
                    fs: 12, fw: FontWeight.w600, c: AppColors.primary)),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.primary),
          ]),
        )
      else
        Text('Not uploaded',
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
        label: 'Logout',
        isOutlined: true,
        onTap: () => Get.dialog(
          AlertDialog(
            title: Text('Logout?',
                style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
            content: Text('Are you sure you want to logout?',
                style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: Get.back, child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Get.back();
                  await MiscApiService().logout();
                  await AuthService.instance.signOut();
                  await SessionService.to.clear();
                  Get.offAllNamed(AppRoutes.language);
                },
                child: Text('Logout',
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
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(label,
              style: KTextStyle.poppins(fs: 10, c: AppColors.textHint),
              textAlign: TextAlign.center),
        ]),
      );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.divider);
}
