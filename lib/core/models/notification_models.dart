// ═══════════════════════════════════════════════════════════════════
//  IN-APP NOTIFICATION — /api/notifications
// ═══════════════════════════════════════════════════════════════════
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'])
          : const {},
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class NotificationListResponse {
  final bool success;
  final String? message;
  final List<AppNotification> data;
  final int unreadCount;

  const NotificationListResponse({
    required this.success,
    this.message,
    this.data = const [],
    this.unreadCount = 0,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    return NotificationListResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: rawList is List
          ? rawList
              .whereType<Map>()
              .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
