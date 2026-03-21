import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/custom_cirular_indicator.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';

import '../controllers/worker_home_controller.dart';
import '../controllers/worker_feed_controller.dart';
import 'active_job_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER HOME TAB  —  Tab 0
//  Shows: profile card, active/no-job card, skills, community feed
// ═══════════════════════════════════════════════════════════════════
class WorkerHomeTab extends StatelessWidget {
  final WorkerHomeController homeCtrl;
  const WorkerHomeTab({super.key, required this.homeCtrl});

  @override
  Widget build(BuildContext context) {
    final feedCtrl = Get.put(WorkerFeedController());

    return CustomScrollView(
      slivers: [
        _buildAppBar(feedCtrl),
        _buildProfileCard(),
        _buildActiveJobSection(),
        _buildSkillsSection(),
        _buildFeedHeader(context, feedCtrl),
        _buildFeedList(feedCtrl),
      ],
    );
  }

  // ── App Bar ───────────────────────────────────────────────────
  Widget _buildAppBar(WorkerFeedController feedCtrl) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
      ),
      title: Text(
        AppStrings.appName,
        style: KTextStyle.poppins(fs: 20, fw: FontWeight.w600, c: Colors.white),
      ),
      centerTitle: true,
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => homeCtrl.changeTab(2),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '1',
                  textAlign: TextAlign.center,
                  style: KTextStyle.poppins(fs: 9, fw: FontWeight.bold, c: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Profile Card ──────────────────────────────────────────────
  Widget _buildProfileCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, 0),
        child: AppCard(
          child: Row(
            children: [
              Stack(
                children: [
                  AvatarCircle(initials: 'RK', size: AppDimens.avatarLg),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ramesh Kumar',
                      style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const SkillChip(label: 'Mason', selected: true),
                        const SizedBox(width: 8),
                        StatusBadge(type: BadgeType.verified),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SL-WRK-2024-004',
                      style: KTextStyle.poppins(fs: 10, c: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Active / No Job ───────────────────────────────────────────
  Widget _buildActiveJobSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.md, AppDimens.lg, 0),
        child: Obx(() => homeCtrl.hasActiveJob.value
            ? _ActiveJobCard(ctrl: homeCtrl)
            : const _NoJobCard()),
      ),
    );
  }

  // ── Skills ────────────────────────────────────────────────────
  Widget _buildSkillsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Your Skills'),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SkillChip(label: 'Mason',       selected: true),
                SkillChip(label: 'Tile Worker', selected: true),
                SkillChip(label: 'Helper',      selected: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Feed Header ───────────────────────────────────────────────
  Widget _buildFeedHeader(BuildContext context, WorkerFeedController feedCtrl) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.xl, AppDimens.lg, AppDimens.md),
        child: Row(
          children: [
            const _SectionHeader(title: 'Community Feed'),
            const Spacer(),
            GestureDetector(
              onTap: () => _showCreatePostSheet(context, feedCtrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Post',
                      style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600, c: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feed List ─────────────────────────────────────────────────
  Widget _buildFeedList(WorkerFeedController feedCtrl) {
    return Obx(() {
      if (feedCtrl.isLoading.value) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CustomCircularIndicator()),
          ),
        );
      }

      if (feedCtrl.posts.isEmpty) {
        return const SliverToBoxAdapter(child: _EmptyFeed());
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final post   = feedCtrl.posts[index];
            final isLast = index == feedCtrl.posts.length - 1;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.lg, 0, AppDimens.lg,
                isLast ? AppDimens.xl : AppDimens.md,
              ),
              child: _FeedPostCard(
                post: post,
                onLike: () => feedCtrl.toggleLike(post.id),
              ),
            );
          },
          childCount: feedCtrl.posts.length,
        ),
      );
    });
  }

  // ── Create Post Sheet ─────────────────────────────────────────
  void _showCreatePostSheet(BuildContext context, WorkerFeedController feedCtrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(feedCtrl: feedCtrl),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACTIVE JOB CARD
// ═══════════════════════════════════════════════════════════════════
class _ActiveJobCard extends StatelessWidget {
  final WorkerHomeController ctrl;
  const _ActiveJobCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showLeftBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Current Assignment',
                style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600, c: AppColors.primary),
              ),
              const Spacer(),
              StatusBadge(type: BadgeType.active),
            ],
          ),
          const SizedBox(height: 10),
          Text('Mason', style: KTextStyle.poppins(fs: 17, fw: FontWeight.bold)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          _DetailRow(icon: Icons.location_on_outlined,  text: 'Vaishali Nagar, Jaipur'),
          const SizedBox(height: 6),
          _DetailRow(icon: Icons.access_time_rounded,   text: '8:00 AM  ·  Start: 20 Mar 2026'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                const Icon(Icons.phone_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Rajesh Construction — Call Now',
                  style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500, c: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            label: AppStrings.markArrived,
            height: 44,
            onTap: () => Get.to(() => const ActiveJobView()),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NO JOB CARD
// ═══════════════════════════════════════════════════════════════════
class _NoJobCard extends StatelessWidget {
  const _NoJobCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.construction_rounded, size: 34, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.waitingForJob,
            style: KTextStyle.poppins(fs: 14, fw: FontWeight.w500, c: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.teamWillContact,
            style: KTextStyle.poppins(fs: 12, c: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FEED POST CARD
// ═══════════════════════════════════════════════════════════════════
class _FeedPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  const _FeedPostCard({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final isVendor = post.authorRole == 'vendor';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author ──────────────────────────────────────────
          Row(
            children: [
              AvatarCircle(initials: post.authorInitials, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVendor
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                          ),
                          child: Text(
                            isVendor ? 'Vendor' : 'Worker',
                            style: KTextStyle.poppins(
                              fs: 9,
                              fw: FontWeight.w600,
                              c: isVendor ? AppColors.primary : AppColors.info,
                            ),
                          ),
                        ),
                        if (post.authorSkill != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            post.authorSkill!,
                            style: KTextStyle.poppins(fs: 10, c: AppColors.textHint),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(post.createdAt),
                style: KTextStyle.poppins(fs: 10, c: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Content ─────────────────────────────────────────
          Text(
            post.description,
            style: KTextStyle.poppins(fs: 13, c: AppColors.textPrimary),
          ),

          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade400),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          // ── Actions ─────────────────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: post.isLikedByMe ? Colors.red.shade400 : AppColors.textHint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.likesCount}',
                      style: KTextStyle.poppins(
                        fs: 12,
                        fw: FontWeight.w500,
                        c: post.isLikedByMe ? Colors.red.shade400 : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

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

// ═══════════════════════════════════════════════════════════════════
//  CREATE POST SHEET
// ═══════════════════════════════════════════════════════════════════
class _CreatePostSheet extends StatelessWidget {
  final WorkerFeedController feedCtrl;
  const _CreatePostSheet({required this.feedCtrl});

  @override
  Widget build(BuildContext context) {
    final textCtrl = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('New Post', style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600)),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: textCtrl,
                    maxLines: 5,
                    minLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your work or requirements...',
                      hintStyle: KTextStyle.poppins(fs: 13, c: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: KTextStyle.poppins(fs: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Photo button
                    GestureDetector(
                      onTap: () {
                        // TODO: image_picker — feedCtrl.selectedImagePath.value = pickedPath
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Add Photo',
                              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500, c: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Obx(() => CustomButton(
                      label: 'Share',
                      height: 42,
                      width: 110,
                      isLoading: feedCtrl.isPosting.value,
                      onTap: () async {
                        await feedCtrl.submitPost(
                          description: textCtrl.text,
                          imagePath: feedCtrl.selectedImagePath.value,
                        );
                        if (context.mounted) Get.back();
                      },
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY FEED
// ═══════════════════════════════════════════════════════════════════
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.dynamic_feed_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text('No posts yet', style: KTextStyle.poppins(fs: 14, c: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS (private to this file)
// ═══════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        Text(title, style: KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Text(text, style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary)),
    ],
  );
}