import 'package:get/get.dart';

import '../../features/auth/presentation/controllers/auth_controllers.dart';
import '../../features/auth/presentation/views/auth_views.dart';
import '../../features/auth/presentation/views/language_view.dart';
import '../../features/auth/presentation/views/splash_view.dart';
import '../../features/shared/presentation/views/shared_views.dart';
import '../../features/vendor/presentation/views/my_requests_view.dart';
import '../../features/vendor/presentation/views/new_request_view.dart';
import '../../features/vendor/presentation/views/rate_worker_view.dart';
import '../../features/vendor/presentation/views/replacement_request_view.dart';
import '../../features/vendor/presentation/views/vendor_home_view.dart';
import '../../features/vendor/presentation/views/vendor_reg_view.dart';
import '../../features/worker/presentation/views/active_job_view.dart';
import '../../features/worker/presentation/views/job_offer_view.dart';
import '../../features/worker/presentation/views/worker_home_view.dart';
import '../../features/worker/presentation/views/worker_reg_views.dart';
import '../../features/worker/presentation/views/worker_setting_view.dart';
import '../../features/shared/presentation/views/post_detail_view.dart';
import '../../features/worker/presentation/views/worker_job_detail_view.dart';
import 'app_routes.dart';

// ═══════════════════════════════════════════════════════════════════
//  APP PAGES — named routes + per-route bindings
// ═══════════════════════════════════════════════════════════════════
// Auth routes apne controllers lazyPut karte hain (clean DI). Worker/vendor
// views abhi apna Get.put khud karte hain (incremental migration), isliye
// un routes pe binding optional hai.
class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    // ── Auth ──────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SplashController>(() => SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.language,
      page: () => const LanguageView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LanguageController>(() => LanguageController());
      }),
    ),
    GetPage(
      name: AppRoutes.phone,
      page: () => const PhoneView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PhoneController>(() => PhoneController());
        Get.lazyPut<GoogleAuthController>(() => GoogleAuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<OtpController>(() => OtpController());
      }),
    ),
    GetPage(
      name: AppRoutes.role,
      page: () => const RoleSelectionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<RoleController>(() => RoleController());
      }),
    ),

    // ── Vendor (views self-Get.put for now) ─────────────────────────────
    GetPage(name: AppRoutes.vendorHome, page: () => const VendorHomeView()),
    GetPage(
        name: AppRoutes.vendorRegistration,
        page: () => const VendorRegistrationView()),
    GetPage(name: AppRoutes.newRequest, page: () => const NewRequestView()),
    GetPage(name: AppRoutes.myRequests, page: () => const MyRequestsView()),
    GetPage(name: AppRoutes.rateWorker, page: () => const RateWorkerView()),
    GetPage(name: AppRoutes.postDetail, page: () => const PostDetailView()),
    // Shared job link yahan khulta hai. Arguments me sirf `apiId` aata
    // hai — screen baaki detail khud API se bhar leti hai.
    GetPage(
      name: AppRoutes.workerJobDetail,
      page: () => WorkerJobDetailView(
        job: Map<String, dynamic>.from(
            (Get.arguments as Map?) ?? const <String, dynamic>{}),
      ),
    ),
    GetPage(
        name: AppRoutes.replacementRequest,
        page: () => const ReplacementRequestView()),

    // ── Worker (views self-Get.put for now) ─────────────────────────────
    GetPage(name: AppRoutes.workerHome, page: () => const WorkerHomeView()),
    GetPage(name: AppRoutes.workerReg1, page: () => const WorkerReg1View()),
    GetPage(name: AppRoutes.workerReg2, page: () => const WorkerReg2View()),
    GetPage(name: AppRoutes.workerReg3, page: () => const WorkerReg3View()),
    GetPage(
        name: AppRoutes.documentUpload,
        page: () => const DocumentUploadView()),
    GetPage(
        name: AppRoutes.profilePending,
        page: () => const ProfilePendingView()),
    GetPage(
        name: AppRoutes.workerSettings,
        page: () => const WorkerSettingsView()),
    GetPage(name: AppRoutes.activeJob, page: () => const ActiveJobView()),
    GetPage(name: AppRoutes.jobOffer, page: () => const JobOfferView()),

    // ── Shared ──────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.help, page: () => const HelpView()),
  ];
}
