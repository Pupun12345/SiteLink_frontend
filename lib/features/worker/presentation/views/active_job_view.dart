import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';

class ActiveJobView extends StatelessWidget {
  const ActiveJobView({super.key});

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = false.obs;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'My Assignment / मेरा काम'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.lg, AppDimens.md, AppDimens.lg, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.md, vertical: AppDimens.sm),
                decoration: BoxDecoration(
                  color: AppColors.selectionBg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Job Active / काम जारी है',
                      style: KTextStyle.poppins(
                        fs: 12,
                        fw: FontWeight.w600,
                        c: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Column(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _CardHeader(
                                icon: Icons.work_outline_rounded,
                                title: 'Current Assignment',
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.selectionBg,
                                  borderRadius:
                                  BorderRadius.circular(AppDimens.radiusMax),
                                ),
                                child: Text(
                                  'Active',
                                  style: KTextStyle.poppins(
                                    fs: 10,
                                    fw: FontWeight.w700,
                                    c: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.md),
                          Text(
                            'Mason',
                            style: KTextStyle.poppins(
                                fs: 16, fw: FontWeight.w700),
                          ),
                          const SizedBox(height: AppDimens.sm),
                          Text(
                            'Rajesh Construction',
                            style: KTextStyle.poppins(
                                fs: 12, c: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppDimens.md),
                          const _SectionDivider(),
                          const SizedBox(height: AppDimens.md),
                          Row(
                            children: const [
                              _InfoPill(
                                icon: Icons.calendar_today_rounded,
                                text: '20 Mar – 20 Apr',
                              ),
                              SizedBox(width: 10),
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
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardHeader(
                            icon: Icons.location_on_rounded,
                            title: 'Site Details / साइट विवरण',
                          ),
                          const SizedBox(height: AppDimens.md),
                          const _DetailRow(
                            icon: Icons.location_on_outlined,
                            text: 'Plot 45, Vaishali Nagar, Jaipur 302021',
                          ),
                          const SizedBox(height: AppDimens.lg),
                          const _DetailRow(
                            icon: Icons.access_time_rounded,
                            text: 'Reporting Time: 8:00 AM daily',
                          ),
                          const SizedBox(height: AppDimens.lg),
                          InkWell(
                            onTap: () {},
                            borderRadius:
                            BorderRadius.circular(AppDimens.radiusSm),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                BorderRadius.circular(AppDimens.radiusSm),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.map_outlined,
                                      color: AppColors.primary, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'View on Map / मानचित्र',
                                    style: KTextStyle.poppins(
                                      fs: 12,
                                      fw: FontWeight.w600,
                                      c: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),
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
                                          fs: 14, fw: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rajesh Construction',
                                      style: KTextStyle.poppins(
                                          fs: 11,
                                          c: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+91 98765 43210',
                                      style: KTextStyle.poppins(
                                          fs: 11,
                                          c: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.lg),
                          CustomButton(
                            label: 'Call Now',
                            height: 44,
                            isOutlined: true,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          child: Icon(icon, color: AppColors.textPrimary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: KTextStyle.poppins(
            fs: 13,
            fw: FontWeight.w600,
            c: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  const _InfoPill({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.selectionBg : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMax),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: KTextStyle.poppins(
              fs: 11,
              fw: FontWeight.w600,
              c: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
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
      const Divider(color: AppColors.divider, height: 1);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimens.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: KTextStyle.poppins(
                fs: 12, c: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );}