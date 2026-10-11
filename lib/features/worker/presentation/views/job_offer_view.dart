import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../app/routes/app_routes.dart';

// ═══════════════════════════════════════════════════════════════════
//  JOB OFFER VIEW — Screen 23
// ═══════════════════════════════════════════════════════════════════
class JobOfferView extends StatelessWidget {
  const JobOfferView({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppDimens.radiusXxl),
                bottomRight: Radius.circular(AppDimens.radiusXxl),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
                AppDimens.lg, topPad + 20, AppDimens.lg, 44),
            child: Column(
              children: [
                // Back button row
                Row(
                  children: [
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius:
                      BorderRadius.circular(AppDimens.radiusMax),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius:
                    BorderRadius.circular(AppDimens.radiusMax),
                  ),
                  child: Text(
                    'new_offer_badge'.tr,
                    style: KTextStyle.poppins(
                        fs: 11, fw: FontWeight.w600, c: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.NewJobOffer,
                  style: KTextStyle.poppins(
                      fs: 22, fw: FontWeight.bold, c: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'offer_review_subtitle'.tr,
                  style: KTextStyle.poppins(
                      fs: 12, c: Colors.white.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Overlapping card
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.lg),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Role chip ─────────────────────
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: AppColors.appBarGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radiusMax),
                                ),
                                child: Text(
                                  '🔨  Mason / राजमिस्त्री',
                                  style: KTextStyle.poppins(
                                      fs: 15,
                                      fw: FontWeight.w600,
                                      c: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimens.lg),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: AppDimens.md),

                            // ── Details grid ─────────────────
                            _DetailGrid(items: [
                              (Icons.location_on_outlined, 'location_label'.tr,
                              'Vaishali Nagar, Jaipur'),
                              (Icons.calendar_today_rounded, AppStrings.StartDate,
                              '20 March 2026'),
                              (Icons.timelapse_rounded, AppStrings.Duration,
                              '1 Month'),
                              (Icons.currency_rupee_rounded, 'daily_rate_label'.tr,
                              '₹650 / day'),
                            ]),
                            const SizedBox(height: AppDimens.md),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: AppDimens.md),

                            // ── Company row ──────────────────
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.selectionBg,
                                    borderRadius: BorderRadius.circular(
                                        AppDimens.radiusMd),
                                  ),
                                  child: const Icon(
                                      Icons.business_rounded,
                                      color: AppColors.primary,
                                      size: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rajesh Construction',
                                        style: KTextStyle.poppins(
                                            fs: 14, fw: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'verified_contractor_label'.tr,
                                        style: KTextStyle.poppins(
                                            fs: 11, c: AppColors.success),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppDimens.radiusSm),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: AppColors.secondary,
                                          size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        '4.5',
                                        style: KTextStyle.poppins(
                                            fs: 12, fw: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.md),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: AppDimens.md),

                            // ── Special note ─────────────────
                            Container(
                              padding: const EdgeInsets.all(AppDimens.md),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                border: Border.all(
                                    color: AppColors.divider),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 15, color: AppColors.textHint),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Night shift available. Tools will be provided on site.',
                                      style: KTextStyle.poppins(
                                          fs: 12,
                                          c: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimens.md),

                            // ── Timer ────────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.selectionBg,
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                border: Border.all(
                                    color:
                                    AppColors.primary.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AppStrings.PleaseRespondWithin2Hours,
                                      style: KTextStyle.poppins(
                                          fs: 12,
                                          fw: FontWeight.w500,
                                          c: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ─────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppDimens.lg,
              AppDimens.md,
              AppDimens.lg,
              AppDimens.md + bottomPad,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: AppStrings.Decline,
                    isOutlined: true,
                    onTap: () => Get.back(),
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: CustomButton(
                    label: AppStrings.Accept,
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.activeJob);
                    },
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

// ── Detail Grid ───────────────────────────────────────────────────
class _DetailGrid extends StatelessWidget {
  final List<(IconData, String, String)> items;
  const _DetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: items
          .map((item) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius:
          BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.selectionBg,
                borderRadius:
                BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(item.$1,
                  color: AppColors.primary, size: 15),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.$2,
                      style: KTextStyle.poppins(
                          fs: 9, c: AppColors.textHint)),
                  Text(
                    item.$3,
                    style: KTextStyle.poppins(
                        fs: 11, fw: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }
}