import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../controllers/worker_myjob_controller.dart';
import 'comments_sheet.dart';
import 'job_applied_success_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER JOB DETAIL VIEW
// ═══════════════════════════════════════════════════════════════════
// `job` Map se basic info turant dikhti hai. Agar `job['apiId']` hai to
// /api/jobs/:id se full detail (description, experience) fetch hoti hai.
class WorkerJobDetailView extends StatefulWidget {
  final Map<String, dynamic> job;
  const WorkerJobDetailView({super.key, required this.job});

  @override
  State<WorkerJobDetailView> createState() => _WorkerJobDetailViewState();
}

class _WorkerJobDetailViewState extends State<WorkerJobDetailView> {
  final _jobsApi = JobsApiService();
  final _profileApi = ProfileApiService();
  late Map<String, dynamic> job;
  bool _loadingDetail = false;
  final _applying = false.obs;
  List<JobAmenity> _amenities = const [];
  bool? _isVerified; // null = abhi tak pata nahi
  final _isLiked = false.obs; // job like toggle (optimistic)
  final _locating = false.obs; // "Get Directions" — current location fetch ho rahi hai

  @override
  void initState() {
    super.initState();
    job = Map<String, dynamic>.from(widget.job);
    _maybeFetchDetail();
    _fetchVerification(); // apply se pehle verification ready ho jaaye
  }

  /// Account verified hai? (profile/me se). Fail/unknown → null.
  Future<void> _fetchVerification() async {
    try {
      final res = await _profileApi.getMe();
      final v = res.user?.isVerified;
      if (mounted && v != null) setState(() => _isVerified = v);
    } catch (_) {/* unknown — apply ke waqt phir try hoga */}
  }

  Future<void> _maybeFetchDetail() async {
    final apiId = job['apiId'] as String?;
    if (apiId == null || apiId.isEmpty) return;

    setState(() => _loadingDetail = true);
    final detail = await _jobsApi.getJobById(apiId);
    if (!mounted) return;
    setState(() {
      if (detail != null) {
        job['notes'] = detail.description ?? job['notes'];
        job['experience'] = detail.experience;
        if ((detail.duration ?? '').isNotEmpty) job['duration'] = detail.duration;
        if (detail.workersCount > 0) job['workers'] = detail.workersCount;
        if ((detail.latitude ?? '').isNotEmpty) job['lat'] = detail.latitude;
        if ((detail.longitude ?? '').isNotEmpty) job['lng'] = detail.longitude;
        if ((detail.salaryType ?? '').isNotEmpty) {
          job['salaryType'] = detail.salaryType;
        }
        if ((job['company'] ?? '').toString().isEmpty &&
            detail.companyName.isNotEmpty) {
          job['company'] = detail.companyName;
        }
        // Pay agar list se nahi aaya to salary + salaryType se banao
        if ((job['rate'] ?? '').toString().isEmpty && detail.salary != null) {
          final st = (detail.salaryType ?? '').isEmpty ? '' : ' / ${detail.salaryType}';
          job['rate'] = '₹${detail.salary}$st';
        }
        job['isUrgent'] = detail.isUrgent;
        // Backend sirf tabhi bhejta hai jab application confirm/hire ho
        // chuki ho — warna dono null aate hai (contact card hi nahi dikhta).
        job['vendorPhone'] = detail.postedBy?.phone;
        job['vendorWhatsapp'] = detail.postedBy?.whatsappNumber;
        _amenities = detail.amenities;
      }
      _loadingDetail = false;
    });
  }

  /// Job like/unlike — PUT /jobs/:id/like (optimistic toggle).
  Future<void> _toggleLike() async {
    final apiId = job['apiId'] as String?;
    if (apiId == null || apiId.isEmpty) return;
    _isLiked.toggle(); // optimistic
    final res = await _jobsApi.likeJob(apiId);
    if (!res.success) {
      _isLiked.toggle(); // revert
      AppSnackbar.error(message: res.message ?? 'Like nahi hua');
    }
  }

  /// Job comments sheet (add + read; edit/delete job pe nahi hota).
  void _openComments() {
    final apiId = job['apiId'] as String?;
    if (apiId == null || apiId.isEmpty) {
      AppSnackbar.error(message: 'Job id missing');
      return;
    }
    CommentsSheet.open(context, apiId, isJob: true);
  }

