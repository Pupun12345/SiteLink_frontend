import 'package:get/get.dart';
import '../../../../core/models/community_feed_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/locale_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER PROFILE CONTROLLER
// ═══════════════════════════════════════════════════════════════════
// name / primarySkill / location / skills ab /api/profile/me se aate hain.
// Jo fields API nahi deta (phone, experience, stats, documents) wo abhi
// mock/default hain.
class WorkerProfileController extends GetxController {
  final _profileApi = ProfileApiService();
  final isLoading = false.obs;

  // ── From API ────────────────────────────────────────────────────
  final name         = ''.obs;
  final initials     = ''.obs;
  final email        = ''.obs;
  final primarySkill = ''.obs;
  final location     = ''.obs;
  final skills       = <String>[].obs;
  final profileImage = ''.obs;
  final posts        = <CommunityFeedModel>[].obs; // user ke apne posts
  final postsCount   = 0.obs;

  // ── Mock / default (API me abhi available nahi) ──────────────────
  final workerId     = 'SL-WRK-2024-004'.obs;
  final phone        = '+91 98765 43210'.obs;
  final experience   = '—'.obs; // ✅ ab API se aata hai (totalExperience)
  final isVerified   = false.obs; // ✅ ab API se aata hai (mock true nahi)
  final totalJobs     = 12.obs;
  final completedJobs = 11.obs;
  final rating        = 4.6.obs;
  final documents = <Map<String, dynamic>>[
    {'label': 'Aadhaar Card',           'verified': true},
    {'label': 'Work Experience Letter', 'verified': true},
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final res = await _profileApi.getMe();
      final u = res.user;
      if (res.success && u != null) {
        if ((u.name ?? '').isNotEmpty) {
          name.value = u.name!;
          initials.value = _initials(u.name!);
        }
        if ((u.primarySkill ?? '').isNotEmpty) primarySkill.value = u.primarySkill!;
        if (u.totalExperience != null) {
          final yrs = u.totalExperience!;
          final isWhole = yrs == yrs.roundToDouble();
          experience.value =
              '${isWhole ? yrs.toInt() : yrs} ${yrs == 1 ? 'yr' : 'yrs'}';
        }
        if (u.locationLabel.isNotEmpty) location.value = u.locationLabel;
        if (u.skills.isNotEmpty) skills.assignAll(u.skills);
        profileImage.value = u.profileImage ?? '';
        email.value = u.email ?? '';
        isVerified.value = u.isVerified; // real key se — pending par false
        posts.assignAll(u.posts);
        postsCount.value = u.posts.length;
        // Server-side language preference restore (cross-device).
        LocaleService.to.applyFromProfile(u.language);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete ke baad local list se hata do (UI turant update).
  void removePostLocally(String? id) {
    if (id == null) return;
    posts.removeWhere((p) => p.id == id);
    postsCount.value = posts.length;
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
