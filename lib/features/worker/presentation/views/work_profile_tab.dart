import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sitelink/features/worker/presentation/views/worker_setting_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/worker_feed_controller.dart';
import '../controllers/worker_profile_controller.dart';


// ═══════════════════════════════════════════════════════════════════
//  WORKER PROFILE TAB  —  Tab 3
// ═══════════════════════════════════════════════════════════════════
class WorkerProfileTab extends StatelessWidget {
  const WorkerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl     = Get.put(WorkerProfileController());
    final feedCtrl = Get.find<WorkerFeedController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildHeader(ctrl),
          _buildStats(ctrl),
          _buildSkillsSection(ctrl),
          _buildDocumentsSection(ctrl),
          _buildPostsHeader(),
          _buildPostsList(feedCtrl, ctrl),
        ],
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
      title: Text('My Profile', style: KTextStyle.poppins(fs: 18, fw: FontWeight.w600, c: Colors.white)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Get.to(() => const WorkerSettingsView()),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Obx(() => Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, 0, AppDimens.lg, AppDimens.xl),
        child: Column(
          children: [
            Stack(
              children: [
                AvatarCircle(initials: ctrl.initials.value, size: 80),
                if (ctrl.isVerified.value)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ctrl.name.value,
              style: KTextStyle.poppins(fs: 20, fw: FontWeight.w700, c: Colors.white),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkillChip(label: ctrl.primarySkill.value, selected: true),
                const SizedBox(width: 8),
                if (ctrl.isVerified.value) StatusBadge(type: BadgeType.verified),
              ],
            ),
            const SizedBox(height: 6),
            Text(ctrl.workerId.value, style: KTextStyle.poppins(fs: 11, c: Colors.white60)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Colors.white60),
                const SizedBox(width: 3),
                Text(ctrl.location.value, style: KTextStyle.poppins(fs: 12, c: Colors.white70)),
              ],
            ),
          ],
        ),
      )),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────
  Widget _buildStats(WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Obx(() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
        child: Row(
          children: [
            _StatCell(label: 'Total Jobs',  value: '${ctrl.totalJobs.value}'),
            _Divider(),
            _StatCell(label: 'Completed',   value: '${ctrl.completedJobs.value}'),
            _Divider(),
            _StatCell(label: 'Rating',      value: '${ctrl.rating.value} ⭐'),
            _Divider(),
            _StatCell(label: 'Experience',  value: ctrl.experience.value),
          ],
        ),
      )),
    );
  }

  // ── Skills ────────────────────────────────────────────────────
  Widget _buildSkillsSection(WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, 0),
        child: _ProfileCard(
          title: 'Skills',
          icon: Icons.construction_rounded,
          child: Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ctrl.skills.map((s) => SkillChip(label: s, selected: true)).toList(),
          )),
        ),
      ),
    );
  }

  // ── Documents ─────────────────────────────────────────────────
  Widget _buildDocumentsSection(WorkerProfileController ctrl) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.md, AppDimens.lg, 0),
        child: _ProfileCard(
          title: 'Documents',
          icon: Icons.folder_outlined,
          child: Obx(() => Column(
            children: ctrl.documents.map((d) => _DocumentRow(doc: d)).toList(),
          )),
        ),
      ),
    );
  }

  // ── Posts Header ──────────────────────────────────────────────
  Widget _buildPostsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.md),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text('My Posts', style: KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Posts List ────────────────────────────────────────────────
  Widget _buildPostsList(WorkerFeedController feedCtrl, WorkerProfileController ctrl) {
    return Obx(() {
      final myPosts = feedCtrl.getPostsByUser(ctrl.currentUserId);

      if (myPosts.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.post_add_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No posts yet', style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Share from the Home feed', style: KTextStyle.poppins(fs: 12, c: AppColors.textHint)),
                ],
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final post   = myPosts[index];
            final isLast = index == myPosts.length - 1;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.lg, 0, AppDimens.lg,
                isLast ? AppDimens.xl : AppDimens.md,
              ),
              child: _ProfilePostCard(post: post),
            );
          },
          childCount: myPosts.length,
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROFILE CARD WRAPPER
// ═══════════════════════════════════════════════════════════════════
class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ProfileCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Icon(icon, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(title, style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600)),
            ],
          ),
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
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(doc['label'] ?? '', style: KTextStyle.poppins(fs: 13))),
          if (doc['verified'] == true)
            const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success)
          else
            const Icon(Icons.pending_outlined, size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROFILE POST CARD
// ═══════════════════════════════════════════════════════════════════
class _ProfilePostCard extends StatelessWidget {
  final PostModel post;
  const _ProfilePostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.description,
            style: KTextStyle.poppins(fs: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.grey.shade100,
                  child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite_border_rounded, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('${post.likesCount}', style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
              const Spacer(),
              Text(_timeAgo(post.createdAt), style: KTextStyle.poppins(fs: 10, c: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ── Stat Cell ─────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label, style: KTextStyle.poppins(fs: 10, c: AppColors.textHint), textAlign: TextAlign.center),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32, color: AppColors.divider);
}