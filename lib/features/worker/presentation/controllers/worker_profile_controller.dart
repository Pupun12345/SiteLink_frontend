import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER PROFILE CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class WorkerProfileController extends GetxController {
  final isLoading = false.obs;

  // Current logged-in user ID — replace with auth value in real app
  final currentUserId = 'current_user';

  final name         = 'Ramesh Kumar'.obs;
  final initials     = 'RK'.obs;
  final workerId     = 'SL-WRK-2024-004'.obs;
  final primarySkill = 'Mason'.obs;
  final location     = 'Jaipur, Rajasthan'.obs;
  final phone        = '+91 98765 43210'.obs;
  final experience   = '5 yrs'.obs;
  final isVerified   = true.obs;

  final totalJobs     = 12.obs;
  final completedJobs = 11.obs;
  final rating        = 4.6.obs;

  final skills    = ['Mason', 'Tile Worker', 'Helper'].obs;
  final documents = <Map<String, dynamic>>[
    {'label': 'Aadhaar Card',           'verified': true},
    {'label': 'Work Experience Letter', 'verified': true},
  ].obs;
}