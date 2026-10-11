import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/community_feed_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../worker/presentation/views/comments_sheet.dart';
import '../../../worker/presentation/views/worker_home_tab.dart';

// ═══════════════════════════════════════════════════════════════════
//  POST DETAIL — shared deep link (`/p/<id>`) yahan khulta hai
// ═══════════════════════════════════════════════════════════════════
// Feed wala hi `FeedPostCard` reuse karta hai taaki shared post bilkul
// waisa hi dikhe jaisa feed me dikhta — alag design banane se dono me
// farq aa jaata.
class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final postId = (Get.arguments as String?) ?? '';
    final ctrl = Get.put(PostDetailController(postId), tag: postId);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'post_label'.tr),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final post = ctrl.post.value;
        if (post == null) return _NotFound(message: ctrl.error.value);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeedPostCard(
                post: post,
                isLikedByMe: ctrl.isLiked,
                onLike: ctrl.toggleLike,
              ),
              const SizedBox(height: AppDimens.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.lg, vertical: AppDimens.sm),
                child: CustomButton(
                  label: 'view_comments_label'.tr,
                  isOutlined: true,
                  onTap: () => CommentsSheet.open(context, post.id ?? ''),
                ),
              ),
              const SizedBox(height: AppDimens.xl),
            ],
          ),
        );
      }),
    );
  }
}

class _NotFound extends StatelessWidget {
  final String? message;
  const _NotFound({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimens.md),
            Text(
              (message?.trim().isNotEmpty ?? false)
                  ? message!.trim()
                  : 'post_not_found'.tr,
              textAlign: TextAlign.center,
              style: KTextStyle.poppins(fs: 14, c: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.lg),
            CustomButton(label: 'go_back_label'.tr, onTap: Get.back),
          ],
        ),
      ),
    );
  }
}

// ── Controller ────────────────────────────────────────────────────
class PostDetailController extends GetxController {
  final String postId;
  PostDetailController(this.postId);

  final _api = CommunityApiService();

  final post = Rxn<CommunityFeedModel>();
  final isLoading = true.obs;
  final error = RxnString();

  String get _myId => SessionService.to.userId;

  /// Feed ki tarah likes list se derive hota hai — alag bool rakhne se
  /// load par galat state dikhti (already-liked post bhi khaali dil).
  bool get isLiked =>
      (post.value?.likes ?? const []).any((l) => l.userId == _myId);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    if (postId.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    final (fetched, message) = await _api.getPostById(postId);
    post.value = fetched;
    error.value = message;
    isLoading.value = false;
  }

  /// Optimistic — server ka jawab aane se pehle hi dil bhar jaata hai,
  /// fail hone par sab kuch wapas.
  Future<void> toggleLike() async {
    final p = post.value;
    final id = p?.id;
    if (p == null || id == null) return;

    final was = isLiked;
    final prevCount = p.likesCount ?? 0;
    final prevLikes = List<Like>.from(p.likes ?? const []);

    p.likesCount = was ? prevCount - 1 : prevCount + 1;
    p.likes = was
        ? prevLikes.where((l) => l.userId != _myId).toList()
        : [...prevLikes, Like(userId: _myId, userName: SessionService.to.userName)];
    post.refresh();

    final res = await _api.toggleLike(id);
    if (!res.ok) {
      p.likesCount = prevCount;
      p.likes = prevLikes;
    } else if (res.count != null) {
      p.likesCount = res.count;
    }
    post.refresh();
  }
}
