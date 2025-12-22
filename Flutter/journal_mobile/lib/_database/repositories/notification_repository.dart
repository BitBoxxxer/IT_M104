import 'dart:convert';

import 'package:journal_mobile/models/_widgets/notifications/notification_item.dart';
import '../database_service.dart';
import '../database_config.dart';

class NotificationRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveNotification(NotificationItem notification, String accountId) async {
    await _dbService.insert(DatabaseConfig.tableNotifications, {
      'id': notification.id,
      'account_id': accountId,
      'title': notification.title,
      'message': notification.message,
      'timestamp': notification.timestamp.millisecondsSinceEpoch,
      'type': notification.type.toString().split('.').last,
      'is_read': notification.isRead ? 1 : 0,
      'payload': notification.payload != null ? jsonEncode(notification.payload) : null,
    });
  }

  Future<List<NotificationItem>> getNotifications(String accountId) async {
    final notificationsData = await _dbService.query(
      DatabaseConfig.tableNotifications,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'timestamp DESC',
    );

    return notificationsData.map((data) => NotificationItem.fromJson({
      'id': data['id'],
      'title': data['title'],
      'message': data['message'],
      'timestamp': DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
      'type': _parseNotificationType(data['type'] as String),
      'isRead': data['is_read'] == 1,
      'payload': data['payload'] != null ? jsonDecode(data['payload'] as String) : null,
    })).toList();
  }

  Future<void> markAsRead(int notificationId, String accountId) async {
    await _dbService.update(
      DatabaseConfig.tableNotifications,
      {'is_read': 1},
      where: 'id = ? AND account_id = ?',
      whereArgs: [notificationId, accountId],
    );
  }

  Future<void> deleteNotification(int notificationId, String accountId) async {
    await _dbService.delete(
      DatabaseConfig.tableNotifications,
      where: 'id = ? AND account_id = ?',
      whereArgs: [notificationId, accountId],
    );
  }

  Future<void> clearNotifications(String accountId) async {
    await _dbService.delete(
      DatabaseConfig.tableNotifications,
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  Future<int> getUnreadCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableNotifications} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  } // tableNotifications

  NotificationType _parseNotificationType(String typeString) {
    switch (typeString) {
      case 'newMarks':
        return NotificationType.newMarks;
      case 'attendance':
        return NotificationType.attendance;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}
