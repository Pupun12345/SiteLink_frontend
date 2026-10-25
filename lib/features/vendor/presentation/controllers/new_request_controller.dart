import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../views/vendor_plans_view.dart';
import '../../../shared/presentation/controllers/app_refresh.dart';
import '../../../../core/services/review_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  NEW REQUEST (CREATE JOB) — POST /api/jobs (verified vendor only)
// ═══════════════════════════════════════════════════════════════════
// Required (backend): title, company, location, description,
//                     experience (0–60), quantity (>0), salary (≥0)
// Optional: salaryType (daily|weekly|monthly), isUrgent, duration,
//           latitude/longitude, amenities (numeric ids).
class NewRequestController extends GetxController {
  final _jobsApi      = JobsApiService();
  final _amenitiesApi = AmenitiesApiService();
  final _profileApi   = ProfileApiService();
  final _skillsApi    = SkillsApiService();

  final selectedRoles  = <String>[].obs;
  final quantities     = <String, int>{}.obs;

  // ── Role picker options — backend se (GET /profile/skills), hardcoded nahi ──
  final allSkills       = <String>[].obs;
  final isLoadingSkills = false.obs;
  final cityCtrl       = TextEditingController();
  final areaCtrl       = TextEditingController();
  /// Sirf display ke liye ("12 Sep 2026"). Backend ko bhejne ke liye
  /// [startDate] use karo — formatted string se date parse karna nazuk hai.
  final startDateCtrl  = TextEditingController();

  /// Picker se chuni gayi asli date. Backend ko ISO me jaati hai.
  final startDate = Rx<DateTime?>(null);
  final duration       = ''.obs;
  final customDurationCtrl = TextEditingController();
  final specialReqCtrl = TextEditingController();
  final isLoading      = false.obs;

  /// 'Custom' select hone par uske sath likha gaya text, warna dropdown value.
  String get effectiveDuration =>
      duration.value == 'Custom' ? customDurationCtrl.text.trim() : duration.value;

  // ── Pay & experience (backend required) ─────────────────────
  final salaryCtrl     = TextEditingController();
  final salaryType     = 'daily'.obs; // daily | weekly | monthly
  final experienceCtrl = TextEditingController();
  final isUrgent       = false.obs;

  // ── Amenities (grouped, multi-select) ────────────────────────
  final groupedAmenities = <String, List<JobAmenity>>{}.obs;
  final selectedAmenityIds = <int>[].obs;
  final amenitiesLoading = false.obs;

  // ── Site location (map picker) ───────────────────────────────
  final pickedLat = Rxn<String>();
  final pickedLng = Rxn<String>();

  void setPickedLocation(LatLng latLng) {
    pickedLat.value = latLng.latitude.toString();
    pickedLng.value = latLng.longitude.toString();
  }

  String _companyName = '';

