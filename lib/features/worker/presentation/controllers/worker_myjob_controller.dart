import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/services/api_client.dart';

// ═══════════════════════════════════════════════════════════════════
//  MY JOBS CONTROLLER
// ═══════════════════════════════════════════════════════════════════
// "Available" → /api/jobs ; "Applied/Assigned" → /api/jobs/getAppliedJobs.
// Dono ko UI Map shape me map karte hain taaki existing cards/filters
// unchanged rahein.
class MyJobsController extends GetxController {
  final _jobsApi = JobsApiService();

  final isLoading = false.obs;         // available
  final isLoadingApplied = false.obs;  // applied

  final availableJobs = <Map<String, dynamic>>[].obs;
  final appliedJobs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
    fetchAppliedJobs();
  }

  // ── Available jobs (vendor-posted, open to apply) ──────────────────
  Future<void> fetchJobs() async {
    isLoading.value = true;
    try {
      final res = await _jobsApi.getJobs();
      if (res.success) {
        availableJobs.value = res.data.map(_jobToMap).toList();
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ── Applied / Assigned jobs ────────────────────────────────────────
  Future<void> fetchAppliedJobs() async {
    isLoadingApplied.value = true;
    try {
      final res = await _jobsApi.getAppliedJobs();
      if (res.success) {
        appliedJobs.value = res.data.map(_appliedToMap).toList();
      }
    } finally {
      isLoadingApplied.value = false;
    }
  }

  String _rate(JobModel j, bool isDaily) =>
      j.salary != null ? '₹${j.salary}/${isDaily ? 'day' : 'month'}' : '';

  /// JobModel → UI Map (Available card shape).
  Map<String, dynamic> _jobToMap(JobModel j) {
    final isDaily = (j.salaryType ?? '').toLowerCase() == 'daily';
    return {
      'apiId': j.id, // detail fetch ke liye real id
      'id': j.id ?? '',
      'type': isDaily ? 'daily' : 'permanent',
      'role': j.title ?? '',
      'company': j.companyName,
      'location': j.location ?? '',
      'lat': j.latitude,
      'lng': j.longitude,
      'rate': _rate(j, isDaily),
      'workers': j.workersCount,
      'duration': j.duration ?? '',
      'startDate': j.postedAt != null
          ? DateFormat('d MMM yyyy').format(j.postedAt!)
          : '',
      'urgent': j.isUrgent,
      'notes': j.description, // list me null; detail fetch par bharta hai
    };
  }

  /// AppliedJobModel → UI Map (Applied card shape).
  Map<String, dynamic> _appliedToMap(AppliedJobModel a) {
    final j = a.job;
    final isDaily = (j?.salaryType ?? '').toLowerCase() == 'daily';
    return {
      'apiId': j?.id,
      'id': a.id ?? '',
      'type': isDaily ? 'daily' : 'permanent',
      'role': j?.title ?? '',
      'company': j?.companyName ?? '',
      'location': j?.location ?? '',
      'lat': j?.latitude,
      'lng': j?.longitude,
      'rate': j != null ? _rate(j, isDaily) : '',
      'workers': j?.workersCount ?? 0,
      'dates': a.createdAt != null
          ? 'Applied ${DateFormat('d MMM yyyy').format(a.createdAt!)}'
          : '',
      // Real backend status seedha UI me — pending/shortlisted/confirmed/
      // rejected/hired. Vendor contact gate + status badge dono isi se drive.
      'appStatus': (a.status ?? 'pending').toLowerCase(),
      'notes': (a.coverLetter?.isNotEmpty ?? false)
          ? a.coverLetter
          : j?.description,
    };
  }
}
