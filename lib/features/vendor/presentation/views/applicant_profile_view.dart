import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/community_feed_models.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/post_image_gallery.dart';
import '../../../../core/theme/rating_badge.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';
import '../../../worker/presentation/views/comments_sheet.dart';

// ═══════════════════════════════════════════════════════════════════
//  APPLICANT PROFILE — vendor applicant ko poora parakh sake
// ═══════════════════════════════════════════════════════════════════
// Pehle applicants list me sirf naam, skill aur rating dikhti thi. Hire
// karne ke faisle ke liye itna kaafi nahi — vendor ko ye bhi dekhna
// chahiye ki worker ne registration me kya documents diye aur community
// me kaisa hai.
//
// Do section:
//   Documents  → ID proof, experience certificate, work samples
//   Posts      → uske community posts (GET /community/posts/user/:id)
//
// Posts endpoint access-controlled hai: vendor sirf un workers ke posts
// dekh sakta hai jinhone uski job par apply kiya. Yahan hum wahi worker
// dikha rahe hain jo applicant hai, isliye allowed hai.
class ApplicantProfileView extends StatefulWidget {
  final JobApplicant applicant;
  const ApplicantProfileView({super.key, required this.applicant});

  @override
  State<ApplicantProfileView> createState() => _ApplicantProfileViewState();
}

class _ApplicantProfileViewState extends State<ApplicantProfileView> {
  final _communityApi = CommunityApiService();

  List<CommunityFeedModel> _posts = const [];
  bool _loadingPosts = true;

  JobApplicant get a => widget.applicant;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final id = a.workerId ?? '';
    if (id.isEmpty) {
      setState(() => _loadingPosts = false);
      return;
    }
    final res = await _communityApi.getPostsByUser(id);
    if (!mounted) return;
    setState(() {
      _posts = res.data ?? const [];
      _loadingPosts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'applicant_profile_title'.tr),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadPosts,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.lg),
            children: [
              _header(),
              const SizedBox(height: AppDimens.md),
              _documents(),
              const SizedBox(height: AppDimens.md),
              _postsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: avatar + naam + skill + rating ────────────────────────
  Widget _header() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              AvatarCircle(
                initials: _initials(a.name ?? ''),
                imageUrl: WorkerFeedController.fullUrl(a.profileImage),
                size: 56,
                fontSize: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(a.name ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KTextStyle.poppins(
                                fs: 16, fw: FontWeight.w700)),
                      ),
                      if (a.isVerified) ...[
                        const SizedBox(width: 5),
                        const VerifiedBadge(size: 14),
                      ],
                    ]),
                    if ((a.primarySkill ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(a.primarySkill!,
                          style: KTextStyle.poppins(
                              fs: 12.5, c: AppColors.textSecondary)),
                    ],
                    // rating null = worker ke paas plan nahi hai, rating
                    // chhupi hai. Tab kuch na dikhao — "New" jhooth hota.
                    if (a.rating != null) ...[
                      const SizedBox(height: 6),
                      RatingBadge(rating: a.rating, compact: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (a.skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in a.skills) SkillChip(label: s),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Documents ─────────────────────────────────────────────────────
  Widget _documents() {
    final govt = WorkerFeedController.fullUrl(a.governmentID);
    // Worker ek se zyada certificate laga sakta hai.
    final certs = a.experienceCertificate
        .map(WorkerFeedController.fullUrl)
        .where((u) => u.isNotEmpty)
        .toList();
    final hasAny = govt.isNotEmpty || certs.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('applicant_documents_label'.tr,
              style: KTextStyle.poppins(fs: 14, fw: FontWeight.w700)),
          const SizedBox(height: 12),
          if (!hasAny)
            Text('no_documents_uploaded'.tr,
                style:
                    KTextStyle.poppins(fs: 12, c: AppColors.textSecondary))
          else ...[
            if (govt.isNotEmpty)
              _docRow(
                icon: Icons.badge_outlined,
                label: 'doc_government_id'.tr,
                url: govt,
              ),
            for (int i = 0; i < certs.length; i++) ...[
              if (govt.isNotEmpty || i > 0) const SizedBox(height: 10),
              _docRow(
                icon: Icons.workspace_premium_outlined,
                // Ek se zyada hon to number bhi — warna saari rows ek
                // jaisi dikhti hain.
                label: certs.length > 1
                    ? '${'doc_experience_certificate'.tr} ${i + 1}'
                    : 'doc_experience_certificate'.tr,
                url: certs[i],
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Ek document ki row — tap par fullscreen view.
  ///
  /// PDF (experience certificate PDF ho sakta hai) ko image viewer me
  /// nahi kholte; uske liye "PDF" chip dikhate hain.
  Widget _docRow({
    required IconData icon,
    required String label,
    required String url,
  }) {
    final isPdf = url.toLowerCase().endsWith('.pdf');
    return InkWell(
      onTap: isPdf ? null : () => openImageGallery([url], 0),
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KTextStyle.poppins(fs: 13)),
            ),
            if (isPdf)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text('pdf_label'.tr,
                    style: KTextStyle.poppins(
                        fs: 10, c: AppColors.textSecondary)),
              )
            else
              Row(children: [
                Text('view_label'.tr,
                    style: KTextStyle.poppins(
                        fs: 12, fw: FontWeight.w600, c: AppColors.primary)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: AppColors.primary),
              ]),
          ],
        ),
      ),
    );
  }

  // ── Community posts ───────────────────────────────────────────────
  Widget _postsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('applicant_posts_label'.tr,
                  style: KTextStyle.poppins(fs: 14, fw: FontWeight.w700)),
            ),
            if (!_loadingPosts && _posts.isNotEmpty)
              Text('${_posts.length}',
                  style: KTextStyle.poppins(
                      fs: 13, fw: FontWeight.w700, c: AppColors.primary)),
          ]),
          const SizedBox(height: 12),
          if (_loadingPosts)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: AppColors.primary),
                ),
              ),
            )
          else if (_posts.isEmpty)
            Text('applicant_no_posts'.tr,
                style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary))
          else
            for (int i = 0; i < _posts.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: AppColors.divider),
              _postTile(_posts[i]),
            ],
        ],
      ),
    );
  }

  Widget _postTile(CommunityFeedModel p) {
    final images = (p.images ?? [])
        .map(WorkerFeedController.fullUrl)
        .where((u) => u.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((p.content ?? '').isNotEmpty)
          Text(p.content!,
              style: KTextStyle.poppins(fs: 12.5, height: 1.45)),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: PostImagesDisplay(urls: images),
          ),
        ],
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.favorite_border_rounded,
              size: 13, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text('${p.likesCount ?? 0}',
              style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
          const SizedBox(width: 12),
          // Comments khol sakte hain — vendor dekh sake ki logon ne is
          // worker ke kaam par kya kaha.
          InkWell(
            onTap: () => CommentsSheet.open(context, p.id ?? ''),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(children: [
                Icon(
                    (p.commentsCount ?? 0) > 0
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 13,
                    color: (p.commentsCount ?? 0) > 0
                        ? AppColors.primary
                        : AppColors.textHint),
                const SizedBox(width: 4),
                Text('${p.commentsCount ?? 0}',
                    style: KTextStyle.poppins(
                        fs: 11,
                        c: (p.commentsCount ?? 0) > 0
                            ? AppColors.primary
                            : AppColors.textHint)),
              ]),
            ),
          ),
        ]),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
