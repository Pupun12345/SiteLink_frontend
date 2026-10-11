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
      // Per-role breakdown — card chips aur detail list dono isi se.
      'roles': j.roles,
      'duration': j.duration ?? '',
      // Kaam kab shuru hoga — vendor ki chuni hui date. Pehle yahan
      // galti se `postedAt` (job kab post hui) bhara jaata tha, isliye
      // worker ko "Start" ke naam par posting date dikhti thi.
      'startDate': j.startDate != null
          ? DateFormat('d MMM yyyy').format(j.startDate!)
          : '',
      // Posting date alag key me — "Posted 2 days ago" jaisi jagah ke liye.
      'postedAt': j.postedAt != null
          ? DateFormat('d MMM yyyy').format(j.postedAt!)
          : '',
      'urgent': j.isUrgent,
      'notes': j.description, // list me null; detail fetch par bharta hai
      // Backend ab GET /api/jobs me bhi worker ki apni application ka status
      // bhejta hai (agar apply kar chuka ho) — isse Available list/detail
      // dono me "Applied" sahi se dikhta hai, na sirf "Applied" tab me.
      if (j.hasApplied) 'appStatus': j.applicationStatus!.toLowerCase(),
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
      'roles': j?.roles ?? const <JobRole>[],
      // Kaam ki start date — `dates` (apply kab kiya) se alag cheez hai.
      'startDate': j?.startDate != null
          ? DateFormat('d MMM yyyy').format(j!.startDate!)
          : '',
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
