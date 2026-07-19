import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  REPLACEMENT REQUEST VIEW
// ═══════════════════════════════════════════════════════════════════
class ReplacementRequestView extends StatelessWidget {
  const ReplacementRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(_ReplacementCtrl());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.RequestReplacement),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── SLA Banner ────────────────────────
                    InfoBanner(
                      text: AppStrings.ReplacementGuaranteedWithin48Hours,
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── Worker Info ───────────────────────
                    AppCard(
                      child: Row(
                        children: [
                          AvatarCircle(initials: 'RK', size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ramesh Kumar',
                                  style: KTextStyle.poppins(
                                      fs: 14,
                                      fw: FontWeight.w600),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    SkillChip(
                                        label: 'Mason',
                                        selected: true),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Assigned: 20 Mar',
                                      style: KTextStyle.poppins(
                                          fs: 11,
                                          c: AppColors.textHint),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── Reason Selection ──────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.selectionBg,
                                  borderRadius:
                                  BorderRadius.circular(
                                      AppDimens.radiusSm),
                                ),
                                child: const Icon(
                                    Icons.report_gmailerrorred_rounded,
                                    color: AppColors.primary,
                                    size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.ReasonForReplacement,
                                style: KTextStyle.poppins(
                                    fs: 14, fw: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.md),
                          Obx(() => Column(
                            children: AppStrings
                                .replacementReasons
                                .map((reason) {
                              final sel = ctrl
                                  .selectedReason.value ==
                                  reason;
                              return GestureDetector(
                                onTap: () => ctrl
                                    .selectedReason.value =
                                    reason,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 8),
                                  padding: const EdgeInsets.all(
                                      AppDimens.md),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.selectionBg
                                        : AppColors.surface,
                                    borderRadius:
                                    BorderRadius.circular(
                                        AppDimens.radiusMd),
                                    border: Border.all(
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: sel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style:
                                          KTextStyle.poppins(
                                            fs: 13,
                                            fw: sel
                                                ? FontWeight.w500
                                                : FontWeight
                                                .normal,
                                            c: sel
                                                ? AppColors
                                                .primary
                                                : AppColors
                                                .textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: sel
                                                ? AppColors
                                                .primary
                                                : AppColors.border,
                                            width: 2,
                                          ),
                                        ),
                                        child: sel
                                            ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration:
                                            const BoxDecoration(
                                              color: AppColors
                                                  .primary,
                                              shape: BoxShape
                                                  .circle,
                                            ),
                                          ),
                                        )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Description ───────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.selectionBg,
                                  borderRadius:
                                  BorderRadius.circular(
                                      AppDimens.radiusSm),
                                ),
                                child: const Icon(
                                    Icons.edit_note_rounded,
                                    color: AppColors.primary,
                                    size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.Description,
                                style: KTextStyle.poppins(
                                    fs: 14, fw: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.md),
                          TextFormField(
                            controller: ctrl.descCtrl,
                            maxLines: 4,
                            style: KTextStyle.poppins(fs: 13),
                            decoration: InputDecoration(
                              hintText:
                              'Describe the issue... / समस्या बताएं...',
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
                              contentPadding:
                              const EdgeInsets.all(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Photo Proof ───────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.selectionBg,
                                  borderRadius:
                                  BorderRadius.circular(
                                      AppDimens.radiusSm),
                                ),
                                child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.primary,
                                    size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add Photo Proof / फोटो जोड़ें',
                                style: KTextStyle.poppins(
                                    fs: 14, fw: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radiusMax),
                                ),
                                child: Text(
                                  'Optional',
                                  style: KTextStyle.poppins(
                                      fs: 10,
                                      c: AppColors.textHint),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.md),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(0.03),
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusLg),
                                border: Border.all(
                                  color: AppColors.primary
                                      .withOpacity(0.35),
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.selectionBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.camera_alt_outlined,
                                        color: AppColors.primary,
                                        size: 20),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Take photo or upload',
                                    style: KTextStyle.poppins(
                                        fs: 12,
                                        c: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Warning box ───────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppDimens.md),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd),
                        border:
                        Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.amber.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your 48-hour replacement clock starts when you submit this form.',
                              style: KTextStyle.poppins(
                                  fs: 12,
                                  c: Colors.amber.shade800),
                            ),
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
                label: AppStrings.SubmitRequest,
                onTap: ctrl.submit,
                isLoading: ctrl.isLoading.value,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Controller ────────────────────────────────────────────────────
class _ReplacementCtrl extends GetxController {
  final selectedReason = ''.obs;
  final descCtrl = TextEditingController();
  final isLoading = false.obs;

  void submit() async {
    if (selectedReason.isEmpty) {
      AppSnackbar.error(message: 'Please select a reason');
      return;
    }
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
    Get.back();
    AppSnackbar.success(
      message: 'Replacement request received. We will respond within 48 hours.',
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    descCtrl.dispose();
    super.onClose();
  }
}