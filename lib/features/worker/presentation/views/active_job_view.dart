import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════
//  ACTIVE JOB VIEW — Screen 21
// ═══════════════════════════════════════════════════════════════════
class ActiveJobView extends StatelessWidget {
  const ActiveJobView({super.key});

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = false.obs;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'My Assignment / मेरा काम'),
      body: SafeArea(
        top: false, // AppBar already handles top
        child: Column(
          children: [
            // ── Status banner ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                border: Border(
                  bottom: BorderSide(color: AppColors.success.withOpacity(0.2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 8, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Job Active / काम जारी है',
                    textAlign: TextAlign.center,
                    style: KTextStyle.poppins(
                        fs: 13, fw: FontWeight.w600, c: AppColors.success),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Column(
                  children: [
                    // ── Assignment summary ──────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SkillChip(label: 'Mason / राजमिस्त्री', selected: true),
                              const Spacer(),
                              StatusBadge(type: BadgeType.active),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Rajesh Construction',
                            style: KTextStyle.poppins(fs: 17, fw: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          const _SectionDivider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _InfoPill(
                                icon: Icons.calendar_today_rounded,
                                text: '20 Mar – 20 Apr',
                              ),
                              const SizedBox(width: 10),
                              _InfoPill(
                                icon: Icons.currency_rupee_rounded,
                                text: '₹650 / day',
                                highlight: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Site details ──────────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardHeader(
                            icon: Icons.location_on_rounded,
                            title: 'Site Details / साइट विवरण',
                          ),
                          const SizedBox(height: AppDimens.md),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            text: 'Plot 45, Vaishali Nagar, Jaipur 302021',
                          ),
                          const SizedBox(height: 10),
                          _DetailRow(
                            icon: Icons.access_time_rounded,
                            text: 'Reporting Time: 8:00 AM daily',
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () {},
                            borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.selectionBg,
                                borderRadius:
                                BorderRadius.circular(AppDimens.radiusSm),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map_outlined,
                                      color: AppColors.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'View on Map / मानचित्र',
                                    style: KTextStyle.poppins(
                                        fs: 13,
                                        fw: FontWeight.w500,
                                        c: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Vendor contact ────────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardHeader(
                            icon: Icons.business_center_rounded,
                            title: 'Vendor Contact / ठेकेदार संपर्क',
                          ),
                          const SizedBox(height: AppDimens.md),
                          Row(
                            children: [
                              AvatarCircle(initials: 'RS', size: 48),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rajesh Sharma',
                                      style: KTextStyle.poppins(
                                          fs: 15, fw: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Rajesh Construction',
                                      style: KTextStyle.poppins(
                                          fs: 12, c: AppColors.textHint),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '+91 98765 43210',
                                      style: KTextStyle.poppins(
                                          fs: 12, c: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          CustomButton(
                            label: '📞  Call Now / अभी कॉल करें',
                            height: 44,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Attendance ────────────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardHeader(
                            icon: Icons.how_to_reg_rounded,
                            title: "Today's Attendance / आज की उपस्थिति",
                          ),
                          const SizedBox(height: AppDimens.md),
                          Obx(() => isCheckedIn.value
                              ? Container(
                            padding: const EdgeInsets.all(AppDimens.md),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd),
                              border: Border.all(
                                  color:
                                  AppColors.success.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Arrived at 8:05 AM ✅',
                                  style: KTextStyle.poppins(
                                      fs: 13,
                                      fw: FontWeight.w600,
                                      c: AppColors.success),
                                ),
                              ],
                            ),
                          )
                              : CustomButton(
                            label: AppStrings.markArrived,
                            onTap: () {
                              isCheckedIn.value = true;
                              Get.to(() => const CheckInConfirmView());
                            },
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.xl),
                  ],
                ),
              ),
            ),

            // ── Bottom action ─────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.md,
                AppDimens.lg,
                AppDimens.md + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: CustomButton(
                label: '⚠️  Report Issue / समस्या बताएं',
                isOutlined: true,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.selectionBg,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: KTextStyle.poppins(
              fs: 14, fw: FontWeight.w600, c: AppColors.primary),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  const _InfoPill(
      {required this.icon, required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? AppColors.successLight : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: highlight ? AppColors.success : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: KTextStyle.poppins(
                fs: 12,
                fw: FontWeight.w600,
                c: highlight ? AppColors.success : AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.divider);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style:
          KTextStyle.poppins(fs: 13, c: AppColors.textPrimary),
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
//  CHECK-IN CONFIRMATION — Screen 22
// ═══════════════════════════════════════════════════════════════════
class CheckInConfirmView extends StatelessWidget {
  const CheckInConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'Check-in / उपस्थिति'),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Success icon ────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 56),
              ),
              const SizedBox(height: 20),

              Text(
                'Arrived at Site!',
                style:
                KTextStyle.poppins(fs: 22, fw: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'पहुँच गए! 🎉',
                style: KTextStyle.poppins(
                    fs: 16, fw: FontWeight.w500, c: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Your attendance has been recorded.\nआपकी उपस्थिति दर्ज कर ली गई है।',
                style: KTextStyle.poppins(fs: 13, c: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // ── Timestamp card ───────────────────────────────
              AppCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.selectionBg,
                        borderRadius:
                        BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_filled_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checked in at 8:05 AM',
                                style: KTextStyle.poppins(
                                    fs: 15, fw: FontWeight.w600),
                              ),
                              Text(
                                '20 March 2026',
                                style: KTextStyle.poppins(
                                    fs: 11, c: AppColors.textHint),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius:
                        BorderRadius.circular(AppDimens.radiusMax),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Job Started ✅',
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w600,
                            c: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              CustomButton(
                label: 'Back to Home / होम पर जाएं',
                onTap: () => Get.until((r) => r.isFirst),
              ),
              const SizedBox(height: AppDimens.lg),
            ],
          ),
        ),
      ),
    );
  }
}