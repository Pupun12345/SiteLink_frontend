import 'package:get/get.dart';
import '../../../../core/models/community_feed_models.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/services/session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR PROFILE CONTROLLER — GET /api/profile/me (vendor-shaped)
// ═══════════════════════════════════════════════════════════════════
class VendorProfileController extends GetxController {
  final _profileApi   = ProfileApiService();
  final _jobsApi      = JobsApiService();
  final _communityApi = CommunityApiService();

  final isLoading = true.obs;
  final profile   = Rxn<MyProfile>();

  // Stats
  final myJobsCount   = 0.obs;
  final activeJobsCount = 0.obs;

  // Community feed — vendor apne bhi posts karta hai (same shared feed
  // jo worker use karta hai), isliye "My Posts" yahan bhi dikhta hai.
  // Dedicated endpoint (GET /community/posts/mine) — /profile/me se
  // decouple, taaki apni saari posts dikhein (koi approval/isActive filter
  // nahi) bina profile fetch ko bhaari kiye.
  final posts        = <CommunityFeedModel>[].obs;
  final postsCount    = 0.obs;
  final isLoadingPosts = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    fetchMyPosts();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final res = await _profileApi.getMe();
      if (res.success && res.user != null) {
        profile.value = res.user;
        // Server-side language preference restore (cross-device).
        LocaleService.to.applyFromProfile(res.user!.language);
      }
      await _loadJobStats();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMyPosts() async {
    isLoadingPosts.value = true;
    try {
      final res = await _communityApi.getMyPosts();
      if (res.success ?? false) {
        posts.assignAll(res.data ?? const []);
        postsCount.value = posts.length;
      }
    } finally {
      isLoadingPosts.value = false;
    }
  }

  /// Pull-to-refresh — profile + posts dono ek saath.
  Future<void> refreshAll() => Future.wait([fetchProfile(), fetchMyPosts()]);

  /// Delete ke baad local list se hata do (UI turant update).
  void removePostLocally(String? id) {
    if (id == null) return;
    posts.removeWhere((p) => p.id == id);
    postsCount.value = posts.length;
  }

  /// Apne posted jobs count (getJobs → own filter).
  Future<void> _loadJobStats() async {
    try {
      final myId = SessionService.to.userId;
      final res = await _jobsApi.getJobs();
      if (res.success) {
        final mine =
            res.data.where((j) => j.postedBy?.id == myId).toList();
        myJobsCount.value = mine.length;
        activeJobsCount.value = mine.length; // sab active/approved
      }
    } catch (_) {/* stats optional */}
  }
}
