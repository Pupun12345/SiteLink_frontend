import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
      _logToken('refreshed', newToken);
      if (SessionService.to.isLoggedIn) {
        MiscApiService().saveFcmToken(newToken);
      }
    });

    // Debug me token hamesha print karo (login se pehle bhi) — isse verify
    // kar sakte hain ki device ko FCM token mil raha hai ya nahi.
    if (kDebugMode) {
      try {
        _logToken('startup', await FirebaseMessaging.instance.getToken());
      } catch (e) {
        _out('[FCM_TOKEN] getToken() failed: $e');
      }
    }
  }

  /// Debug-only console output. `debugPrint` throttle karta hai (lambi line
  /// tut sakti hai) isliye seedha `print` — kDebugMode guard ke saath, taaki
  /// release build me token kabhi log na ho.
  void _out(String msg) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print(msg);
  }

  /// Poora FCM token ek hi line me — copy karne layak (token ~163 chars ka
  /// hota hai, logcat ki per-line limit se kaafi kam).
  void _logToken(String label, String? token) {
    if (token == null || token.isEmpty) {
      _out('[FCM_TOKEN] ($label) NULL — device ko token nahi mila');
      return;
    }
    _out('╔═════════════ FCM TOKEN ($label) ═════════════');
    _out('[FCM_TOKEN] $token');
    _out('╚═════════════ length=${token.length} ═════════════');
  }

  /// Kahin se bhi token maangna ho to — e.g. debug button/console se.
  Future<String?> printCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _logToken('manual', token);
      return token;
    } catch (e) {
      _out('[FCM_TOKEN] getToken() failed: $e');
      return null;
    }
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

    // App foreground me hai — Alerts list + Home bell badge turant refresh
    // taaki naya push aate hi unread count/list live update ho, list-tab
    // khole bina.
    NotificationsRefreshHub.refresh();
  }

  /// Fetch karke naya FCM token backend ko bhej do — login ke baad, ya
  /// app cold-start pe agar user pehle se logged in hai.
  /// [label] sirf debug log me dikhta hai — call kahan se aayi wo pata chale
  /// (e.g. 'otp-login', 'google-login', 'splash').
  Future<void> syncTokenIfLoggedIn({String label = 'sync'}) async {
    if (!SessionService.to.isLoggedIn) {
      _out('[FCM_TOKEN] ($label) skipped — user logged in nahi hai');
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _logToken(label, token);
      if (token != null && token.isNotEmpty) {
        final ok = await MiscApiService().saveFcmToken(token);
        _out('[FCM_TOKEN] ($label) backend save-token → '
            '${ok ? 'SUCCESS ✅' : 'FAILED ❌'}');
      }
    } catch (e) {
      _out('[FCM_TOKEN] ($label) token sync failed: $e');
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
      case 'job_closed':
        // Worker — My Jobs tab (index 1)
        Get.offAllNamed(AppRoutes.workerHome);
        _switchTabAfterFrame(1);
        break;
      case 'vendor_verified':
      case 'vendor_rejected':
        Get.offAllNamed(AppRoutes.vendorHome);
        _switchTabAfterFrame(3);
        break;
      case 'worker_verified':
      case 'worker_rejected':
        Get.offAllNamed(AppRoutes.workerHome);
        _switchTabAfterFrame(3);
        break;
      case 'new_comment':
      case 'new_like':
        // Community feed — role ke home tab ka Home hi hai (index 0)
        Get.offAllNamed(isVendor ? AppRoutes.vendorHome : AppRoutes.workerHome);
        break;
      case 'subscription_activated':
      // Auto-payment ki khabrein — renewal, cancel, ya charge fail. Teeno
      // par user ko plan/expiry dekhni hoti hai, jo Profile tab me hai.
      case 'subscription_renewed':
      case 'autopay_cancelled':
      case 'autopay_failed':
      case 'phone_changed':
        // Profile tab — role ke apne Profile/Plan ka context yahin hai
        Get.offAllNamed(isVendor ? AppRoutes.vendorHome : AppRoutes.workerHome);
        _switchTabAfterFrame(3);
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

typedef NotificationsRefreshFn = void Function();

/// [NotificationsController] (features/shared) khud ko yahan register
/// karta hai (onInit/onClose) — [NotificationService] (core) ko upar
/// feature layer import nahi karna padta, [HomeTabSwitcher] jaisa hi
/// decoupling pattern.
class NotificationsRefreshHub {
  static NotificationsRefreshFn? _current;

  static void register(NotificationsRefreshFn fn) => _current = fn;
  static void unregister(NotificationsRefreshFn fn) {
    if (_current == fn) _current = null;
  }

  static void refresh() => _current?.call();
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
