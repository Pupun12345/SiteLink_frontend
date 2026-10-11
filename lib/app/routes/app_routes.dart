/// ═══════════════════════════════════════════════════════════════════
///  APP ROUTES — route name constants (named navigation ke liye)
/// ═══════════════════════════════════════════════════════════════════
/// Inline `Get.to(() => View())` ki jagah `Get.toNamed(AppRoutes.x)`.
abstract class AppRoutes {
  AppRoutes._();

  // Auth flow
  static const splash = '/splash';
  static const language = '/language';
  static const phone = '/phone';
  static const otp = '/otp';
  static const role = '/role';

  // Vendor
  static const vendorHome = '/vendor/home';
  static const vendorRegistration = '/vendor/registration';
  static const newRequest = '/vendor/new-request';
  static const myRequests = '/vendor/my-requests';
  static const requestDetail = '/vendor/request-detail';
  static const rateWorker = '/vendor/rate-worker';

  /// Shared deep link (`sitelink://post/<id>` ya `/p/<id>`) yahan khulta hai
  static const postDetail = '/post';
  static const replacementRequest = '/vendor/replacement-request';

  // Worker
  static const workerHome = '/worker/home';
  static const workerReg1 = '/worker/reg/step1';
  static const workerReg2 = '/worker/reg/step2';
  static const workerReg3 = '/worker/reg/step3';
  static const documentUpload = '/worker/reg/documents';
  static const profilePending = '/worker/profile-pending';
  static const workerSettings = '/worker/settings';
  static const workerJobDetail = '/worker/job-detail';
  static const activeJob = '/worker/active-job';
  static const jobOffer = '/worker/job-offer';

  // Shared
  static const help = '/help';
}
