import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/rating_badge.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';
import '../controllers/job_applicants_controller.dart';
import '../controllers/vendor_jobs_controller.dart';
import 'applicant_profile_view.dart';

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
      appBar: GradientAppBar(title: 'applicants_title'.tr),
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
                Text(job.title ?? 'job_fallback_title'.tr,
                    style: KTextStyle.poppins(fs: 15, fw: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('workers_needed_suffix'
                      .trParams({'count': '${job.workersCount}'}),
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
        title: Text(hire ? 'confirm_worker_title'.tr : 'reject_applicant_title'.tr,
            style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
        content: Text(
          hire
              ? 'confirm_worker_body'.trParams(
                  {'name': a.name ?? 'this_worker_fallback'.tr})
              : 'reject_applicant_body'.trParams(
                  {'name': a.name ?? 'this_applicant_fallback'.tr}),
          style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel_label'.tr)),
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
              hire ? 'confirm_label'.tr : 'reject_label'.tr,
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
      // Card tap = poora applicant profile (documents + community posts).
      // Confirm/Reject buttons apne alag onTap rakhte hain, isliye wo
      // isse override nahi hote.
      onTap: () => Get.to(() => ApplicantProfileView(applicant: a)),
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
                        child: Text(a.name ?? 'worker'.tr,
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
                    // Role — plain text (chip pill se hatakar), kyunki
                    // skill names lambe ho sakte hai (jaise "Rope Access
                    // Technician (Mechanical)") — chip me wrap hoke bada
                    // sa blob ban jaata tha.
                    if ((a.primarySkill ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(a.primarySkill!,
                          style: KTextStyle.poppins(
                              fs: 12.5,
                              fw: FontWeight.w600,
                              c: AppColors.primary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    // Performance rating — job outcomes se automatic banti
                    // hai. Naya worker ho to "New" dikhta hai, 0 stars
                    // nahi (warna naye ko kabhi koi hire hi na kare).
                    //
                    // `rating == null` ka matlab alag hai: worker ke paas
                    // plan nahi hai isliye backend ne rating bheji hi
                    // nahi. Tab kuch nahi dikhate — "New" dikhana jhooth
                    // hota (uski rating ho sakti hai, bas chhupi hai).
                    if (a.rating != null) ...[
                      const SizedBox(height: 6),
                      RatingBadge(rating: a.rating),
                    ],
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
                        'experience_label'.tr,
                        a.totalExperience != null
                            ? '${a.totalExperience} ${'yr_plural'.tr}'
                            : '—'),
                  ),
                  Expanded(
                    child: _infoItem(Icons.location_on_outlined,
                        'location_label'.tr, a.locationLabel.isEmpty ? '—' : a.locationLabel),
                  ),
                ]),
                if (a.appliedAt != null) ...[
                  const SizedBox(height: 10),
                  _infoItem(Icons.access_time_rounded, 'status_applied'.tr,
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
              Text('cover_letter_label'.tr,
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
                            label: 'reject_label'.tr,
                            isOutlined: true,
                            isLoading: isActioning,
                            onTap: isActioning ? null : onReject,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            label: 'confirm_label'.tr,
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
                                ? 'confirmed_for_job_label'.tr
                                : 'application_rejected_label'.tr,
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
        ? ('status_confirmed'.tr, AppColors.success)
        : a.isRejected
            ? ('status_rejected'.tr, AppColors.error)
            : a.isShortlisted
                ? ('status_shortlisted'.tr, AppColors.info)
                : ('pending'.tr, AppColors.warning);
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
      if (!ok) AppSnackbar.error(message: 'call_failed_generic'.tr);
    } catch (_) {
      AppSnackbar.error(message: 'call_failed_generic'.tr);
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
            Text('no_applications_yet'.tr,
                style: KTextStyle.poppins(
                    fs: 15, fw: FontWeight.w600, c: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('workers_apply_show_here'.tr,
                style: KTextStyle.poppins(fs: 12, c: AppColors.textHint)),
          ]),
        ],
      ),
    );
  }
}
