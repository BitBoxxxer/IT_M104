import 'package:flutter/material.dart';
import 'package:journal_mobile/models/_widgets/notifications/notification_item.dart';

class NotificationIcon extends StatelessWidget {
  final NotificationType type;
  final double size;

  const NotificationIcon({
    super.key,
    required this.type,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = _getIconData();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  (IconData, Color) _getIconData() {
    switch (type) {
      case NotificationType.newMarks:
        return (Icons.school, Colors.green);
      case NotificationType.attendance:
        return (Icons.access_time, Colors.orange);
      case NotificationType.schedule:
        return (Icons.calendar_today, Colors.blue);
      case NotificationType.achievement:
        return (Icons.emoji_events, Colors.purple);
      case NotificationType.system:
      return (Icons.info, Colors.grey);
    }
  }
}