import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';
import '../controllers/job_applicants_controller.dart';
import '../controllers/vendor_jobs_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  JOB APPLICANTS — vendor ke liye, workers jinhone apply kiya + Confirm/Reject
// ═══════════════════════════════════════════════════════════════════
class JobApplicantsView extends StatelessWidget {
  final JobModel job;
  const JobApplicantsView({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(
        JobApplicantsController(job.id ?? ''), tag: job.id);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'Applicants'),
      body: SafeArea(
        top: false,
        child: Column(children: [
          // ── Job summary strip ─────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
                AppDimens.lg, 12, AppDimens.lg, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title ?? 'Job',
                    style: KTextStyle.poppins(fs: 15, fw: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('${job.workersCount} needed',
                      style: KTextStyle.poppins(
                          fs: 11.5, c: AppColors.textHint)),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(job.location ?? '',
                        style: KTextStyle.poppins(
                            fs: 11.5, c: AppColors.textHint),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.divider),

          // ── Applicants list ────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value && ctrl.applicants.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary));
              }
              if (ctrl.applicants.isEmpty) {
                return _EmptyApplicants(onRefresh: ctrl.fetchApplicants);
              }
              // Confirmed pehle, phir pending, phir rejected — sabse
              // relevant applicants upar dikhein
              final sorted = [...ctrl.applicants]..sort((a, b) {
                  const order = {
                    'confirmed': 0,
                    'shortlisted': 1,
                    'pending': 2,
                    'rejected': 3,
                  };
                  return (order[a.status] ?? 9)
                      .compareTo(order[b.status] ?? 9);
                });
              return RefreshIndicator(
                onRefresh: ctrl.fetchApplicants,
                color: AppColors.primary,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.lg),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimens.md),
                  itemBuilder: (_, i) => _ApplicantCard(
                    applicant: sorted[i],
                    isActioning:
                        ctrl.actioningId.value == sorted[i].applicationId,
                    onConfirm: () => _confirmAction(
                        context, ctrl, sorted[i], hire: true),
                    onReject: () => _confirmAction(
                        context, ctrl, sorted[i], hire: false),
                  ),
                ),
              );
            }),
          ),
        ]),
      ),
    );
  }

  void _confirmAction(BuildContext context, JobApplicantsController ctrl,
      JobApplicant a, {required bool hire}) {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(hire ? 'Confirm this worker?' : 'Reject this applicant?',
            style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
        content: Text(
          hire
              ? '${a.name ?? 'This worker'} ko is job ke liye confirm/hire kiya jaayega.'
              : '${a.name ?? 'This applicant'} ki application reject ho jaayegi.',
          style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              if (hire) {
                ctrl.confirmApplicant(a);
              } else {
                ctrl.rejectApplicant(a);
              }
              // Job list ka applicants count bhi refresh ho jaaye
              if (Get.isRegistered<VendorJobsController>()) {
                Get.find<VendorJobsController>().fetchMyJobs();
              }
            },
            child: Text(
              hire ? 'Confirm' : 'Reject',
              style: KTextStyle.poppins(
                  fs: 13,
                  fw: FontWeight.w600,
                  c: hire ? AppColors.success : AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Applicant card — full worker details + actions ─────────────────
class _ApplicantCard extends StatelessWidget {
  final JobApplicant applicant;
  final bool isActioning;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  const _ApplicantCard({
    required this.applicant,
    required this.isActioning,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final a = applicant;
    final imgUrl = WorkerFeedController.fullUrl(a.profileImage);

    return AppCard(
      showShadow: false,
      borderColor: a.isConfirmed
          ? AppColors.success
          : a.isRejected
              ? AppColors.divider
              : AppColors.divider,
      child: Opacity(
        opacity: a.isRejected ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + name + skill + status ──────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AvatarCircle(
                initials: _initials(a.name ?? ''),
                size: 52,
                fontSize: 17,
                imageUrl: imgUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(a.name ?? 'Worker',
                            style: KTextStyle.poppins(
                                fs: 15, fw: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (a.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified_rounded,
                              size: 15, color: AppColors.primary),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      if ((a.primarySkill ?? '').isNotEmpty)
                        SkillChip(label: a.primarySkill!, selected: true),
                      if (a.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusMax),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.star_rounded,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text('${a.rating}',
                                style: KTextStyle.poppins(
                                    fs: 10.5, fw: FontWeight.w600)),
                          ]),
                        ),
                    ]),
                  ],
                ),
              ),
              _statusBadge(a),
            ]),
            const SizedBox(height: 12),

            // ── Details grid ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: _infoItem(
                        Icons.work_history_outlined,
                        'Experience',
                        a.totalExperience != null
                            ? '${a.totalExperience} yrs'
                            : '—'),
                  ),
                  Expanded(
                    child: _infoItem(Icons.location_on_outlined,
                        'Location', a.locationLabel.isEmpty ? '—' : a.locationLabel),
                  ),
                ]),
                if (a.appliedAt != null) ...[
                  const SizedBox(height: 10),
                  _infoItem(Icons.access_time_rounded, 'Applied',
                      _timeAgo(a.appliedAt!)),
                ],
              ]),
            ),

            if (a.skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: a.skills
                    .take(5)
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBg,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusMax),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(s,
                              style: KTextStyle.poppins(
                                  fs: 10.5, c: AppColors.textSecondary)),
                        ))
                    .toList(),
              ),
            ],

            if ((a.coverLetter ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Cover Letter',
                  style: KTextStyle.poppins(fs: 11.5, fw: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(a.coverLetter!,
                  style: KTextStyle.poppins(
                      fs: 12, c: AppColors.textSecondary, height: 1.4)),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),

            // ── Actions ───────────────────────────────────────────
            Row(children: [
              if ((a.phone ?? '').isNotEmpty)
                _iconAction(
                  icon: Icons.call_outlined,
                  color: AppColors.primary,
                  onTap: () => _call(a.phone!),
                ),
              if ((a.phone ?? '').isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: a.isPending || a.isShortlisted
                    ? Row(children: [
                        Expanded(
                          child: CustomButton(
                            label: 'Reject',
                            isOutlined: true,
                            isLoading: isActioning,
                            onTap: isActioning ? null : onReject,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            label: 'Confirm',
                            isLoading: isActioning,
                            onTap: isActioning ? null : onConfirm,
                          ),
                        ),
                      ])
                    : Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: (a.isConfirmed
                                  ? AppColors.success
                                  : AppColors.textHint)
                              .withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                        child: Center(
                          child: Text(
                            a.isConfirmed
                                ? '✓ Confirmed for this job'
                                : 'Application rejected',
                            style: KTextStyle.poppins(
                              fs: 12.5,
                              fw: FontWeight.w600,
                              c: a.isConfirmed
                                  ? AppColors.success
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(JobApplicant a) {
    final (label, color) = a.isConfirmed
        ? ('Confirmed', AppColors.success)
        : a.isRejected
            ? ('Rejected', AppColors.error)
            : a.isShortlisted
                ? ('Shortlisted', AppColors.info)
                : ('Pending', AppColors.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusMax),
      ),
      child: Text(label,
          style: KTextStyle.poppins(fs: 10, fw: FontWeight.w600, c: color)),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.primary),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: KTextStyle.poppins(fs: 9.5, c: AppColors.textHint)),
            Text(value,
                style: KTextStyle.poppins(fs: 11.5, fw: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ]);
  }

  Widget _iconAction(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final ok = await launchUrl(uri);
      if (!ok) AppSnackbar.error(message: 'Call nahi ho paayi');
    } catch (_) {
      AppSnackbar.error(message: 'Call nahi ho paayi');
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'W';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyApplicants extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyApplicants({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Column(children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.people_outline_rounded,
                  size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('No applications yet',
                style: KTextStyle.poppins(
                    fs: 15, fw: FontWeight.w600, c: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Workers who apply will show up here',
                style: KTextStyle.poppins(fs: 12, c: AppColors.textHint)),
          ]),
        ],
      ),
    );
  }
}
