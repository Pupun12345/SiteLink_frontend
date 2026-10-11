import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/models/notification_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  NOTIFICATIONS CONTROLLER — shared by vendor + worker Alerts screens
//  AND the Home-tab bell badge (single source of truth for unreadCount).
// ═══════════════════════════════════════════════════════════════════
class NotificationsController extends GetxController {
  final _api = NotificationApiService();

  final notifications = <AppNotification>[].obs;
  final isLoading = true.obs;
  final unreadCount = 0.obs;

  /// Find-or-create — ek hi permanent instance poori app session me,
  /// taaki Home badge aur Alerts list dono hamesha same live data dekhein.
  static NotificationsController get to =>
      Get.isRegistered<NotificationsController>()
          ? Get.find<NotificationsController>()
          : Get.put(NotificationsController(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    NotificationsRefreshHub.register(fetchNotifications);
    fetchNotifications();
  }

  @override
  void onClose() {
    NotificationsRefreshHub.unregister(fetchNotifications);
    super.onClose();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final res = await _api.getMyNotifications();
      if (res.success) {
        notifications.assignAll(res.data);
        unreadCount.value = res.unreadCount;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllRead() async {
    final ok = await _api.markAllRead();
    if (ok) {
      notifications.assignAll(
          notifications.map((n) => n.isRead ? n : _copyRead(n)).toList());
      unreadCount.value = 0;
    }
  }

  /// Tap: read mark karo (agar zaroori ho) aur relevant tab/screen par le jao.
  Future<void> onTapNotification(AppNotification n) async {
    if (!n.isRead) {
      final idx = notifications.indexWhere((x) => x.id == n.id);
      if (idx != -1) {
        notifications[idx] = _copyRead(n);
        unreadCount.value = (unreadCount.value - 1).clamp(0, 1 << 30);
      }
      _api.markRead(n.id);
    }
    NotificationService.instance.openFromData(n.type, n.data);
  }

  Future<void> deleteNotification(String id) async {
    final removed = notifications.firstWhereOrNull((n) => n.id == id);
    notifications.removeWhere((n) => n.id == id);
    if (removed != null && !removed.isRead) {
      unreadCount.value = (unreadCount.value - 1).clamp(0, 1 << 30);
    }
    await _api.deleteNotification(id);
  }

  AppNotification _copyRead(AppNotification n) => AppNotification(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        data: n.data,
        isRead: true,
        createdAt: n.createdAt,
      );

  bool get isVendor => SessionService.to.userType == 'vendor';
  String get homeRoute => isVendor ? AppRoutes.vendorHome : AppRoutes.workerHome;
}
