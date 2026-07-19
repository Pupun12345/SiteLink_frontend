import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/community_feed_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  MY POST CARD — "My Posts" (profile screens) ke liye shared widget
// ═══════════════════════════════════════════════════════════════════
// Worker aur vendor dono ka profile isi card se apne CommunityFeedModel
// posts dikhate hain (same /api/community feed, dono role post kar
// sakte hain) — isliye ek jagah, do jagah copy-paste nahi.
class MyPostCard extends StatelessWidget {
  final CommunityFeedModel post;
  final VoidCallback onDelete;

  const MyPostCard({
    super.key,
    required this.post,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = post.images != null && post.images!.isNotEmpty;
    final hasVideo = post.video != null && post.video!.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Poster row: avatar + name/feeling + status + delete ─
          Row(children: [
            AvatarCircle(
              initials: _initials(post.posterName ?? ''),
              imageUrl: post.posterImage,
              size: 34,
              fontSize: 12,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.posterName ?? 'You',
                    style: KTextStyle.poppins(fs: 12.5, fw: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post.feeling != null && post.feeling!.isNotEmpty)
                    Text('😊 Feeling ${post.feeling}',
                        style: KTextStyle.poppins(
                            fs: 10, c: AppColors.textHint)),
                ],
              ),
            ),
            PostApprovalChip(status: post.approvalStatus ?? post.verification),
            const SizedBox(width: 6),
            // Delete button
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.delete_outline_rounded,
                    size: 16, color: Colors.red.shade400),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // ── Content text ─────────────────────────────────────
          if (post.content != null && post.content!.isNotEmpty)
            Text(
              post.content!,
              style: KTextStyle.poppins(fs: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

          // ── First image preview ───────────────────────────────
          if (hasImage) ...[
            const SizedBox(height: 8),
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: Image.network(
                  WorkerFeedController.fullUrl(post.images!.first),
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd)),
                    child: Icon(Icons.image_outlined,
                        color: Colors.grey.shade400, size: 32),
                  ),
                ),
              ),
              // "+N more" badge for multiple images
              if (post.images!.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '+${post.images!.length - 1} more',
                      style: KTextStyle.poppins(fs: 10, c: Colors.white),
                    ),
                  ),
                ),
            ]),
          ],

          // ── Video badge ───────────────────────────────────────
          if (hasVideo && !hasImage) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text('Video',
                      style: KTextStyle.poppins(fs: 12, c: Colors.white)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Container(height: 0.5, color: AppColors.divider),
          const SizedBox(height: 8),

          // ── Stats row ─────────────────────────────────────────
          Row(children: [
            Icon(
                (post.likesCount ?? 0) > 0
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 14,
                color: (post.likesCount ?? 0) > 0
                    ? AppColors.primary
                    : AppColors.textHint),
            const SizedBox(width: 4),
            Text('${post.likesCount ?? 0}',
                style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
            const SizedBox(width: 12),
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('${post.commentsCount ?? 0}',
                style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
            const Spacer(),
            Text(_timeAgo(post.createdAt ?? DateTime.now()),
                style: KTextStyle.poppins(fs: 10, c: AppColors.textHint)),
          ]),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APPROVAL / VERIFICATION STATUS CHIP  (post ka actual status)
// ═══════════════════════════════════════════════════════════════════
class PostApprovalChip extends StatelessWidget {
  final String? status; // 'approved'|'verified' | 'rejected' | 'pending'
  const PostApprovalChip({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    final s = (status ?? 'pending').toLowerCase();
    final isApproved = s == 'approved' || s == 'verified';
    final isRejected = s == 'rejected';
    final color = isApproved
        ? AppColors.success
        : (isRejected ? AppColors.error : Colors.amber.shade700);
    final label =
        isApproved ? 'Approved' : (isRejected ? 'Rejected' : 'Pending');
    final icon = isApproved
        ? Icons.check_circle_rounded
        : (isRejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style:
                  KTextStyle.poppins(fs: 9.5, fw: FontWeight.w600, c: color)),
        ],
      ),
    );
  }
}
