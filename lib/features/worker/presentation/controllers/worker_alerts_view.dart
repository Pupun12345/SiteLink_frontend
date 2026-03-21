import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════
//  ALERT MODEL
// ═══════════════════════════════════════════════════════════════════
enum AlertType { jobAssigned, jobCompleted, newRequirement, system }

class AlertModel {
  final String id;
  final AlertType type;
  final String title;
  final String subtitle;
  final DateTime time;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isRead = false,
  });

  AlertModel copyWith({bool? isRead}) => AlertModel(
    id: id,
    type: type,
    title: title,
    subtitle: subtitle,
    time: time,
    isRead: isRead ?? this.isRead,
  );
}

// ═══════════════════════════════════════════════════════════════════
//  ALERTS CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class WorkerAlertsController extends GetxController {
  final alerts    = <AlertModel>[].obs;
  final isLoading = false.obs;

  int get unreadCount => alerts.where((a) => !a.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    isLoading.value = true;
    // TODO: API call
    await Future.delayed(const Duration(milliseconds: 500));
    alerts.assignAll(_mockAlerts);
    isLoading.value = false;
  }

  void markAllRead() {
    // TODO: API call
    alerts.assignAll(alerts.map((a) => a.copyWith(isRead: true)).toList());
  }

  static final _mockAlerts = [
    AlertModel(
      id: 'a1',
      type: AlertType.jobAssigned,
      title: 'New Job Assigned',
      subtitle:
      'Admin assigned you Mason work with Rajesh Construction. Start date: 25 Mar 2026.',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    AlertModel(
      id: 'a2',
      type: AlertType.newRequirement,
      title: 'New Requirement Posted',
      subtitle: 'Sharma Builders needs 5 Tile Workers. Malviya Nagar, ₹600/day.',
      time: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: false,
    ),
    AlertModel(
      id: 'a3',
      type: AlertType.jobCompleted,
      title: 'Job Completed',
      subtitle: 'Gupta Constructions job is complete. Your rating: 4.5 ⭐',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AlertModel(
      id: 'a4',
      type: AlertType.system,
      title: 'Profile Verified',
      subtitle: 'Your profile has been verified by the SiteLink admin. Jobs can now be assigned to you.',
      time: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
    ),
  ];
}