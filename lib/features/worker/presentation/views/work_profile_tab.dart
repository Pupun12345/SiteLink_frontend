import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/rating_badge.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../shared/presentation/views/my_posts_view.dart';
import '../controllers/worker_feed_controller.dart';
import '../controllers/worker_profile_controller.dart';
import 'worker_plans_view.dart';


class WorkerProfileTab extends StatelessWidget {
  const WorkerProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final ctrl     = Get.put(WorkerProfileController());
    final feedCtrl = Get.find<WorkerFeedController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      // Pull-to-refresh — profile + posts dono dobara fetch hote hai
      body: RefreshIndicator(
        onRefresh: ctrl.refreshAll,
        color: AppColors.primary,
        // Spinner pinned app bar ke neeche dikhe
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
        child: CustomScrollView(
          // Content chhota ho tab bhi pull-to-refresh chale
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            _buildAppBar(),
            _buildHeader(ctrl),
            _buildStats(feedCtrl, ctrl),
            _buildRatingCard(ctrl),
            _buildMyPostsTile(feedCtrl, ctrl),
            _buildSkillsSection(ctrl),
            _buildDocumentsSection(ctrl),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
      ),
      title: Text('my_profile_title'.tr,
          style: KTextStyle.poppins(
              fs: 18, fw: FontWeight.w600, c: Colors.white)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Get.toNamed(AppRoutes.workerSettings),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Obx(() => Container(
        width: double.infinity,
        decoration:
        const BoxDecoration(gradient: AppColors.appBarGradient),
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, 0, AppDimens.lg, AppDimens.xl),
        child: Column(children: [
          Stack(children: [
            AvatarCircle(
              initials: ctrl.initials.value,
              size: 80,
              imageUrl: ctrl.profileImage.value,
            ),
            if (ctrl.isVerified.value)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 2)),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Text(ctrl.name.value,
              style: KTextStyle.poppins(
                  fs: 20,
                  fw: FontWeight.w700,
                  c: Colors.white)),
          if (ctrl.email.value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(ctrl.email.value,
                style: KTextStyle.poppins(fs: 12, c: Colors.white70)),
          ],
          const SizedBox(height: 6),
          // Skill chip — apni alag row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusMax),
            ),
            child: Text(
              ctrl.primarySkill.value,
              style: KTextStyle.poppins(
                  fs: 12, fw: FontWeight.w600, c: AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          // Verified / Pending chip — apni alag row (vendor profile jaisa)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusMax),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                ctrl.isVerified.value
                    ? Icons.verified_rounded
                    : Icons.hourglass_top_rounded,
                size: 14,
                color: ctrl.isVerified.value
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                ctrl.isVerified.value
                    ? 'verified_worker_label'.tr
                    : 'verification_pending_title'.tr,
                style: KTextStyle.poppins(
                    fs: 12,
                    fw: FontWeight.w600,
                    c: ctrl.isVerified.value
                        ? AppColors.success
                        : AppColors.warning),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Text(ctrl.workerId.value,
              style: KTextStyle.poppins(
                  fs: 11, c: Colors.white60)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: Colors.white60),
              const SizedBox(width: 3),
              Text(ctrl.location.value,
                  style: KTextStyle.poppins(
                      fs: 12, c: Colors.white70)),
            ],
          ),
        ]),
      )),
    );
  }

  // ── Performance rating ────────────────────────────────────────
  // Rating job outcomes se khud banti hai — koi manually nahi deta.
  // Naye worker ko card batata hai ki rating aayegi kaise, warna "New"
  // dekh ke lagta hai kuch galat hai.
  Widget _buildRatingCard(WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, AppDimens.md, AppDimens.lg, 0),
        child: Obx(() => Column(
              children: [
                RatingSummaryCard(
                  rating: ctrl.rating.value,
                  comment: ctrl.ratingComment.value,
                ),
                // Plan na ho to saaf batao ki rating contractors ko dikhegi
                // hi nahi — warna worker ko lagta hai rating ka koi
                // matlab hi nahi.
                if (!ctrl.hasActivePlan.value) ...[
                  const SizedBox(height: AppDimens.sm),
                  RatingPlanNudge(
                    onViewPlans: () => Get.to(() => const WorkerPlansView()),
                  ),
                ],
              ],
            )),
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────
  Widget _buildStats(WorkerFeedController feedCtrl, WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Obx(() => Container(
        color: AppColors.surface,
        padding:
        const EdgeInsets.symmetric(vertical: AppDimens.lg),
        child: Row(children: [
          _StatCell(
              label: 'posts_label'.tr,
              value: '${ctrl.postsCount.value}',
              onTap: () => _openMyPosts(feedCtrl, ctrl)),
          _Divider(),
          _StatCell(
              label: 'rating_label'.tr,
              // Rating admin deta hai. Na mili ho to "0.0 ⭐" nahi
              // dikhate — 0 ka matlab "kharaab" nahi, "abhi rating nahi
              // mili" hai.
              value: (ctrl.rating.value ?? 0) > 0
                  ? '${ctrl.rating.value!.toStringAsFixed(1)} ⭐'
                  : 'rating_not_rated'.tr),
          _Divider(),
          _StatCell(
              label: 'experience_label'.tr,
              value: ctrl.experience.value),
        ]),
      )),
    );
  }

  // ── My Posts — apna alag page (clearly tappable tile) ──────────
  Widget _buildMyPostsTile(WorkerFeedController feedCtrl, WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, AppDimens.md, AppDimens.lg, 0),
        child: _ProfileCard(
          title: 'my_posts_label'.tr,
          icon: Icons.dynamic_feed_rounded,
          child: InkWell(
            onTap: () => _openMyPosts(feedCtrl, ctrl),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Row(children: [
              const Icon(Icons.post_add_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('view_my_posts'.tr,
                    style: KTextStyle.poppins(fs: 13)),
              ),
              Obx(() => Text('${ctrl.postsCount.value}',
                  style: KTextStyle.poppins(
                      fs: 12.5, fw: FontWeight.w600, c: AppColors.textHint))),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Skills ────────────────────────────────────────────────────
  Widget _buildSkillsSection(WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, AppDimens.lg, AppDimens.lg, 0),
        child: _ProfileCard(
          title: 'skills_section_title'.tr,
          icon: Icons.construction_rounded,
          child: Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ctrl.skills
                .map((s) =>
                SkillChip(label: s, selected: true))
                .toList(),
          )),
        ),
      ),
    );
  }

  // ── Documents ─────────────────────────────────────────────────
  Widget _buildDocumentsSection(WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, AppDimens.md, AppDimens.lg, 0),
        child: _ProfileCard(
          title: 'documents_label'.tr,
          icon: Icons.folder_outlined,
          child: Column(
            children: ctrl.documents
                .map((d) => _DocumentRow(doc: d))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ── Posts Header ──────────────────────────────────────────────
  // ── My Posts — apna alag page (profile screen se sirf navigate) ────
  void _openMyPosts(WorkerFeedController feedCtrl, WorkerProfileController ctrl) {
    Get.to(() => MyPostsView(
          posts: ctrl.posts,
          isLoading: ctrl.isLoadingPosts,
          onRefresh: ctrl.fetchMyPosts,
          onDelete: (postId) {
            feedCtrl.deletePost(postId);
            ctrl.removePostLocally(postId);
          },
        ));
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROFILE CARD WRAPPER
// ═══════════════════════════════════════════════════════════════════
class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ProfileCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius:
                  BorderRadius.circular(AppDimens.radiusSm)),
              child: Icon(icon, size: 15, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: KTextStyle.poppins(
                    fs: 13, fw: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DOCUMENT ROW
// ═══════════════════════════════════════════════════════════════════
class _DocumentRow extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DocumentRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        const Icon(Icons.description_outlined,
            size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(doc['label'] ?? '',
                style: KTextStyle.poppins(fs: 13))),
        if (doc['verified'] == true)
          const Icon(Icons.check_circle_rounded,
              size: 16, color: AppColors.success)
        else
          const Icon(Icons.pending_outlined,
              size: 16, color: AppColors.textHint),
      ]),
    );
  }
}

// ── Stat Cell ─────────────────────────────────────────────────────
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
            style: KTextStyle.poppins(
                fs: 16, fw: FontWeight.w700)),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: KTextStyle.poppins(
                    fs: 10, c: AppColors.textHint),
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.divider);
}