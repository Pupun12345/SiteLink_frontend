import 'package:get/get.dart';
import '../../../../core/models/community_feed_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';
import 'worker_feed_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  COMMENTS CONTROLLER — ek post ke comments (CRUD)
// ═══════════════════════════════════════════════════════════════════
// Sheet khulte waqt per-post tag ke saath Get.put hota hai.
// Ownership: sirf apna comment hi edit/delete (userId == currentUserId).
class CommentsController extends GetxController {
  final String postId;
  final bool isJob; // true = job comments, false = community post
  CommentsController(this.postId, {this.isJob = false});

  late final _api = CommentsApiService(forJob: isJob);

  final comments  = <CommentModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  String get _currentUserId => SessionService.to.userId;

  /// Sirf apna comment? (edit/delete tabhi allowed)
  bool isMine(CommentModel c) =>
      _currentUserId.isNotEmpty && (c.userId ?? '') == _currentUserId;

  @override
  void onInit() {
    super.onInit();
    fetchComments();
  }

  Future<void> fetchComments() async {
    isLoading.value = true;
    try {
      final res = await _api.getComments(postId);
      if (res.success) comments.assignAll(res.data);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addComment(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    isSending.value = true;
    try {
      final res = await _api.addComment(postId, t);
      if (res.success) {
        await fetchComments();
        _bumpFeedCount(1);
      } else {
        AppSnackbar.error(message: res.message ?? 'comment_add_failed'.tr);
      }
    } finally {
      isSending.value = false;
    }
  }

  Future<void> updateComment(String commentId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    isSending.value = true;
    try {
      final res = await _api.updateComment(postId, commentId, t);
      if (res.success) {
        await fetchComments();
        AppSnackbar.success(message: 'comment_updated'.tr);
      } else {
        AppSnackbar.error(message: res.message ?? 'comment_update_failed'.tr);
      }
    } finally {
      isSending.value = false;
    }
  }

  Future<void> deleteComment(CommentModel c) async {
    if (!isMine(c) || c.id == null) return;
    // Optimistic remove
    final idx = comments.indexWhere((x) => x.id == c.id);
    if (idx != -1) comments.removeAt(idx);

    final res = await _api.deleteComment(postId, c.id!);
    if (res.success) {
      _bumpFeedCount(-1);
      AppSnackbar.success(message: 'comment_deleted'.tr);
    } else {
      if (idx != -1) comments.insert(idx, c); // revert
      AppSnackbar.error(message: res.message ?? 'comment_delete_failed'.tr);
    }
  }

  /// Feed card par commentsCount sync rakhta hai (sirf community posts).
  void _bumpFeedCount(int delta) {
    if (isJob) return; // job comments feed se linked nahi
    if (!Get.isRegistered<WorkerFeedController>()) return;
    final feed = Get.find<WorkerFeedController>();
    final idx = feed.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = feed.posts[idx];
    final next = (p.commentsCount ?? 0) + delta;
    p.commentsCount = next < 0 ? 0 : next;
    feed.posts.refresh();
  }
}
