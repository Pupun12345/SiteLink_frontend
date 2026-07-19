import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import 'api_client.dart';
import 'session_service.dart';

// Top-level, @pragma('vm:entry-point') — Firebase ki requirement hai ke
// background handler isolate-safe top-level function ho, class method nahi.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // OS khud background/terminated me system tray notification dikha deta hai
  // (payload me `notification` block hai) — yahan sirf log ke liye hook hai.
  debugPrint('[FCM][bg] ${message.messageId}: ${message.notification?.title}');
}

// ═══════════════════════════════════════════════════════════════════
//  NOTIFICATION SERVICE — FCM lifecycle + local display + tap routing
// ═══════════════════════════════════════════════════════════════════
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'sitelink_default_channel',
    'SiteLink Notifications',
    description: 'Job updates, applications aur account alerts.',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// App start pe ek baar call karo (main.dart, Firebase.initializeApp ke baad).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    // Android 13+ runtime permission + iOS prompt — dono is ek call se.
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[NotificationService] permission request failed: $e');
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleRemoteMessageTap(m.data));

    // App terminated state se notification tap karke khula ho to.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageTap(initialMessage.data);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (SessionService.to.isLoggedIn) {
        MiscApiService().saveFcmToken(newToken);
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload));
          _handleRemoteMessageTap(data);
        } catch (e) {
          debugPrint('[NotificationService] payload decode failed: $e');
        }
      },
    );
    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
  }

  /// FCM foreground me khud system tray notification nahi dikhata —
  /// isliye local_notifications se manually dikhate hai.
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Fetch karke naya FCM token backend ko bhej do — login ke baad, ya
  /// app cold-start pe agar user pehle se logged in hai.
  Future<void> syncTokenIfLoggedIn() async {
    if (!SessionService.to.isLoggedIn) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await MiscApiService().saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('[NotificationService] token sync failed: $e');
    }
  }

  void _handleRemoteMessageTap(Map<String, dynamic> data) {
    openFromData(data['type']?.toString() ?? 'general', data);
  }

  // ── Tap-to-navigate ────────────────────────────────────────────────
  // Notification ke `type` ke hisaab se sahi tab/screen par le jaata hai.
  // Har notification ke liye exact detail screen tak deep-link karne ke
  // liye jobId/postId se dobara fetch karna padta — abhi role ke Home tab
  // tak le jaate hai, jaha se user aage tap kar sakta hai. Public — FCM
  // taps aur in-app Alerts-list taps (NotificationsController) dono isi
  // se guzarte hai, taaki routing ek hi jagah define ho.
  void openFromData(String type, Map<String, dynamic> data) {
    final isVendor = SessionService.to.userType == 'vendor';

    switch (type) {
      case 'job_approved':
      case 'job_rejected':
      case 'new_application':
        // Vendor — Requests tab (index 1)
        Get.offAllNamed(AppRoutes.vendorHome);
        _switchTabAfterFrame(1);
        break;
      case 'application_status':
        // Worker — My Jobs tab (index 1)
        Get.offAllNamed(AppRoutes.workerHome);
        _switchTabAfterFrame(1);
        break;
      case 'vendor_verified':
      case 'vendor_rejected':
        Get.offAllNamed(AppRoutes.vendorHome);
        _switchTabAfterFrame(3);
        break;
      case 'new_comment':
        // Community feed — role ke home tab ka Home hi hai (index 0)
        Get.offAllNamed(isVendor ? AppRoutes.vendorHome : AppRoutes.workerHome);
        break;
      default:
        // General — seedha role ke Alerts tab (index 2) par.
        Get.offAllNamed(isVendor ? AppRoutes.vendorHome : AppRoutes.workerHome);
        _switchTabAfterFrame(2);
    }
  }

  void _switchTabAfterFrame(int tabIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeTabSwitcher.switchTo(tabIndex);
    });
  }
}

typedef HomeTabSwitchFn = void Function(int index);

/// [NotificationService] ko concrete `VendorHomeController`/
/// `WorkerHomeController` na import karna pade (feature layers se core
/// me import ulta hota), isliye Home controllers khud apna switch
/// function yahan register karte hai (`onInit`/`onClose`).
class HomeTabSwitcher {
  static HomeTabSwitchFn? _current;

  static void register(HomeTabSwitchFn fn) => _current = fn;
  static void unregister(HomeTabSwitchFn fn) {
    if (_current == fn) _current = null;
  }

  static void switchTo(int index) => _current?.call(index);
}
