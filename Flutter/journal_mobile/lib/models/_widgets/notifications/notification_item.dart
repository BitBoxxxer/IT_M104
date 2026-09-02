class NotificationItem {
  final int id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? payload;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.payload,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'];
    final type = json['type'];
    return NotificationItem(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString()),
      type: type is NotificationType
          ? type
          : type is String
              ? NotificationType.values.firstWhere(
                  (value) => value.name == type,
                  orElse: () => NotificationType.system,
                )
              : NotificationType.values[(type as num).toInt().clamp(
                    0,
                    NotificationType.values.length - 1,
                  )],
      isRead: json['isRead'] ?? false,
      payload: json['payload'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'isRead': isRead,
      'payload': payload,
    };
  }
}

enum NotificationType {
  newMarks,
  attendance,
  system,
  schedule,
  achievement,
}