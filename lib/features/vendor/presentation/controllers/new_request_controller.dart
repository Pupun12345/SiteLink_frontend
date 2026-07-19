import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/job_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_snackbar.dart';

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

  final selectedRoles  = <String>[].obs;
  final quantities     = <String, int>{}.obs;
  final cityCtrl       = TextEditingController();
  final areaCtrl       = TextEditingController();
  final startDateCtrl  = TextEditingController();
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
      // Vendor ke /me me companyName top-level ya user me aa sakta hai
      _companyName = res.user?.name ?? '';
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
      AppSnackbar.success(message: 'Amenity added');
      await loadAmenities();
    } else {
      AppSnackbar.error(message: res.message ?? 'Amenity add nahi hui');
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
      AppSnackbar.error(message: 'Please select at least one role');
      return;
    }
    if (cityCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'Please enter the site city / location');
      return;
    }
    final salary = num.tryParse(salaryCtrl.text.trim());
    if (salary == null || salary < 0) {
      AppSnackbar.error(message: 'Valid salary daalein (₹)');
      return;
    }
    final exp = num.tryParse(experienceCtrl.text.trim().isEmpty
        ? '0'
        : experienceCtrl.text.trim());
    if (exp == null || exp < 0 || exp > 60) {
      AppSnackbar.error(message: 'Experience 0–60 saal ke beech ho');
      return;
    }
    if (duration.value == 'Custom' && customDurationCtrl.text.trim().isEmpty) {
      AppSnackbar.error(message: 'Custom duration daalein');
      return;
    }

    // ── UI fields → backend job body ─────────────────────────────
    final roles = selectedRoles.toList();
    final title = roles.length == 1
        ? '${roles.first} Required'
        : '${roles.first} +${roles.length - 1} more Required';
    final location = [
      areaCtrl.text.trim(),
      cityCtrl.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
    final rolesDetail = roles
        .map((r) => '${quantities[r] ?? 1} x $r')
        .join(', ');
    final description = [
      'Roles: $rolesDetail',
      if (startDateCtrl.text.trim().isNotEmpty)
        'Start: ${startDateCtrl.text.trim()}',
      if (specialReqCtrl.text.trim().isNotEmpty) specialReqCtrl.text.trim(),
    ].join('. ');

    isLoading.value = true;
    try {
      final res = await _jobsApi.createJob({
        'title': title,
        'company': _companyName.isEmpty ? 'SiteLink Vendor' : _companyName,
        'location': location,
        // Live server abhi lat/long na milne par 500 deta hai (.trim() crash
        // on undefined) — isliye hamesha strings bhejo; map se pick na kiya
        // ho to bhi "0"/"0" fallback rakho.
        'latitude': pickedLat.value ?? '0',
        'longitude': pickedLng.value ?? '0',
        'quantity': totalQuantity.toString(),
        'salary': salary,
        'salaryType': salaryType.value,
        'isUrgent': isUrgent.value,
        if (effectiveDuration.isNotEmpty) 'duration': effectiveDuration,
        'description': description,
        'experience': exp.toString(),
        'amenities': selectedAmenityIds.toList(),
      });

      if (res.success) {
        Get.back();
        if ((res.approvalStatus ?? 'pending').toLowerCase() == 'approved') {
          AppSnackbar.success(
            message: res.message ?? 'Job posted successfully!',
            duration: const Duration(seconds: 4),
          );
        } else {
          AppSnackbar.warning(
            title: 'Job Submitted',
            message: res.message ??
                'Pending admin approval — it will be visible once approved.',
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        // 403 = verification pending (business rule)
        final msg = res.message ?? 'Job post nahi hua';
        AppSnackbar.error(
          message: msg.toLowerCase().contains('verif') ||
                  msg.contains('403') ||
                  msg.toLowerCase().contains('not authorized')
              ? 'Aapka account abhi verify nahi hua — 24-48 hours me verify hone ke baad job post kar payenge.'
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
