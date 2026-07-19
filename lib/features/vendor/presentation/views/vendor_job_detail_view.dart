import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/vendor_jobs_controller.dart';
import 'job_applicants_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR JOB DETAIL — apna posted job (full detailing, flat cards)
// ═══════════════════════════════════════════════════════════════════
class VendorJobDetailView extends StatelessWidget {
  final JobModel job;
  const VendorJobDetailView({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final salary = job.salary != null
        ? '₹${job.salary}${(job.salaryType ?? '').isNotEmpty ? ' / ${job.salaryType}' : ''}'
        : '—';
    final isOpen = (job.status ?? 'open').toLowerCase() != 'closed';
    final hasApplicants = job.applicationsCount > 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'Job Details'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header card ──────────────────────────────────
              AppCard(
                showShadow: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Text(job.title ?? 'Job',
                            style: KTextStyle.poppins(
                                fs: 19, fw: FontWeight.w700)),
                      ),
                    ]),
                    if ((job.jobId ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(job.jobId!,
                          style: KTextStyle.poppins(
                              fs: 11.5, c: AppColors.textHint)),
                    ],
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _badge(
                        label: isOpen ? 'Open' : 'Closed',
                        color: isOpen ? AppColors.success : AppColors.textHint,
                        icon: isOpen
                            ? Icons.radio_button_checked_rounded
                            : Icons.check_circle_rounded,
                      ),
                      if (job.isUrgent)
                        _badge(
                            label: 'Urgent Hiring',
                            color: AppColors.error,
                            icon: Icons.bolt_rounded),
                      _approvalBadge(job.approvalStatus),
                    ]),
                    if (job.approvalStatus?.toLowerCase() == 'rejected' &&
                        (job.rejectionReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 15, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(job.rejectionReason!,
                                  style: KTextStyle.poppins(
                                      fs: 12, c: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if ((job.companyName).isNotEmpty)
                      _row(Icons.business_outlined, job.companyName),
                    const SizedBox(height: 10),
                    _row(Icons.location_on_outlined, job.location ?? ''),
                    if ((job.postedAt) != null) ...[
                      const SizedBox(height: 10),
                      _row(Icons.calendar_today_rounded,
                          'Posted ${_timeAgo(job.postedAt!)}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.md),

              // ── Applicants CTA — bada, prominent ──────────────
              AppCard(
                showShadow: false,
                onTap: () => Get.to(() => JobApplicantsView(job: job)),
                borderColor:
                    hasApplicants ? AppColors.primary : AppColors.divider,
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${job.applicationsCount} Applicant${job.applicationsCount == 1 ? '' : 's'}',
                          style: KTextStyle.poppins(
                              fs: 15, fw: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasApplicants
                              ? 'Tap to view & confirm workers'
                              : 'No applications yet',
                          style: KTextStyle.poppins(
                              fs: 11.5, c: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.primary),
                ]),
              ),
              const SizedBox(height: AppDimens.md),

              // ── Details ──────────────────────────────────────
              AppCard(
                showShadow: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job Details',
                        style: KTextStyle.poppins(
                            fs: 14, fw: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: _detailTile(Icons.people_outline_rounded,
                              'Workers Needed', '${job.workersCount}')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _detailTile(
                              Icons.payments_outlined, 'Pay', salary)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _detailTile(
                              Icons.work_history_outlined,
                              'Experience',
                              (job.experience ?? '').isNotEmpty
                                  ? '${job.experience} yrs'
                                  : '—')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _detailTile(Icons.timelapse_rounded,
                              'Duration', job.duration ?? '—')),
                    ]),
                    if ((job.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 14),
                      Text('Description',
                          style: KTextStyle.poppins(
                              fs: 13, fw: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(job.description!,
                          style: KTextStyle.poppins(
                              fs: 12.5,
                              c: AppColors.textSecondary,
                              height: 1.5)),
                    ],
                  ],
                ),
              ),

              // ── Amenities ────────────────────────────────────
              if (job.amenities.isNotEmpty) ...[
                const SizedBox(height: AppDimens.md),
                AppCard(
                  showShadow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amenities & Benefits',
                          style: KTextStyle.poppins(
                              fs: 14, fw: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: job.amenities
                            .map((a) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.scaffoldBg,
                                    borderRadius: BorderRadius.circular(
                                        AppDimens.radiusMax),
                                    border: Border.all(
                                        color: AppColors.divider),
                                  ),
                                  child: Text(
                                    '${a.icon ?? ''} ${a.name ?? ''}'.trim(),
                                    style: KTextStyle.poppins(
                                        fs: 12, fw: FontWeight.w500),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppDimens.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum:
              const EdgeInsets.fromLTRB(AppDimens.lg, 10, AppDimens.lg, 10),
          child: CustomButton(
            label: 'Deactivate Job',
            isOutlined: true,
            leading: const Icon(Icons.block_rounded,
                size: 18, color: AppColors.error),
            onTap: () => _confirmDelete(context),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('Deactivate Job?',
            style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
        content: Text(
            'Ye job workers ko dikhna band ho jaayega. Aapke plan ke worker '
            'quota me ye phir bhi count hota rahega.',
            style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back(); // dialog
              if (Get.isRegistered<VendorJobsController>()) {
                Get.find<VendorJobsController>().deleteJob(job.id ?? '');
              }
              Get.back(); // detail screen
            },
            child: Text('Deactivate',
                style: KTextStyle.poppins(
                    fs: 13, fw: FontWeight.w600, c: AppColors.error)),
          ),
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

  Widget _row(IconData icon, String text) => Row(children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: KTextStyle.poppins(fs: 12.5, c: AppColors.textSecondary)),
        ),
      ]);

  Widget _detailTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(label,
              style: KTextStyle.poppins(fs: 10, c: AppColors.textHint)),
          const SizedBox(height: 2),
          Text(value,
              style: KTextStyle.poppins(fs: 13, fw: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  /// Admin approval status — pending/approved/rejected — alag color+icon.
  Widget _approvalBadge(String? approvalStatus) {
    final v = (approvalStatus ?? 'pending').toLowerCase();
    switch (v) {
      case 'approved':
        return _badge(
            label: 'Live',
            color: AppColors.success,
            icon: Icons.verified_rounded);
      case 'rejected':
        return _badge(
            label: 'Rejected',
            color: AppColors.error,
            icon: Icons.cancel_rounded);
      default:
        return _badge(
            label: 'Pending Admin Approval',
            color: AppColors.warning,
            icon: Icons.hourglass_top_rounded);
    }
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
