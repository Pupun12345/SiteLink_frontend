import 'package:get/get.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR JOBS CONTROLLER — apne posted jobs (GET /api/jobs/my)
// ═══════════════════════════════════════════════════════════════════
// /api/jobs (public list) sirf approved jobs deta hai — vendor ki apni
// pending/rejected job usme kabhi nahi dikhti. /api/jobs/my server-side
// hi caller ki saari jobs (kisi bhi approvalStatus ki) deta hai, isliye
// client-side postedBy filter ki zaroorat nahi rahi.
class VendorJobsController extends GetxController {
  final _jobsApi = JobsApiService();

  final jobs      = <JobModel>[].obs;
  final isLoading = false.obs;
  final quota     = Rxn<WorkerQuota>();

  @override
  void onInit() {
    super.onInit();
    fetchMyJobs();
  }

  Future<void> fetchMyJobs() async {
    isLoading.value = true;
    try {
      final res = await _jobsApi.getMyJobs();
      if (res.success) {
        final mine = res.data.toList()
          ..sort((a, b) => (b.postedAt ?? DateTime(2000))
              .compareTo(a.postedAt ?? DateTime(2000)));
        jobs.assignAll(mine);
        quota.value = res.quota;
      } else {
        AppSnackbar.error(message: res.message ?? 'Jobs load nahi hue');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Job deactivate — DELETE /jobs/:id ab soft-deactivate karta hai (job
  /// list me "Deactivated" badge ke saath rehta hai, quota me count hota
  /// rehta hai). Success par refetch taaki badge + quota dono update ho.
  Future<void> deleteJob(String jobId) async {
    final res = await _jobsApi.deleteJob(jobId);
    if (res.success) {
      AppSnackbar.success(message: 'Job deactivated');
      await fetchMyJobs();
    } else {
      AppSnackbar.error(message: res.message ?? 'Deactivate nahi hua');
    }
  }
}
