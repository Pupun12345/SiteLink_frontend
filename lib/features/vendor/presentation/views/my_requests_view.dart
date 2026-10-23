import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/vendor_jobs_controller.dart';
import 'job_applicants_view.dart';
import 'vendor_job_detail_view.dart';
import 'vendor_plans_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  MY REQUESTS (POSTED JOBS) — real GET /api/jobs (own filter)
// ═══════════════════════════════════════════════════════════════════
class MyRequestsView extends StatelessWidget {
  const MyRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VendorJobsController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: 'my_posted_jobs'.tr,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () async {
              await Get.toNamed(AppRoutes.newRequest);
              ctrl.fetchMyJobs(); // naya job post hone par refresh
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (ctrl.isLoading.value && ctrl.jobs.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (ctrl.jobs.isEmpty) return _EmptyState(onRefresh: ctrl.fetchMyJobs);
          final quota = ctrl.quota.value;
          return RefreshIndicator(
            onRefresh: ctrl.fetchMyJobs,
            color: AppColors.primary,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimens.lg),
              itemCount: ctrl.jobs.length + (quota != null ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimens.md),
              itemBuilder: (_, i) {
                if (quota != null && i == 0) return _QuotaBanner(quota: quota);
                final job = ctrl.jobs[quota != null ? i - 1 : i];
                return _JobCard(
                  job: job,
                  onTap: () => Get.to(() => VendorJobDetailView(job: job)),
                  onDelete: () => _confirmDelete(ctrl, job),
                  onViewApplicants: () =>
                      Get.to(() => JobApplicantsView(job: job)),
                  // Plan renew karke lautne par list refresh — job turant
                  // wapas "Live" dikhe.
                  onRenewPlan: () async {
                    await Get.to(() => const VendorPlansView());
                    ctrl.fetchMyJobs();
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }

  void _confirmDelete(VendorJobsController ctrl, JobModel job) {
    Get.dialog(
      AlertDialog(
        title: Text('deactivate_job_title'.tr,
            style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
        content: Text(
            'deactivate_job_body'.tr,
            style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel_label'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.deleteJob(job.id ?? '');
            },
            child: Text('deactivate_label'.tr,
                style: KTextStyle.poppins(
                    fs: 13, fw: FontWeight.w600, c: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Worker quota banner (subscription plan limit) ──────────────────
class _QuotaBanner extends StatelessWidget {
  final WorkerQuota quota;
  const _QuotaBanner({required this.quota});

  @override
  Widget build(BuildContext context) {
    // Koi active subscription nahi — post karne se pehle plan lena hoga.
    if (!quota.hasActiveSubscription) {
      return _wrap(
        color: AppColors.warning,
        icon: Icons.workspace_premium_outlined,
        title: 'no_active_subscription'.tr,
        subtitle: 'subscribe_plan_to_post'.tr,
      );
    }
    // Plan hai par admin ne worker-limit set nahi ki.
    if (!quota.hasLimit) {
      return _wrap(
        color: AppColors.success,
        icon: Icons.verified_rounded,
        title: 'subscription_active'.tr,
        subtitle: 'workers_posted_so_far'.trParams({'count': '${quota.used}'}),
      );
    }
    final used = quota.used;
    final max = quota.maxWorkers;
    final remaining = quota.remaining ?? 0;
    final ratio = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;
    final full = remaining <= 0;
    final color = full ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.groups_rounded, size: 18, color: color),
            const SizedBox(width: 8),
            // Expanded + ellipsis: label lamba hai ("Employees / Workers
            // this month") aur bade font wale phone par to aur lamba. Pehle
            // Spacer 0 par collapse ho jaata tha aur "2 / 50" label se
            // chipak kar kinare se bahar nikal jaata tha.
            Expanded(
              child: Text('worker_quota_label'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KTextStyle.poppins(fs: 13, fw: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text('$used / $max',
                style: KTextStyle.poppins(
                    fs: 13, fw: FontWeight.w700, c: color)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            full
                ? 'quota_limit_reached'.trParams({'date': quota.resetLabel})
                : 'workers_left_in_plan'.trParams({
                    'count': '$remaining',
                    'date': quota.resetLabel,
                  }),
            style: KTextStyle.poppins(fs: 11.5, c: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _wrap({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: KTextStyle.poppins(fs: 13, fw: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: KTextStyle.poppins(
                      fs: 11.5, c: AppColors.textSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Job card — flat (no elevation), bigger, richer detail ──────────
class _JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onViewApplicants;
  final VoidCallback onRenewPlan;
  const _JobCard({
    required this.job,
    required this.onTap,
    required this.onDelete,
    required this.onViewApplicants,
    required this.onRenewPlan,
  });

  @override
  Widget build(BuildContext context) {
    final salary = job.salary != null
        ? '₹${job.salary}${(job.salaryType ?? '').isNotEmpty ? '/${job.salaryType}' : ''}'
        : '';
    final isOpen = (job.status ?? 'open').toLowerCase() != 'closed';
    final hasApplicants = job.applicationsCount > 0;

    return AppCard(
      showShadow: false, // koi elevation nahi — flat bordered card
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: title + status + menu ────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title ?? 'job_fallback_title'.tr,
                      style:
                          KTextStyle.poppins(fs: 16, fw: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if ((job.jobId ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(job.jobId!,
                        style: KTextStyle.poppins(
                            fs: 10.5, c: AppColors.textHint)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (job.isActive)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 20, color: AppColors.textHint),
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.block_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('deactivate_label'.tr,
                          style:
                              KTextStyle.poppins(fs: 13, c: AppColors.error)),
                    ]),
                  ),
                ],
              ),
          ]),
          const SizedBox(height: 8),

          // ── Badges: deactivated + approval + status + urgent ────
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (!job.isActive)
              _badge(
                  label: 'deactivated_badge'.tr,
                  color: AppColors.textHint,
                  icon: Icons.block_rounded),
            // Approved hai par workers ko ab nahi dikhti (30 din / plan khatam)
            // to "Live" ki jagah asli haalat.
            if (job.isExpired)
              _badge(
                  label: 'job_expired_badge'.tr,
                  color: AppColors.textHint,
                  icon: Icons.event_busy_rounded)
            else if (job.isHiddenByPlan)
              _badge(
                  label: 'job_hidden_badge'.tr,
                  color: AppColors.error,
                  icon: Icons.visibility_off_rounded)
            else
              _approvalBadge(job.approvalStatus),
            if (job.isActive && job.isLive != false)
              _badge(
                label: isOpen ? 'open_badge'.tr : 'closed_badge'.tr,
                color: isOpen ? AppColors.success : AppColors.textHint,
                icon: isOpen
                    ? Icons.radio_button_checked_rounded
                    : Icons.check_circle_rounded,
              ),
            if (job.isUrgent && job.isActive && job.isLive != false)
              _badge(
                  label: 'urgent_label'.tr,
                  color: AppColors.error,
                  icon: Icons.bolt_rounded),
          ]),
          _VisibilityNote(job: job, onRenewPlan: onRenewPlan),
          const SizedBox(height: 12),

          // ── Location ────────────────────────────────────────────
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(job.location ?? '',
                  style: KTextStyle.poppins(
                      fs: 12.5, c: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Detail grid: workers / salary / experience / duration ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: _detailItem(Icons.people_outline_rounded,
                        'workers_label'.tr, '${job.workersCount}')),
                Expanded(
                    child: _detailItem(
                        Icons.payments_outlined, 'pay_label'.tr, salary)),
              ]),
              if ((job.experience ?? '').isNotEmpty ||
                  (job.duration ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _detailItem(Icons.work_history_outlined,
                          'experience_label'.tr, '${job.experience ?? '—'} yrs')),
                  Expanded(
                      child: _detailItem(Icons.timelapse_rounded,
                          'duration'.tr, job.duration ?? '—')),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // ── Footer: applicants + view details ──────────────────
          Row(children: [
            GestureDetector(
              onTap: onViewApplicants,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: hasApplicants
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.people_alt_rounded,
                      size: 15,
                      color: hasApplicants
                          ? AppColors.primary
                          : AppColors.textHint),
                  const SizedBox(width: 5),
                  Text(
                    'applicants_count_suffix'
                        .trParams({'count': '${job.applicationsCount}'}),
                    style: KTextStyle.poppins(
                      fs: 12,
                      fw: FontWeight.w600,
                      c: hasApplicants
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onTap,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('view_details_label'.tr,
                    style: KTextStyle.poppins(
                        fs: 12, fw: FontWeight.w600, c: AppColors.primary)),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: AppColors.primary),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _badge(
      {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusMax),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style:
                KTextStyle.poppins(fs: 10.5, fw: FontWeight.w600, c: color)),
      ]),
    );
  }

  /// Admin approval status — pending/approved/rejected — alag color+icon.
  Widget _approvalBadge(String? approvalStatus) {
    final v = (approvalStatus ?? 'pending').toLowerCase();
    switch (v) {
      case 'approved':
        return _badge(
            label: 'live_badge'.tr,
            color: AppColors.success,
            icon: Icons.verified_rounded);
      case 'rejected':
        return _badge(
            label: 'status_rejected'.tr,
            color: AppColors.error,
            icon: Icons.cancel_rounded);
      default:
        return _badge(
            label: 'pending_admin_approval'.tr,
            color: AppColors.warning,
            icon: Icons.hourglass_top_rounded);
    }
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: KTextStyle.poppins(fs: 10, c: AppColors.textHint)),
            Text(value,
                style: KTextStyle.poppins(fs: 12.5, fw: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ]);
  }
}

// ── Workers ko kab tak dikhegi — note + "Renew plan" ───────────────
// Backend rule: job post se max 30 din dikhti hai, aur tabhi tak jab tak
// vendor ka plan chale. Vendor ko pehle se pata ho ki job kab band hogi,
// aur plan ki wajah se band hui (ya hone wali) ho to wahin se renew kare.
class _VisibilityNote extends StatelessWidget {
  final JobModel job;
  final VoidCallback onRenewPlan;
  const _VisibilityNote({required this.job, required this.onRenewPlan});

  static const _jobVisibleDays = 30;
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final until = job.visibleUntil;
    final posted = job.postedAt?.toLocal();
    final approved = (job.approvalStatus ?? '').toLowerCase() == 'approved';
    if (!approved || !job.isActive || job.isLive == null || posted == null) {
      return const SizedBox.shrink();
    }
    // Plan na hota to job kab tak dikhti (30 din ki limit).
    final maxDate = posted.add(const Duration(days: _jobVisibleDays));

    final String text;
    final Color color;
    var showRenew = false;

    if (job.isExpired) {
      text = 'job_expired_note'.tr;
      color = AppColors.textHint;
    } else if (job.isHiddenByPlan) {
      text = 'job_hidden_plan_note'.trParams({'date': _fmt(maxDate)});
      color = AppColors.error;
      showRenew = true;
    } else if (until != null) {
      final endsByPlan = until.isBefore(maxDate.subtract(const Duration(hours: 1)));
      final daysLeft = until.difference(DateTime.now()).inDays;
      if (endsByPlan) {
        // Plan 30 din se pehle khatam ho raha hai — abhi se bata do.
        text = 'job_ends_with_plan_note'
            .trParams({'date': _fmt(until), 'max': _fmt(maxDate)});
        color = AppColors.warning;
        showRenew = true;
      } else if (daysLeft < 3) {
        text = daysLeft < 1
            ? 'job_ends_today_note'.tr
            : 'job_ends_in_days_note'.trParams({'days': '$daysLeft'});
        color = AppColors.warning;
      } else {
        text = 'job_visible_till_note'.trParams({'date': _fmt(until)});
        color = AppColors.textSecondary;
      }
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: Row(children: [
          Icon(Icons.schedule_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: KTextStyle.poppins(fs: 11.5, c: color, fw: FontWeight.w500)),
          ),
          if (showRenew)
            TextButton(
              onPressed: onRenewPlan,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('renew_plan_label'.tr,
                  style: KTextStyle.poppins(
                      fs: 12, fw: FontWeight.w700, c: AppColors.primary)),
            ),
        ]),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Column(children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.assignment_outlined,
                  size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('no_jobs_posted_yet'.tr,
                style: KTextStyle.poppins(
                    fs: 15, fw: FontWeight.w600, c: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('post_job_to_start_hiring'.tr,
                style: KTextStyle.poppins(fs: 12, c: AppColors.textHint)),
            const SizedBox(height: 24),
            CustomButton(
              label: 'post_new_job_btn'.tr,
              onTap: () => Get.toNamed(AppRoutes.newRequest),
              width: 240,
            ),
          ]),
        ],
      ),
    );
  }
}
