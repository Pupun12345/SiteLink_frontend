import 'package:get/get.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  JOB APPLICANTS CONTROLLER — GET /jobs/:id/applicants + confirm/reject
// ═══════════════════════════════════════════════════════════════════
class JobApplicantsController extends GetxController {
  final String jobId;
  JobApplicantsController(this.jobId);

  final _jobsApi = JobsApiService();

  final applicants = <JobApplicant>[].obs;
  final isLoading  = false.obs;
  final actioningId = RxnString(); // jis applicant pe confirm/reject chal raha hai

  @override
  void onInit() {
    super.onInit();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    isLoading.value = true;
    try {
      final res = await _jobsApi.getApplicants(jobId);
      if (res.success) {
        applicants.assignAll(res.data);
      } else if ((res.message ?? '').isNotEmpty) {
        AppSnackbar.error(message: res.message!);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmApplicant(JobApplicant a) =>
      _updateStatus(a, 'confirmed', 'confirmed');

  Future<void> rejectApplicant(JobApplicant a) =>
      _updateStatus(a, 'rejected', 'rejected');

  Future<void> _updateStatus(
      JobApplicant a, String newStatus, String verb) async {
    final id = a.applicationId;
    if (id == null || actioningId.value != null) return;

    actioningId.value = id;
    final idx = applicants.indexWhere((x) => x.applicationId == id);
    final previous = idx != -1 ? applicants[idx] : null;

    // Optimistic update
    if (idx != -1) {
      applicants[idx] = _withStatus(a, newStatus);
    }

    final res = await _jobsApi.updateApplicantStatus(jobId, id, newStatus);
    actioningId.value = null;

    if (res.success) {
      AppSnackbar.success(
          message: res.message ?? '${a.name ?? 'Worker'} $verb');
    } else {
      if (idx != -1 && previous != null) applicants[idx] = previous; // revert
      AppSnackbar.error(message: res.message ?? 'Update nahi hua');
    }
  }

  JobApplicant _withStatus(JobApplicant a, String status) => JobApplicant(
        applicationId: a.applicationId,
        workerId: a.workerId,
        name: a.name,
        profileImage: a.profileImage,
        primarySkill: a.primarySkill,
        skills: a.skills,
        totalExperience: a.totalExperience,
        phone: a.phone,
        workCity: a.workCity,
        workState: a.workState,
        isVerified: a.isVerified,
        rating: a.rating,
        coverLetter: a.coverLetter,
        experienceNote: a.experienceNote,
        status: status,
        appliedAt: a.appliedAt,
      );
}
