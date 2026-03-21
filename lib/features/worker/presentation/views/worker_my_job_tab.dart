import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';

import '../controllers/worker_myjob_controller.dart';
import 'active_job_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER MY JOBS TAB  —  Tab 1
//  Shows: Available Jobs (posted by vendors) + My Assigned Jobs
// ═══════════════════════════════════════════════════════════════════
class WorkerMyJobsTab extends StatefulWidget {
  const WorkerMyJobsTab({super.key});

  @override
  State<WorkerMyJobsTab> createState() => _WorkerMyJobsTabState();
}

class _WorkerMyJobsTabState extends State<WorkerMyJobsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late MyJobsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl    = Get.put(MyJobsController());
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'Jobs', showBack: false),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Tab Bar ──────────────────────────────────────
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: KTextStyle.poppins(fs: 13, fw: FontWeight.w600),
                unselectedLabelStyle: KTextStyle.poppins(fs: 13),
                tabs: const [
                  Tab(text: 'Available'),
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => TabBarView(
                controller: _tabCtrl,
                children: [
                  _AvailableJobsList(jobs: _ctrl.availableJobs),
                  _AssignedJobsList(jobs: _ctrl.activeJobs),
                  _AssignedJobsList(jobs: _ctrl.completedJobs),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AVAILABLE JOBS LIST (vendor-posted requirements)
// ═══════════════════════════════════════════════════════════════════
class _AvailableJobsList extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  const _AvailableJobsList({required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return const _EmptyState(message: 'No available jobs right now');

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.lg),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
      itemBuilder: (_, i) => _AvailableJobCard(job: jobs[i]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ASSIGNED JOBS LIST (admin-assigned jobs)
// ═══════════════════════════════════════════════════════════════════
class _AssignedJobsList extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  const _AssignedJobsList({required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return const _EmptyState(message: 'No jobs here yet');

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.lg),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
      itemBuilder: (_, i) => _AssignedJobCard(job: jobs[i]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AVAILABLE JOB CARD
// ═══════════════════════════════════════════════════════════════════
class _AvailableJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _AvailableJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final isUrgent = job['urgent'] == true;

    return AppCard(
      onTap: () {
        // TODO: Get.to(() => WorkerJobDetailView(jobId: job['id']));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ────────────────────────────────────────
          Row(
            children: [
              Expanded(child: SkillChip(label: job['role'] ?? '', selected: true)),
              if (isUrgent) ...[
                const SizedBox(width: 8),
                _UrgentBadge(),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(job['company'] ?? '', style: KTextStyle.poppins(fs: 15, fw: FontWeight.w600)),
          const SizedBox(height: 8),

          // ── Info rows ───────────────────────────────────────
          _InfoRow(icon: Icons.location_on_outlined, text: job['location'] ?? ''),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.people_outline_rounded,
                  text: '${job['workers']} workers needed',
                ),
              ),
              Expanded(
                child: _InfoRow(icon: Icons.timelapse_rounded, text: job['duration'] ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _InfoRow(icon: Icons.calendar_today_rounded, text: 'Start: ${job['startDate']}'),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // ── Footer ─────────────────────────────────────────
          Row(
            children: [
              _RatePill(rate: job['rate'] ?? ''),
              const Spacer(),
              Text('View Details', style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500, c: AppColors.primary)),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ASSIGNED JOB CARD
// ═══════════════════════════════════════════════════════════════════
class _AssignedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _AssignedJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final isActive = job['status'] == 'active';

    return AppCard(
      showLeftBorder: true,
      leftBorderColor: isActive ? AppColors.primary : AppColors.info,
      onTap: isActive ? () => Get.to(() => const ActiveJobView()) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkillChip(label: job['role'] ?? '', selected: true),
              const Spacer(),
              StatusBadge(type: isActive ? BadgeType.active : BadgeType.completed),
            ],
          ),
          const SizedBox(height: 10),
          Text(job['company'] ?? '', style: KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(job['location'] ?? '', style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary)),
              const Spacer(),
              Text(job['rate'] ?? '', style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600, c: AppColors.success)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(job['dates'] ?? '', style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('View Details', style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500, c: AppColors.primary)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS (private to this file)
// ═══════════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: AppColors.textSecondary),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _RatePill extends StatelessWidget {
  final String rate;
  const _RatePill({required this.rate});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.success.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDimens.radiusMax),
    ),
    child: Text(rate, style: KTextStyle.poppins(fs: 13, fw: FontWeight.w700, c: AppColors.success)),
  );
}

class _UrgentBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(AppDimens.radiusMax),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt_rounded, size: 11, color: Colors.red.shade600),
        const SizedBox(width: 2),
        Text('Urgent', style: KTextStyle.poppins(fs: 10, fw: FontWeight.w600, c: Colors.red.shade600)),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(Icons.work_off_outlined, size: 36, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 14),
        Text(message, style: KTextStyle.poppins(fs: 14, c: AppColors.textSecondary)),
      ],
    ),
  );
}