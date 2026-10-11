import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/community_feed_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import 'my_post_card.dart';

// ═══════════════════════════════════════════════════════════════════
//  MY POSTS — dedicated page (worker + vendor dono use karte hain)
// ═══════════════════════════════════════════════════════════════════
// Pehle company/worker profile screen ke andar hi ek inline section tha —
// ab apna alag page hai, profile screen se sirf ek tile/tap se yahan aate
// hain. Data source (posts/isLoading/refresh/delete) caller se aata hai,
// taaki vendor aur worker apne-apne controller (VendorProfileController /
// WorkerProfileController) ke saath bina duplicate UI likhe reuse ho sake.
class MyPostsView extends StatelessWidget {
  final RxList<CommunityFeedModel> posts;
  final RxBool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(String postId) onDelete;

  const MyPostsView({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'my_posts_label'.tr),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (isLoading.value && posts.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                  Column(children: [
                    Icon(Icons.post_add_outlined,
                        size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 14),
                    Text('no_posts_yet'.tr,
                        style: KTextStyle.poppins(
                            fs: 15, fw: FontWeight.w600, c: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('share_something_home_feed_hint'.tr,
                        style: KTextStyle.poppins(fs: 12, c: AppColors.textHint)),
                  ]),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimens.lg),
              itemCount: posts.length,
              itemBuilder: (_, i) => Padding(
                padding: EdgeInsets.only(
                    bottom: i == posts.length - 1 ? 0 : AppDimens.md),
                child: MyPostCard(
                  post: posts[i],
                  onDelete: () => _confirmDelete(context, posts[i].id),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String? postId) {
    if (postId == null) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('delete_post_confirm_title'.tr,
            style: KTextStyle.poppins(fs: 15, fw: FontWeight.w600)),
        content: Text(
            'delete_post_confirm_body'.tr,
            style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel_label'.tr,
                style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onDelete(postId);
            },
            child: Text('delete_label'.tr,
                style: KTextStyle.poppins(
                    fs: 13, fw: FontWeight.w600, c: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }
}
