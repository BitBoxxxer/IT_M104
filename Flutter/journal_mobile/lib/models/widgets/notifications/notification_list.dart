import 'package:flutter/material.dart';
import 'package:journal_mobile/models/notification_item.dart';
import 'package:journal_mobile/models/widgets/notifications/notification_card.dart';

class NotificationList extends StatelessWidget {
  final List<NotificationItem> notifications;
  final Function(NotificationItem) onNotificationTap;
  final Function(NotificationItem) onNotificationDelete;

  const NotificationList({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onNotificationDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        
        return NotificationCard(
          notification: notification,
          onTap: () => onNotificationTap(notification),
          onDelete: () => onNotificationDelete(notification),
        );
      },
    );
  }
}