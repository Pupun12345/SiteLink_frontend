import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import 'replacement_request_view.dart';
import 'rate_worker_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  REQUEST DETAIL VIEW
// ═══════════════════════════════════════════════════════════════════
class RequestDetailView extends StatelessWidget {
  final Map<String, dynamic> request;
  const RequestDetailView({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: AppStrings.requestDetails,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Status Banner ────────────────────────────
            _StatusBanner(status: status),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Column(
                  children: [
                    // ── Request Summary ───────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#REQ-2024-001',
                                style: KTextStyle.poppins(
                                    fs: 11, c: AppColors.textHint),
                              ),
                              const Spacer(),
                              StatusBadge(
                                type: status == 'active'
                                    ? BadgeType.active
                                    : BadgeType.pending,
                                customLabel: status == 'active'
                                    ? 'Active'
                                    : 'Pending',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mason × 5  |  Carpenter × 3',
                            style: KTextStyle.poppins(
                                fs: 17, fw: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Divider(
                              height: 1,
                              color: AppColors.divider),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            text: 'Vaishali Nagar, Jaipur',
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            text:
                            '20 Mar – 20 Apr 2026  ·  1 Month',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Status Timeline ───────────────────
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
                                    Icons.timeline_rounded,
                                    color: AppColors.primary,
                                    size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.statusTimeline,
                                style: KTextStyle.poppins(
                                    fs: 14, fw: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.lg),
                          const _TimelineStep(
                            label: 'Request Submitted',
                            sub: '18 Mar, 10:30 AM',
                            isDone: true,
                          ),
                          const _TimelineStep(
                            label: 'Admin Received',
                            sub: '18 Mar, 10:35 AM',
                            isDone: true,
                          ),
                          const _TimelineStep(
                            label: 'Workers Matched',
                            sub: '18 Mar, 2:00 PM',
                            isDone: true,
                          ),
                          const _TimelineStep(
                            label: 'Workers On Site',
                            sub: '20 Mar 2026',
                            isCurrent: true,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Assigned Workers ──────────────────
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
                                    Icons.people_outline_rounded,
                                    color: AppColors.primary,
                                    size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.assignedWorkers,
                                style: KTextStyle.poppins(
                                    fs: 14, fw: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.md),
                          const _WorkerRow(
                              name: 'Ramesh Kumar',
                              skill: 'Mason'),
                          const Divider(
                              color: AppColors.divider,
                              height: 16),
                          const _WorkerRow(
                              name: 'Suresh Yadav',
                              skill: 'Carpenter'),
                          const Divider(
                              color: AppColors.divider,
                              height: 16),
                          const _WorkerRow(
                              name: 'Mahesh Sharma',
                              skill: 'Mason'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // Rate Workers (if fulfilled)
                    if (status == 'fulfilled')
                      CustomButton(
                        label: '⭐  Rate Workers / रेटिंग दें',
                        onTap: () =>
                            Get.to(() => const RateWorkerView()),
                        isOutlined: true,
                      ),
                    const SizedBox(height: AppDimens.lg),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom ──────────────────────────────
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
              child: CustomButton(
                label: AppStrings.requestReplacement,
                isOutlined: true,
                onTap: () => Get.to(
                        () => const ReplacementRequestView()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Banner ─────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.successLight
            : AppColors.warningLight,
        border: Border(
          bottom: BorderSide(
            color: (isActive ? AppColors.success : AppColors.warning)
                .withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_outline_rounded
                : Icons.hourglass_top_rounded,
            size: 15,
            color: isActive ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            isActive
                ? 'Workers Assigned / मज़दूर नियुक्त हो गए'
                : 'Finding Workers / मज़दूर खोजे जा रहे हैं',
            textAlign: TextAlign.center,
            style: KTextStyle.poppins(
              fs: 13,
              fw: FontWeight.w600,
              c: isActive ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style:
            KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

// ── Timeline Step ─────────────────────────────────────────────────
class _TimelineStep extends StatelessWidget {
  final String label, sub;
  final bool isDone, isCurrent, isLast;

  const _TimelineStep({
    required this.label,
    required this.sub,
    this.isDone = false,
    this.isCurrent = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.success
                    : (isCurrent
                    ? AppColors.primary
                    : AppColors.divider),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone
                    ? Icons.check_rounded
                    : (isCurrent
                    ? Icons.sync_rounded
                    : Icons.radio_button_unchecked),
                color: isDone || isCurrent
                    ? Colors.white
                    : AppColors.textHint,
                size: 14,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColors.success : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: KTextStyle.poppins(
                    fs: 13,
                    fw: isCurrent
                        ? FontWeight.w600
                        : FontWeight.normal,
                    c: isCurrent
                        ? AppColors.primary
                        : (isDone
                        ? AppColors.textPrimary
                        : AppColors.textHint),
                  ),
                ),
                Text(
                  sub,
                  style: KTextStyle.poppins(
                      fs: 11, c: AppColors.textHint),
                ),
                if (!isLast) const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Worker Row ────────────────────────────────────────────────────
class _WorkerRow extends StatelessWidget {
  final String name, skill;
  const _WorkerRow({required this.name, required this.skill});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarCircle(initials: name.substring(0, 2), size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style:
                KTextStyle.poppins(fs: 13, fw: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              SkillChip(label: skill, selected: true),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.call_rounded,
              size: 13, color: AppColors.primary),
          label: Text(
            'Call',
            style: KTextStyle.poppins(
                fs: 12,
                fw: FontWeight.w500,
                c: AppColors.primary),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}