  /// Google Maps me directions kholo (lat/long se). Values UI me show nahi hoti.
  /// Location permission maang ke current position ko origin banate hain —
  /// mile to "meri location → job site" turn-by-turn route khulta hai;
  /// na mile (denied/off) to bhi destination-only maps khul jaata hai.
  Future<void> _openDirections(String lat, String lng) async {
    if (_locating.value) return;
    _locating.value = true;
    final result = await LocationService.getCurrentLocation();
    _locating.value = false;

    if (!result.hasPosition && (result.error ?? '').isNotEmpty) {
      // Permission na milne pe bhi feature block nahi hota — bas info dikhao
      AppSnackbar.warning(message: result.error!);
    }

    final origin = result.hasPosition
        ? '&origin=${result.position!.latitude},${result.position!.longitude}'
        : '';
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1$origin&destination=$lat,$lng');
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) AppSnackbar.error(message: 'Map nahi khul paaya');
    } catch (_) {
      AppSnackbar.error(message: 'Map nahi khul paaya');
    }
  }

  /// Confirmed-unverified ho to false; verified ya unknown ho to true (allow).
  Future<bool> _ensureVerified() async {
    if (_isVerified != null) return _isVerified!;
    try {
      final res = await _profileApi.getMe();
      _isVerified = res.user?.isVerified ?? true; // unknown → allow (backend gate)
    } catch (_) {
      _isVerified = true; // network fail → block mat karo, backend enforce karega
    }
    return _isVerified!;
  }

  /// "Apply for this job" — verified user hi apply kar sakta hai.
  Future<void> _applyDirect() async {
    if (_applying.value) return; // double-tap guard
    final apiId = job['apiId'] as String?;
    if (apiId == null || apiId.isEmpty) {
      AppSnackbar.error(message: 'Job id missing — apply nahi kar sakte.');
      return;
    }

    // ── Verification gate ─────────────────────────────────────────
    _applying.value = true;
    final allowed = await _ensureVerified();
    if (!allowed) {
      _applying.value = false;
      _showVerificationPending();
      return;
    }

    final res = await _jobsApi.applyToJob(apiId);
    _applying.value = false;
    if (res.success) {
      if (Get.isRegistered<MyJobsController>()) {
        Get.find<MyJobsController>().fetchAppliedJobs();
      }
      // Celebration screen — confetti + congrats, auto home after ~4s
      Get.to(() => JobAppliedSuccessView(jobTitle: job['role']?.toString()));
    } else {
      AppSnackbar.error(message: res.message ?? 'Failed to apply');
    }
  }

  // ── Verification pending — accha sa dialog ────────────────────────
  void _showVerificationPending() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_outlined,
                    color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 18),
              Text('Verification Pending',
                  style: KTextStyle.poppins(fs: 18, fw: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                'Aapka account abhi verify nahi hua hai.\n'
                'Hamari team aapki profile 24–48 hours me verify kar degi.',
                textAlign: TextAlign.center,
                style: KTextStyle.poppins(
                    fs: 13, c: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Verify hone ke baad aap jobs pe apply kar payenge.',
                        style: KTextStyle.poppins(
                            fs: 11.5, c: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomButton(label: 'Got it', onTap: () => Get.back()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Application status → top badge. `appStatus == null` matlab abhi apply
  /// nahi kiya (browsing "Available" job).
  Widget _appStatusBadge(String? appStatus) {
    switch (appStatus) {
      case 'pending':
        return const StatusBadge(type: BadgeType.pending, customLabel: 'Under Review');
      case 'shortlisted':
        return const StatusBadge(type: BadgeType.active, customLabel: 'Shortlisted');
      case 'confirmed':
        return const StatusBadge(type: BadgeType.verified, customLabel: 'Confirmed');
      case 'hired':
        return const StatusBadge(type: BadgeType.verified, customLabel: 'Hired');
      case 'rejected':
        return const StatusBadge(type: BadgeType.rejected, customLabel: 'Rejected');
      case null:
        return const StatusBadge(type: BadgeType.fulfilled, customLabel: 'Available');
      default:
        return const StatusBadge(type: BadgeType.pending, customLabel: 'Applied');
    }
  }

  String _appliedButtonLabel(String? appStatus) {
    switch (appStatus) {
      case 'shortlisted':
        return 'Shortlisted — waiting for confirmation';
      case 'confirmed':
        return 'Confirmed by vendor';
      case 'hired':
        return 'Hired';
      case 'rejected':
        return 'Application rejected';
      default:
        return 'Applied — under review';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 'appStatus' sirf Applied tab se aaye jobs par set hota hai (real
    // backend Application.status: pending/shortlisted/confirmed/rejected/hired).
    final appStatus = (job['appStatus'] as String?)?.toLowerCase();
    final isApplied = appStatus != null;
    final contactUnlocked = appStatus == 'confirmed' || appStatus == 'hired';
    final jobType = (job['type'] as String?) ?? 'daily';
    final title = job['role'] ?? 'Job';
    final company = job['company'] ?? '';
    final location = job['location'] ?? '';
    final rate = job['rate'] ?? '';
    final duration = jobType == 'permanent'
        ? 'Permanent employment'
        : job['duration'] ?? '';
    final startDate = job['startDate'] ?? job['dates'] ?? '';
    final workers = job['workers'] != null ? '${job['workers']} workers' : '';
    final experience = (job['experience'] ?? '').toString();
    final lat = (job['lat'] ?? '').toString();
    final lng = (job['lng'] ?? '').toString();
    final hasCoords = lat.isNotEmpty && lng.isNotEmpty;
    final isUrgent = job['isUrgent'] == true;
    final salaryType = (job['salaryType'] ?? '').toString();
    final statusBadge = _appStatusBadge(appStatus);

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
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: KTextStyle.poppins(fs: 18, fw: FontWeight.w700),
                          ),
                        ),
                        statusBadge,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      company,
                      style: KTextStyle.poppins(fs: 14, c: AppColors.textSecondary),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMax),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text('Urgent hiring',
                                style: KTextStyle.poppins(
                                    fs: 11,
                                    fw: FontWeight.w600,
                                    c: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _InfoRow(icon: Icons.location_on_outlined, text: location),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.people_outline_rounded, text: workers),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.calendar_today_rounded, text: startDate),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 6),
                    // ── Like + Comment actions ────────────────────
                    Row(children: [
                      Obx(() => _JobAction(
                            icon: _isLiked.value
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: _isLiked.value ? 'Liked' : 'Like',
                            color: _isLiked.value
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            onTap: _toggleLike,
                          )),
                      const SizedBox(width: 8),
                      _JobAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Questions',
                        color: AppColors.textSecondary,
                        onTap: _openComments,
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              if (hasCoords) ...[
                Obx(() => CustomButton(
                      label: 'Get Directions',
                      isOutlined: true,
                      isLoading: _locating.value,
                      leading: const Icon(Icons.directions_rounded,
                          size: 18, color: AppColors.primary),
                      onTap: () => _openDirections(lat, lng),
                    )),
                const SizedBox(height: AppDimens.lg),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Contract details',
                            style: KTextStyle.poppins(fs: 14, fw: FontWeight.w700)),
                        if (_loadingDetail) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailPill(label: 'Type', value: jobType == 'permanent' ? 'Permanent' : 'Daily wage'),
                    const SizedBox(height: 8),
                    _DetailPill(label: 'Duration', value: duration),
                    const SizedBox(height: 8),
                    _DetailPill(label: 'Pay', value: rate),
                    if (salaryType.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailPill(label: 'Salary type', value: _cap(salaryType)),
                    ],
                    if (experience.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailPill(label: 'Experience', value: '$experience yrs'),
                    ],
                    const SizedBox(height: 8),
                    _DetailPill(label: 'Start', value: startDate),
                    if (job['notes'] != null) ...[
                      const SizedBox(height: 12),
                      Text('Description', style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('${job['notes']}', style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (_amenities.isNotEmpty) ...[
                const SizedBox(height: AppDimens.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amenities & Benefits',
                          style:
                              KTextStyle.poppins(fs: 14, fw: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _AmenitiesGrouped(amenities: _amenities),
                    ],
                  ),
                ),
              ],
              if (isApplied) ...[
                const SizedBox(height: AppDimens.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vendor contact',
                          style: KTextStyle.poppins(fs: 14, fw: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.business_outlined, text: job['company'] ?? ''),
                      const SizedBox(height: 8),
                      if (contactUnlocked) ...[
                        _InfoRow(
                            icon: Icons.phone_android_outlined,
                            text: (job['vendorPhone'] ?? '').toString().isNotEmpty
                                ? job['vendorPhone']
                                : 'Not shared'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.location_on_outlined,
                            text: job['location'] ?? ''),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                size: 16, color: AppColors.textHint),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Contact number vendor ke confirm karne ke baad hi dikhega.',
                                style: KTextStyle.poppins(
                                    fs: 12, c: AppColors.textHint),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      // ── Fixed bottom action button (scroll nahi hota) ─────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum:
              const EdgeInsets.fromLTRB(AppDimens.lg, 10, AppDimens.lg, 10),
          child: isApplied
              ? CustomButton(
                  label: _appliedButtonLabel(appStatus), onTap: null)
              : Obx(() => CustomButton(
                    label: 'Apply for this job',
                    isLoading: _applying.value,
                    onTap: _applyDirect,
                  )),
        ),
      ),
    );
  }
}

// ── Job action chip (Like / Questions) ─────────────────────────────
class _JobAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _JobAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: KTextStyle.poppins(
                  fs: 12, fw: FontWeight.w500, c: color)),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
        ),
      ),
    ],
  );
}

// ── Amenities grouped by category (Financial / Travel / ...) ─────────
class _AmenitiesGrouped extends StatelessWidget {
  final List<JobAmenity> amenities;
  const _AmenitiesGrouped({required this.amenities});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<JobAmenity>> grouped = {};
    for (final a in amenities) {
      final cat = (a.category ?? '').trim().isEmpty ? 'Other' : a.category!.trim();
      grouped.putIfAbsent(cat, () => []).add(a);
    }
    final cats = grouped.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cats.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(cats[i],
              style: KTextStyle.poppins(
                  fs: 12, fw: FontWeight.w600, c: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grouped[cats[i]]!
                .map((a) => _AmenityChip(amenity: a))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final JobAmenity amenity;
  const _AmenityChip({required this.amenity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMax),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(amenity.icon ?? '•', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(amenity.name ?? '',
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500)),
        ],
      ),
    );
  }
}

String _cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _DetailPill extends StatelessWidget {
  final String label;
  final String value;
  const _DetailPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
