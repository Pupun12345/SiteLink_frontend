import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/community_feed_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/comments_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  COMMENTS SHEET — ek post ke comments dekho / add / edit / delete
// ═══════════════════════════════════════════════════════════════════
class CommentsSheet extends StatelessWidget {
  final String postId;
  final bool isJob;
  const CommentsSheet({super.key, required this.postId, this.isJob = false});

  /// Sheet kholo (controller put + close pe cleanup).
  /// [isJob] = job comments (/jobs/:id/comments) — edit/delete hidden.
  static Future<void> open(
    BuildContext context,
    String postId, {
    bool isJob = false,
  }) async {
    if (postId.isEmpty) return;
    Get.put(CommentsController(postId, isJob: isJob), tag: postId);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => CommentsSheet(postId: postId, isJob: isJob),
    );
    await Get.delete<CommentsController>(tag: postId);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CommentsController>(tag: postId);
    final media = MediaQuery.of(context);
    // Sheet ki max height — keyboard + status bar chhodkar (overflow se bachao)
    final maxSheetH =
        media.size.height - media.viewInsets.bottom - media.padding.top - 12;

    return Padding(
      // keyboard ke upar uthane ke liye
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetH),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 8),
              child: Row(
                children: [
                  // Ginti me replies bhi — feed card wali ginti se match kare.
                  Obx(
                    () => Text(
                      ctrl.comments.isEmpty
                          ? 'comments_title'.tr
                          : 'comments_title_count'.trParams({
                              'count': '${ctrl.totalCount}',
                            }),
                      style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: Get.back,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // List — Flexible: keyboard khulne par shrink ho (no overflow)
            Flexible(
              child: Obx(() {
                if (ctrl.isLoading.value && ctrl.comments.isEmpty) {
                  return const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                if (ctrl.comments.isEmpty) {
                  return const _EmptyComments();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: ctrl.comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (_, i) {
                    final c = ctrl.comments[i];
                    final open = ctrl.expanded.contains(c.id);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CommentTile(
                          comment: c,
                          // Job comments me edit/delete API nahi — menu hide
                          isMine: !isJob && ctrl.isMine(c),
                          onEdit: () => _editDialog(ctrl, c),
                          onDelete: () => _deleteConfirm(ctrl, c),
                          onReply: ctrl.canReply
                              ? () => ctrl.startReply(c)
                              : null,
                        ),
                        // ── Replies: "N replies dekhein" → andar khiske hue ──
                        if (c.replies.isNotEmpty)
                          _RepliesToggle(
                            count: c.replies.length,
                            open: open,
                            onTap: () => ctrl.toggleReplies(c.id ?? ''),
                          ),
                        if (open)
                          for (final r in c.replies)
                            _CommentTile(
                              comment: r,
                              isReply: true,
                              isMine: !isJob && ctrl.isMine(r),
                              onEdit: () => _editDialog(ctrl, r),
                              onDelete: () => _deleteConfirm(ctrl, r),
                              // Reply ka reply bhi isi thread me jaata hai
                              onReply: ctrl.canReply
                                  ? () => ctrl.startReply(r, thread: c)
                                  : null,
                            ),
                      ],
                    );
                  },
                );
              }),
            ),

            const Divider(height: 1, color: AppColors.divider),
            // Composer
            _CommentComposer(ctrl: ctrl),
          ],
        ),
      ),
    );
  }

  // ── Edit dialog (sirf apna comment) ───────────────────────────────
  void _editDialog(CommentsController ctrl, CommentModel c) {
    final editCtrl = TextEditingController(text: c.comment ?? '');
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'edit_comment_title'.tr,
          style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700),
        ),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          style: KTextStyle.poppins(fs: 14, c: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'update_comment_hint'.tr,
            hintStyle: KTextStyle.poppins(fs: 13, c: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel_label'.tr)),
          TextButton(
            onPressed: () {
              final t = editCtrl.text.trim();
              if (t.isEmpty || c.id == null) return;
              Get.back();
              ctrl.updateComment(c.id!, t);
            },
            child: Text(
              'save_label'.tr,
              style: KTextStyle.poppins(
                fs: 13,
                fw: FontWeight.w600,
                c: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete confirm (sirf apna comment) ────────────────────────────
  void _deleteConfirm(CommentsController ctrl, CommentModel c) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'delete_comment_title'.tr,
          style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700),
        ),
        content: Text(
          'delete_comment_body'.tr,
          style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel_label'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.deleteComment(c);
            },
            child: Text(
              'delete_label'.tr,
              style: KTextStyle.poppins(
                fs: 13,
                fw: FontWeight.w600,
                c: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COMMENT TILE
// ═══════════════════════════════════════════════════════════════════
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// null = reply ka option nahi (job comments).
  final VoidCallback? onReply;

  /// Reply hai to andar khiska hua aur chhota dikhta hai.
  final bool isReply;

  const _CommentTile({
    required this.comment,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = (comment.userName ?? '').trim().isEmpty
        ? 'default_user_name'.tr
        : comment.userName!.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isReply ? 62 : 16,
        isReply ? 4 : 8,
        8,
        isReply ? 4 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarCircle(
            initials: _initials(name),
            size: isReply ? 28 : 36,
            fontSize: isReply ? 11 : 13,
          ),
          SizedBox(width: isReply ? 8 : 10),
          // Bubble + "Reply" button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: KTextStyle.poppins(
                                fs: 12.5,
                                fw: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Admin ka comment/reply — saaf pehchaan
                          if (comment.isAdmin) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'admin_badge_label'.tr,
                                style: KTextStyle.poppins(
                                  fs: 9.5,
                                  fw: FontWeight.w600,
                                  c: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                          if (comment.createdAt != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· ${_timeAgo(comment.createdAt!)}',
                              style: KTextStyle.poppins(
                                fs: 10,
                                c: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        comment.comment ?? '',
                        style: KTextStyle.poppins(
                          fs: 13,
                          c: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onReply != null)
                  GestureDetector(
                    onTap: onReply,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 5, 12, 2),
                      child: Text(
                        'reply_label'.tr,
                        style: KTextStyle.poppins(
                          fs: 11.5,
                          fw: FontWeight.w600,
                          c: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Sirf apne comment pe edit/delete
          if (isMine)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text('edit_label'.tr, style: KTextStyle.poppins(fs: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'delete_label'.tr,
                        style: KTextStyle.poppins(fs: 13, c: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── "N replies dekhein" / "Replies chhupayein" ──────────────────────
class _RepliesToggle extends StatelessWidget {
  final int count;
  final bool open;
  final VoidCallback onTap;
  const _RepliesToggle({
    required this.count,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = open
        ? 'hide_replies'.tr
        : (count == 1
              ? 'view_one_reply'.tr
              : 'view_replies'.trParams({'count': '$count'}));
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(62, 2, 16, 6),
        child: Row(
          children: [
            Container(width: 22, height: 1, color: AppColors.divider),
            const SizedBox(width: 8),
            Text(
              label,
              style: KTextStyle.poppins(
                fs: 12,
                fw: FontWeight.w600,
                c: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COMPOSER (add comment)
// ═══════════════════════════════════════════════════════════════════
class _CommentComposer extends StatefulWidget {
  final CommentsController ctrl;
  const _CommentComposer({required this.ctrl});

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _textCtrl = TextEditingController();
  final _focus = FocusNode();
  Worker? _replyWorker;

  @override
  void initState() {
    super.initState();
    // "Reply" dabate hi keyboard khule — user seedha likhe.
    _replyWorker = ever<CommentModel?>(widget.ctrl.replyingTo, (c) {
      if (c != null) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _replyWorker?.dispose();
    _textCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) return;
    widget.ctrl.addComment(t);
    _textCtrl.clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── "Replying to X" patti — ✕ se wapas naya comment ──
          Obx(() {
            if (widget.ctrl.replyingTo.value == null)
              return const SizedBox.shrink();
            final who = (widget.ctrl.replyToName.value ?? '').trim();
            return Container(
              width: double.infinity,
              color: AppColors.scaffoldBg,
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'replying_to'.trParams({
                        'name': who.isEmpty ? 'default_user_name'.tr : who,
                      }),
                      style: KTextStyle.poppins(
                        fs: 12,
                        c: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: widget.ctrl.cancelReply,
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => TextField(
                      controller: _textCtrl,
                      focusNode: _focus,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      minLines: 1,
                      maxLines: 4,
                      style: KTextStyle.poppins(
                        fs: 14,
                        c: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.ctrl.replyingTo.value != null
                            ? 'add_reply_hint'.tr
                            : 'add_comment_hint'.tr,
                        hintStyle: KTextStyle.poppins(
                          fs: 13,
                          c: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: AppColors.scaffoldBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMax,
                          ),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMax,
                          ),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMax,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => GestureDetector(
                    onTap: widget.ctrl.isSending.value ? null : _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: widget.ctrl.isSending.value
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════════
class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 38,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'no_comments_yet'.tr,
            style: KTextStyle.poppins(
              fs: 14,
              fw: FontWeight.w500,
              c: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'be_first_to_comment'.tr,
            style: KTextStyle.poppins(fs: 12, c: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────
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

String _timeAgo(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inSeconds < 60) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${(d.inDays / 7).floor()}w';
}
