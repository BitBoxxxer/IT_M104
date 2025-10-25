import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:journal_mobile/models/notification_item.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _passwordKey = 'auth_password';
  static const String _notificationsHistoryKey = 'notifications_history';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    return {'username': username, 'password': password};
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _notificationsHistoryKey);
  }

  Future<bool> hasSavedCredentials() async {
    final credentials = await getCredentials();
    return credentials['username'] != null && credentials['password'] != null;
  }

  Future<void> saveNotificationsHistory(List<NotificationItem> notifications) async {
    final notificationsJson = notifications.map((n) => n.toJson()).toList();
    await _storage.write(
      key: _notificationsHistoryKey,
      value: jsonEncode(notificationsJson),
    );
  }

  Future<List<NotificationItem>> getNotificationsHistory() async {
    try {
      final jsonString = await _storage.read(key: _notificationsHistoryKey) ?? '[]';
      final List<dynamic> notificationsList = jsonDecode(jsonString);
      
      return notificationsList.map((json) => NotificationItem.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки истории уведомлений: $e');
      return [];
    }
  }

  Future<void> addNotificationToHistory(NotificationItem notification) async {
    try {
      final List<NotificationItem> existingNotifications = await getNotificationsHistory();
      
      if (existingNotifications.length >= 100) {
        existingNotifications.removeLast();
      } // TODO: Сделать возможность для пользователя сделать ограничение длинны уведомлений в настройках
      
      existingNotifications.insert(0, notification);
      await saveNotificationsHistory(existingNotifications);
      
      print('📱 Уведомление сохранено в безопасное хранилище: ${notification.title}');
    } catch (e) {
      print('❌ Ошибка сохранения уведомления: $e');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final List<NotificationItem> notifications = await getNotificationsHistory();
      
      for (var i = 0; i < notifications.length; i++) {
        if (notifications[i].id == notificationId) {
          notifications[i] = NotificationItem(
            id: notifications[i].id,
            title: notifications[i].title,
            message: notifications[i].message,
            timestamp: notifications[i].timestamp,
            type: notifications[i].type,
            isRead: true,
            payload: notifications[i].payload,
          );
          break;
        }
      }
      
      await saveNotificationsHistory(notifications);
    } catch (e) {
      print('❌ Ошибка пометки уведомления как прочитанного: $e');
    }
  }

  Future<void> clearNotificationsHistory() async {
    try {
      await _storage.delete(key: _notificationsHistoryKey);
    } catch (e) {
      print('❌ Ошибка очистки истории уведомлений: $e');
    }
  }
}