  // Pre-fill from community feed "Hire" button
  final preFilledWorkerName = ''.obs;
  final preFilledWorkerId   = ''.obs;
  final preFilledSkill      = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAmenities();
    _loadCompany();
    _loadSkills();
  }

  /// Role picker options — GET /profile/skills. Same source as worker
  /// registration's skill picker, taaki dono jagah backend-managed list
  /// consistent rahe (pehle yahan hardcoded AppStrings.allSkills tha).
  Future<void> _loadSkills() async {
    isLoadingSkills.value = true;
    try {
      final res = await _skillsApi.getAllSkills();
      if (res.success) {
        allSkills.assignAll(res.data
            .map((s) => s.name ?? '')
            .where((n) => n.isNotEmpty));
      } else {
        AppSnackbar.error(message: res.message ?? 'roles_load_failed'.tr);
      }
    } finally {
      isLoadingSkills.value = false;
    }
  }

  /// Amenities list load/retry — grouped-by-category (backend se aata hai).
  Future<void> loadAmenities() async {
    amenitiesLoading.value = true;
    final grouped = await _amenitiesApi.getGrouped();
    groupedAmenities.assignAll(grouped);
    amenitiesLoading.value = false;
  }

  Future<void> _loadCompany() async {
    try {
      final res = await _profileApi.getMe();
      // Job par company ka naam jaata hai, vendor ka personal naam nahi.
      // Pehle yahan `user.name` padha jaata tha, isliye har job me vendor
      // ka apna naam save ho jaata tha aur job detail me building icon ke
      // saath usi ka naam dikhta tha.
      _companyName = res.user?.companyName?.trim() ?? '';
      // Company name na ho (profile adhoora) to naam par fallback — job
      // par `company` required hai, khaali nahi ja sakta.
      if (_companyName.isEmpty) _companyName = res.user?.name?.trim() ?? '';
    } catch (_) {}
    if (_companyName.isEmpty) _companyName = SessionService.to.userName;
  }

  void toggleAmenity(int? id) {
    if (id == null) return;
    if (selectedAmenityIds.contains(id)) {
      selectedAmenityIds.remove(id);
    } else {
      selectedAmenityIds.add(id);
    }
  }

  // Backend allowed categories
  static const amenityCategories = [
    'Financial Benefits',
    'Accommodation & Food',
    'Travel',
    'Safety & Medical',
    'Leave',
    'Work & Career',
    'Employee Rewards',
  ];

  /// Custom amenity add (POST /amenities) → list reload.
  Future<void> addCustomAmenity(String name, String category) async {
    if (name.trim().isEmpty) return;
    final res = await _amenitiesApi.addAmenity(name.trim(), category);
    if (res.success) {
      AppSnackbar.success(message: 'amenity_added_success'.tr);
      await loadAmenities();
    } else {
      AppSnackbar.error(message: res.message ?? 'amenity_add_failed'.tr);
    }
  }

  void prefillFromWorker({
    required String workerName,
    required String workerId,
    required String skill,
  }) {
    preFilledWorkerName.value = workerName;
    preFilledWorkerId.value   = workerId;
    preFilledSkill.value      = skill;
    if (!selectedRoles.contains(skill)) {
      selectedRoles.add(skill);
      quantities[skill] = 1;
    }
  }

  void incrementQty(String role) {
    quantities[role] = (quantities[role] ?? 1) + 1;
  }

  void decrementQty(String role) {
    if ((quantities[role] ?? 1) > 1) {
      quantities[role] = (quantities[role] ?? 1) - 1;
    }
  }

  int get totalQuantity => selectedRoles.fold(
      0, (sum, r) => sum + (quantities[r] ?? 1));

  /// Job create — POST /api/jobs. 403 = vendor abhi verified nahi.
  Future<void> submitRequest() async {
    if (isLoading.value) return;
    if (selectedRoles.isEmpty) {
      AppSnackbar.error(message: 'select_one_role_error'.tr);
      return;
    }
    if (cityCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'enter_site_city_error'.tr);
      return;
    }
    final salary = num.tryParse(salaryCtrl.text.trim());
    if (salary == null || salary < 0) {
      AppSnackbar.error(message: 'enter_valid_salary_error'.tr);
      return;
    }
    final exp = num.tryParse(experienceCtrl.text.trim().isEmpty
        ? '0'
        : experienceCtrl.text.trim());
    if (exp == null || exp < 0 || exp > 60) {
      AppSnackbar.error(message: 'experience_range_error'.tr);
      return;
    }
    if (duration.value == 'Custom' && customDurationCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'enter_custom_duration_error'.tr);
      return;
    }

    // ── UI fields → backend job body ─────────────────────────────
    final roles = selectedRoles.toList();

    // Roles ab structured field me jaate hain (`roles` array), isliye
    // title sirf ek chhota summary hai aur description me role list
    // repeat karne ki zaroorat nahi. Pehle title "Welder +3 more
    // Required" ban jaata tha aur asli breakdown description ke free
    // text me dab jaata tha — worker ko kuch theek se dikhta hi nahi tha.
    final title = roles.length == 1
        ? roles.first
        : '${roles.first} +${roles.length - 1} more';

    final location = [
      areaCtrl.text.trim(),
      cityCtrl.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');

    // Description me sirf wahi jo kahin aur structured nahi jaata.
    // Backend ise required maanta hai (khaali par 400), aur ab role list
    // isme nahi hai — isliye sab khaali hone par role summary fallback.
    // Start date ab apne `startDate` field me jaati hai, isliye description
    // me repeat nahi karte.
    final descParts = [
      if (specialReqCtrl.text.trim().isNotEmpty) specialReqCtrl.text.trim(),
    ];
    final description = descParts.isEmpty
        ? roles.map((r) => '${quantities[r] ?? 1} x $r').join(', ')
        : descParts.join('. ');

    isLoading.value = true;
    try {
      final res = await _jobsApi.createJob({
        'title': title,
        'company': _companyName.isEmpty ? 'Sitelink Vendor' : _companyName,
        'location': location,
        // Live server abhi lat/long na milne par 500 deta hai (.trim() crash
        // on undefined) — isliye hamesha strings bhejo; map se pick na kiya
        // ho to bhi "0"/"0" fallback rakho.
        'latitude': pickedLat.value ?? '0',
        'longitude': pickedLng.value ?? '0',
        'quantity': totalQuantity.toString(),
        // Per-role breakdown — backend isse `quantity` ka total bhi
        // derive karta hai, to dono kabhi alag nahi ho sakte.
        'roles': roles
            .map((r) => {'skill': r, 'quantity': quantities[r] ?? 1})
            .toList(),
        'salary': salary,
        'salaryType': salaryType.value,
        'isUrgent': isUrgent.value,
        if (effectiveDuration.isNotEmpty) 'duration': effectiveDuration,
        // Kaam kab shuru hoga — asli date field, description ka text nahi.
        if (startDate.value != null)
          'startDate': startDate.value!.toIso8601String(),
        'description': description,
        'experience': exp.toString(),
        'amenities': selectedAmenityIds.toList(),
      });

      if (res.success) {
        Get.back();
        // Vendor ki jobs list + quota turant taaza. Ye yahan se karte hain
        // (screen kholne wali jagah se nahi) kyunki "New Request" teen
        // jagah se khulti hai aur sirf ek hi list refresh karti thi.
        await refreshVendorJobs();
        // Job post ho gayi — rating maangne ka achha moment. Service
        // khud dekh leti hai ki pehle maang chuke hain ya nahi.
        ReviewService.maybeAsk();
        if ((res.approvalStatus ?? 'pending').toLowerCase() == 'approved') {
          AppSnackbar.success(
            message: res.message ?? 'job_posted_success'.tr,
            duration: const Duration(seconds: 4),
          );
        } else {
          AppSnackbar.warning(
            title: 'job_submitted_title'.tr,
            message: res.message ?? 'job_pending_approval_msg'.tr,
            duration: const Duration(seconds: 4),
          );
        }
      } else if (res.needsPlanScreen) {
        // Plan hi nahi hai (SUBSCRIPTION_REQUIRED) ya worker quota khatam
        // (WORKER_QUOTA_EXCEEDED) — dono me vendor ko Plans screen chahiye.
        //
        // `Get.to` use kar rahe hain (offNamed/back nahi) taaki bhara hua
        // form neeche bacha rahe: plan lene ke baad wapas aate hi vendor
        // seedha Submit dabata hai, poora form dobara nahi bharna padta.
        AppSnackbar.warning(
          title: res.needsSubscription
              ? 'subscription_required_title'.tr
              : 'plan_limit_reached_title'.tr,
          message: res.message ?? 'subscription_required_msg'.tr,
          duration: const Duration(seconds: 4),
        );
        await Get.to(() => const VendorPlansView());
      } else {
        // 403 = verification pending (business rule)
        final msg = res.message ?? 'job_post_failed'.tr;
        AppSnackbar.error(
          message: msg.toLowerCase().contains('verif') ||
                  msg.contains('403') ||
                  msg.toLowerCase().contains('not authorized')
              ? 'account_not_verified_job_msg'.tr
              : msg,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    cityCtrl.dispose();
    areaCtrl.dispose();
    startDateCtrl.dispose();
    customDurationCtrl.dispose();
    specialReqCtrl.dispose();
    salaryCtrl.dispose();
    experienceCtrl.dispose();
    super.onClose();
  }
}
