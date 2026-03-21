import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════
//  RATE WORKER VIEW
// ═══════════════════════════════════════════════════════════════════
class RateWorkerView extends StatelessWidget {
  const RateWorkerView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(_RateCtrl());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.rateWorker),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Column(
                  children: [
                    // ── Worker Card ───────────────────────
                    AppCard(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              AvatarCircle(
                                  initials: 'RK',
                                  size: AppDimens.avatarXl),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white,
                                        width: 2),
                                  ),
                                  child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ramesh Kumar',
                            style: KTextStyle.poppins(
                                fs: 18, fw: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          SkillChip(
                              label: 'Mason / राजमिस्त्री',
                              selected: true),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMax),
                            ),
                            child: Text(
                              'Job: 20 Mar – 20 Apr 2026',
                              style: KTextStyle.poppins(
                                  fs: 11, c: AppColors.textHint),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── Rating Card ───────────────────────
                    AppCard(
                      child: Column(
                        children: [
                          Text(
                            AppStrings.rateExperience,
                            style: KTextStyle.poppins(
                                fs: 14,
                                fw: FontWeight.w600,
                                c: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'अपना अनुभव साझा करें',
                            style: KTextStyle.poppins(
                                fs: 12, c: AppColors.textHint),
                          ),
                          const SizedBox(height: AppDimens.lg),

                          // Stars
                          Obx(() => Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final filled =
                                  i < ctrl.rating.value;
                              return GestureDetector(
                                onTap: () =>
                                ctrl.rating.value = i + 1,
                                child: Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 5),
                                  child: Icon(
                                    filled
                                        ? Icons.star_rounded
                                        : Icons
                                        .star_outline_rounded,
                                    color: filled
                                        ? AppColors.secondary
                                        : AppColors.divider,
                                    size: 46,
                                  ),
                                ),
                              );
                            }),
                          )),
                          const SizedBox(height: 10),
                          Obx(() => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: ctrl.rating.value > 0
                                  ? AppColors.selectionBg
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMax),
                            ),
                            child: Text(
                              _ratingLabel(ctrl.rating.value),
                              style: KTextStyle.poppins(
                                fs: 13,
                                fw: FontWeight.w600,
                                c: ctrl.rating.value > 0
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                            ),
                          )),
                          const SizedBox(height: AppDimens.lg),

                          // Review text
                          TextFormField(
                            controller: ctrl.reviewCtrl,
                            maxLines: 4,
                            style: KTextStyle.poppins(fs: 13),
                            decoration: InputDecoration(
                              hintText:
                              'Share your experience... / अपना अनुभव लिखें...',
                              hintStyle: KTextStyle.poppins(
                                  fs: 12, c: AppColors.textHint),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── Average Rating Card ───────────────
                    AppCard(
                      child: Column(
                        children: [
                          Text(
                            "WORKER'S AVERAGE RATING",
                            style: KTextStyle.poppins(
                              fs: 10,
                              fw: FontWeight.bold,
                              c: AppColors.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.secondary,
                                  size: 36),
                              const SizedBox(width: 6),
                              Text(
                                '4.2',
                                style: KTextStyle.poppins(
                                    fs: 30, fw: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 4),
                                child: Text(
                                  '/ 5.0',
                                  style: KTextStyle.poppins(
                                      fs: 15,
                                      c: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Based on 18 ratings',
                            style: KTextStyle.poppins(
                                fs: 12, c: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.xl),
                  ],
                ),
              ),
            ),

            // ── Submit Button ──────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.md,
                AppDimens.lg,
                AppDimens.md +
                    MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.divider)),
              ),
              child: Obx(() => CustomButton(
                label: AppStrings.submitRating,
                onTap: ctrl.rating.value > 0
                    ? ctrl.submit
                    : null,
                isLoading: ctrl.isLoading.value,
              )),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor / खराब';
      case 2:
        return 'Fair / ठीक';
      case 3:
        return 'Good / अच्छा';
      case 4:
        return 'Very Good / बहुत अच्छा';
      case 5:
        return 'Excellent! / बहुत बढ़िया!';
      default:
        return 'Tap a star to rate';
    }
  }
}

// ── Controller ────────────────────────────────────────────────────
class _RateCtrl extends GetxController {
  final rating = 0.obs;
  final reviewCtrl = TextEditingController();
  final isLoading = false.obs;

  void submit() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
    Get.back();
    Get.snackbar(
      'Thank you! 🙏',
      'Rating submitted successfully.',
      backgroundColor: const Color(0xFFE8F5E9),
      colorText: const Color(0xFF2E7D32),
    );
  }

  @override
  void onClose() {
    reviewCtrl.dispose();
    super.onClose();
  }
}