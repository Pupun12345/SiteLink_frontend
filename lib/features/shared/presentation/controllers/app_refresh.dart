import 'package:get/get.dart';

import '../../../vendor/presentation/controllers/vendor_jobs_controller.dart';
import '../../../vendor/presentation/controllers/vendor_profile_controller.dart';
import '../../../worker/presentation/controllers/worker_myjob_controller.dart';
import '../../../worker/presentation/controllers/worker_profile_controller.dart';
import '../../../worker/presentation/views/worker_setting_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  APP REFRESH — mutation ke baad doosri screens ka data taaza karo
// ═══════════════════════════════════════════════════════════════════
// Problem jo ye solve karta hai: ek screen par kuch badalta hai (post
// bani, job post hui, plan liya) aur doosri screen purana data dikhati
// rehti hai — user ko manually pull-to-refresh karna padta hai.
//
// Refresh ko MUTATION ki jagah se trigger karte hain, screen kholne wali
// jagah se nahi. Warna har naye entry point par refresh dobara likhna
// padta hai aur ek na ek jagah chhoot jaata hai (jaise "New Request"
// teen jagah se khulti thi par sirf ek hi list refresh karti thi).
//
// Har helper pehle `isRegistered` check karta hai — jo tab kabhi khola
// hi nahi gaya, uska controller memory me nahi hota, aur usko refresh
// karne ki zaroorat bhi nahi (khulte waqt khud fetch karega).

/// Post bani ya delete hui → Profile tab ka posts list + count.
///
/// Dono roles handle karta hai; jo registered hoga wahi refresh hoga.
///
/// NOTE: `fetchProfile()` kaafi NAHI hai — posts aur unka count alag
/// endpoint (`GET /community/posts/mine`) se aate hain. Pehle sirf
/// `fetchProfile()` bulaya jaata tha, isliye post banane ke baad bhi
/// Profile par count 0 hi dikhta rehta tha.
Future<void> refreshProfilePosts() async {
  final futures = <Future<void>>[];
  if (Get.isRegistered<WorkerProfileController>()) {
    futures.add(Get.find<WorkerProfileController>().fetchMyPosts());
  }
  if (Get.isRegistered<VendorProfileController>()) {
    futures.add(Get.find<VendorProfileController>().fetchMyPosts());
  }
  await Future.wait(futures);
}

/// Vendor ne job post/deactivate ki → uski jobs list aur worker quota.
///
/// Quota bhi isi response me aata hai, isliye ek hi fetch se list aur
/// "is mahine kitne workers bache" dono theek ho jaate hain.
Future<void> refreshVendorJobs() async {
  if (Get.isRegistered<VendorJobsController>()) {
    await Get.find<VendorJobsController>().fetchMyJobs();
  }
}

/// Worker ne job par apply kiya → uski "Applied" list.
Future<void> refreshWorkerAppliedJobs() async {
  if (Get.isRegistered<MyJobsController>()) {
    await Get.find<MyJobsController>().fetchAppliedJobs();
  }
}

/// Plan khareeda/renew hua → wo sab jo plan par depend karta hai.
///
/// Isme sirf list nahi, FEATURE LOCKS bhi aate hain: Contact Support ka
/// lock `hasActivePlan` par chalta hai, aur vendor ka job quota plan ke
/// `maxWorkers` par. Plan lene ke baad wapas aate hi ye khul jaane
/// chahiye, warna user ko lagta hai paisa dene par bhi kuch nahi hua.
Future<void> refreshAfterPlanChange() async {
  final futures = <Future<void>>[];
  if (Get.isRegistered<WorkerProfileController>()) {
    futures.add(Get.find<WorkerProfileController>().fetchProfile());
  }
  if (Get.isRegistered<VendorProfileController>()) {
    futures.add(Get.find<VendorProfileController>().fetchProfile());
  }
  if (Get.isRegistered<VendorJobsController>()) {
    futures.add(Get.find<VendorJobsController>().fetchMyJobs());
  }
  // Settings screen apna plan status alag rakhti hai (Contact Support ka
  // lock isi se chalta hai) — usko bhi bata do.
  if (Get.isRegistered<WorkerSettingsController>()) {
    futures.add(Get.find<WorkerSettingsController>().loadPlanStatus());
  }
  await Future.wait(futures);
}
