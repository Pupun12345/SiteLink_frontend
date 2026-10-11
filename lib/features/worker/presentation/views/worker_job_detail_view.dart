import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/post_share_service.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/job_roles_view.dart';
import '../../../../core/utils/amenity_category_label.dart';
import '../controllers/worker_myjob_controller.dart';
import '../../../../core/services/review_service.dart';
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
        // Shared deep link se aane par map me sirf `apiId` hota hai —
        // baaki sab yahin bharta hai, warna screen khaali dikhti.
        if ((job['role'] ?? '').toString().isEmpty) {
          job['role'] = detail.title ?? '';
        }
        if ((job['location'] ?? '').toString().isEmpty) {
          job['location'] = detail.location ?? '';
        }
        if ((job['type'] ?? '').toString().isEmpty) {
          job['type'] = (detail.salaryType ?? '').toLowerCase() == 'daily'
              ? 'daily'
              : 'permanent';
        }
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
        // Detail response me roles list list-response se zyada bharosemand
        // hai (shared deep link se aaye ho to map khaali hota hai).
        if (detail.roles.isNotEmpty) job['roles'] = detail.roles;
        // Shared deep link se aaye ho to map khaali hota hai — detail se bharo.
        if (detail.startDate != null) {
          job['startDate'] = DateFormat('d MMM yyyy').format(detail.startDate!);
        }
        // Backend sirf tabhi bhejta hai jab application confirm/hire ho
        // chuki ho — warna null aata hai (contact locked dikhta hai).
        // Vendor ka `phone` worker tak aata hi nahi, isliye yahan sirf
        // WhatsApp number rakha jaata hai.
        job['vendorWhatsapp'] = detail.postedBy?.whatsappNumber;
        // Detail fetch se latest applied-status bhi le lo — Available list
        // se khula ho to bhi ab sahi "Applied" state dikhegi.
        if (detail.hasApplied) {
          job['appStatus'] = detail.applicationStatus!.toLowerCase();
        }
        _amenities = detail.amenities;
      }
      _loadingDetail = false;
    });
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
      if (!ok) AppSnackbar.error(message: 'map_open_failed'.tr);
    } catch (_) {
      AppSnackbar.error(message: 'map_open_failed'.tr);
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

  /// "Apply for this job" — apply FREE hai, koi plan zaroori nahi.
  /// Sirf account verified hona chahiye.
  Future<void> _applyDirect() async {
    if (_applying.value) return; // double-tap guard
    final apiId = job['apiId'] as String?;
    if (apiId == null || apiId.isEmpty) {
      AppSnackbar.error(message: 'job_id_missing_error'.tr);
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
      // Apply ho gaya — rating maangne ka achha moment. Celebration
      // screen khulne ke baad maangte hain taaki dono ek doosre ke
      // upar na aayein. Service khud dekh leti hai ki pehle maang
      // chuke hain ya nahi.
      ReviewService.maybeAsk();
    } else {
      AppSnackbar.error(message: res.message ?? 'apply_failed_generic'.tr);
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
              Text('verification_pending_title'.tr,
                  style: KTextStyle.poppins(fs: 18, fw: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                'verification_pending_body'.tr,
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
                        'verification_pending_note'.tr,
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
                child: CustomButton(label: 'got_it_label'.tr, onTap: () => Get.back()),
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
        return StatusBadge(type: BadgeType.pending, customLabel: 'status_under_review'.tr);
      case 'shortlisted':
        return StatusBadge(type: BadgeType.active, customLabel: 'status_shortlisted'.tr);
      case 'confirmed':
        return StatusBadge(type: BadgeType.verified, customLabel: 'status_confirmed'.tr);
      case 'hired':
        return StatusBadge(type: BadgeType.verified, customLabel: 'status_hired'.tr);
      case 'rejected':
        return StatusBadge(type: BadgeType.rejected, customLabel: 'status_rejected'.tr);
      case null:
        return StatusBadge(type: BadgeType.fulfilled, customLabel: 'status_available'.tr);
      default:
        return StatusBadge(type: BadgeType.pending, customLabel: 'status_applied'.tr);
    }
  }

  String _appliedButtonLabel(String? appStatus) {
    switch (appStatus) {
      case 'shortlisted':
        return 'applied_btn_shortlisted'.tr;
      case 'confirmed':
        return 'applied_btn_confirmed'.tr;
      case 'hired':
        return 'applied_btn_hired'.tr;
      case 'rejected':
        return 'applied_btn_rejected'.tr;
      default:
        return 'applied_btn_default'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 'appStatus' — Applied tab se ho ya Available tab se (backend GET
    // /api/jobs / /api/jobs/:id ab worker ki apni application ka status bhi
    // bhejta hai agar already apply kar chuka ho) — dono jagah se sahi set
    // hota hai (real backend Application.status: pending/shortlisted/confirmed/rejected/hired).
    final appStatus = (job['appStatus'] as String?)?.toLowerCase();
    final isApplied = appStatus != null;
    final contactUnlocked = appStatus == 'confirmed' || appStatus == 'hired';
    final jobType = (job['type'] as String?) ?? 'daily';
    final title = job['role'] ?? 'job_fallback_title'.tr;
    final company = job['company'] ?? '';
    final location = job['location'] ?? '';
    final rate = job['rate'] ?? '';
    final duration = jobType == 'permanent'
        ? 'permanent_employment_label'.tr
        : job['duration'] ?? '';
    final startDate = job['startDate'] ?? job['dates'] ?? '';
    final workers = job['workers'] != null
        ? 'workers_count_suffix'.trParams({'count': '${job['workers']}'})
        : '';
    final experience = (job['experience'] ?? '').toString();
    final lat = (job['lat'] ?? '').toString();
    final lng = (job['lng'] ?? '').toString();
    final hasCoords = lat.isNotEmpty && lng.isNotEmpty;
    final isUrgent = job['isUrgent'] == true;
    final salaryType = (job['salaryType'] ?? '').toString();
    final statusBadge = _appStatusBadge(appStatus);
    // Purani jobs (structured roles se pehle) me khaali — card hide ho jaata hai.
    final roles = (job['roles'] as List?)?.whereType<JobRole>().toList() ??
        const <JobRole>[];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: 'job_details_title'.tr,
        actions: [
          Builder(
            // Builder isliye ki share sheet ko is icon ka rect chahiye
            // (iPad anchor), Scaffold ke context ka nahi.
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'share_label'.tr,
              onPressed: () => shareJob(
                ctx,
                jobId: job['apiId'] as String?,
                title: job['role']?.toString(),
                company: job['company']?.toString(),
                location: job['location']?.toString(),
                pay: job['rate']?.toString(),
              ),
            ),
          ),
        ],
      ),
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
                            Text('urgent_hiring_label'.tr,
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
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              if (hasCoords) ...[
                Obx(() => CustomButton(
                      label: 'get_directions_label'.tr,
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
                        Text('contract_details_label'.tr,
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
                    _DetailPill(label: 'type_label'.tr, value: jobType == 'permanent' ? 'permanent_label'.tr : 'daily_wage_label'.tr),
                    const SizedBox(height: 8),
                    _DetailPill(label: AppStrings.Duration, value: duration),
                    const SizedBox(height: 8),
                    _DetailPill(label: 'pay_label'.tr, value: rate),
                    if (salaryType.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailPill(label: AppStrings.SalaryType, value: _cap(salaryType)),
                    ],
                    if (experience.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailPill(label: 'experience_label'.tr, value: '$experience ${'yr_plural'.tr}'),
                    ],
                    // Purani jobs me start date nahi hoti — pill hi na dikhao,
                    // khaali value dikhane se lagta hai data gayab hai.
                    if (startDate.toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailPill(label: 'start_label'.tr, value: startDate),
                    ],
                    if (job['notes'] != null) ...[
                      const SizedBox(height: 12),
                      Text(AppStrings.Description, style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('${job['notes']}', style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              // Kaun-kaun se role aur kitne — pehle ye title me "+3 more"
              // ban jaata tha aur breakdown description me dab jaata tha.
              if (roles.isNotEmpty) ...[
                const SizedBox(height: AppDimens.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('roles_required_label'.tr,
                          style:
                              KTextStyle.poppins(fs: 14, fw: FontWeight.w700)),
                      const SizedBox(height: 12),
                      JobRolesBreakdown(roles: roles),
                    ],
                  ),
                ),
              ],
              if (_amenities.isNotEmpty) ...[
                const SizedBox(height: AppDimens.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('amenities_benefits_label'.tr,
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
                      Text('vendor_contact_label'.tr,
                          style: KTextStyle.poppins(fs: 14, fw: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.business_outlined, text: job['company'] ?? ''),
                      const SizedBox(height: 8),
                      if (contactUnlocked) ...[
                        // Sirf WhatsApp — vendor ka personal/login number
                        // worker ko kabhi nahi dikhta. Backend bhi wahi
                        // bhejta hai, yahan uska koi fallback nahi hai.
                        Builder(builder: (_) {
                          final wa =
                              (job['vendorWhatsapp'] ?? '').toString().trim();
                          if (wa.isEmpty) {
                            return _InfoRow(
                                icon: Icons.chat_outlined,
                                text: 'not_shared_label'.tr);
                          }
                          return _WhatsAppRow(number: wa);
                        }),
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
                                'contact_locked_note'.tr,
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
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(AppDimens.lg, 10, AppDimens.lg, 10),
            child: isApplied
                ? CustomButton(
                    label: _appliedButtonLabel(appStatus), onTap: null)
                : Obx(() => CustomButton(
                      label: 'apply_for_job_btn'.tr,
                      isLoading: _applying.value,
                      onTap: _applyDirect,
                    )),
          ),
        ),
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

// ── Vendor ka WhatsApp — tap karne pe seedha chat khulti hai ─────────
// Worker ko vendor ka asli number kabhi nahi dikhta; yahi ek contact
// channel hai jo vendor apni profile me khud deta hai.
class _WhatsAppRow extends StatelessWidget {
  final String number;
  const _WhatsAppRow({required this.number});

  Future<void> _open() async {
    // wa.me ko country code chahiye — vendor 10 digit hi bharta hai.
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    final msisdn = digits.length == 10 ? '91$digits' : digits;
    try {
      final ok = await launchUrl(Uri.parse('https://wa.me/$msisdn'),
          mode: LaunchMode.externalApplication);
      if (!ok) AppSnackbar.error(message: 'whatsapp_open_failed'.tr);
    } catch (_) {
      AppSnackbar.error(message: 'whatsapp_open_failed'.tr);
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: _open,
        child: Row(
          children: [
            const Icon(Icons.chat_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                number,
                style: KTextStyle.poppins(
                    fs: 12,
                    fw: FontWeight.w600,
                    c: AppColors.primary),
              ),
            ),
            Text(
              AppStrings.WhatsApp,
              style: KTextStyle.poppins(fs: 11, c: AppColors.textHint),
            ),
          ],
        ),
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
      final cat = (a.category ?? '').trim().isEmpty ? AppStrings.Other : a.category!.trim();
      grouped.putIfAbsent(cat, () => []).add(a);
    }
    final cats = grouped.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cats.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(amenityCategoryLabel(cats[i]),
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
