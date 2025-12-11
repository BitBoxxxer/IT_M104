import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:journal_mobile/models/_widgets/notifications/notification_item.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static final _readWriteLock = AsyncLock();

  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _passwordKey = 'auth_password';
  static const String _notificationsHistoryKey = 'notifications_history';

  Future<void> saveToken(String token) async {
    await _readWriteLock.synchronized(() async {
      await _storage.write(key: _tokenKey, value: token);
    });
  }

  Future<String?> getToken() async {
    return await _readWriteLock.synchronized<String?>(() async {
      return await _storage.read(key: _tokenKey);
    });
  }

  Future<void> saveCredentials(String username, String password) async {
    await _readWriteLock.synchronized(() async {
      await _storage.write(key: _usernameKey, value: username);
      await _storage.write(key: _passwordKey, value: password);
    });
  }

  Future<Map<String, String?>> getCredentials() async {
    return await _readWriteLock.synchronized<Map<String, String?>>(() async {
      try {
        final username = await _storage.read(key: _usernameKey);
        final password = await _storage.read(key: _passwordKey);
        return {'username': username, 'password': password};
      } catch (e) {
        print('❌ Ошибка получения данных: $e');
        return {'username': null, 'password': null};
      }
    });
  }

  Future<void> clearAll() async {
    await _readWriteLock.synchronized(() async {
      try {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _usernameKey);
        await _storage.delete(key: _passwordKey);
        await _storage.delete(key: _notificationsHistoryKey);
        print('✅ Безопасное хранилище полностью очищено');
      } catch (e) {
        print('❌ Ошибка очистки хранилища: $e');
        await _clearStorageFile();
      }
    });
  }

  Future<bool> hasSavedCredentials() async {
    return await _readWriteLock.synchronized<bool>(() async {
      try {
        final username = await _storage.read(key: _usernameKey);
        final password = await _storage.read(key: _passwordKey);
        return username != null && password != null;
      } catch (e) {
        print('❌ Ошибка проверки сохраненных данных: $e');
        return false;
      }
    });
  }

  Future<void> saveNotificationsHistory(List<NotificationItem> notifications) async {
    await _readWriteLock.synchronized(() async {
      try {
        final notificationsJson = notifications.map((n) => n.toJson()).toList();
        await _storage.write(
          key: _notificationsHistoryKey,
          value: jsonEncode(notificationsJson),
        );
        print('✅ История уведомлений сохранена: ${notifications.length} шт');
      } catch (e) {
        print('❌ Ошибка сохранения истории уведомлений: $e');
        throw e;
      }
    });
  }

  Future<List<NotificationItem>> getNotificationsHistory() async {
    return await _readWriteLock.synchronized<List<NotificationItem>>(() async {
      try {
        final jsonString = await _storage.read(key: _notificationsHistoryKey) ?? '[]';
        final List<dynamic> notificationsList = jsonDecode(jsonString);
        
        final notifications = notificationsList
            .map((json) => NotificationItem.fromJson(json))
            .toList();
        
        print('✅ История уведомлений загружена: ${notifications.length} шт');
        return notifications;
      } catch (e) {
        print('❌ Ошибка загрузки истории уведомлений: $e');
        return [];
      }
    });
  }

  Future<void> addNotificationToHistory(NotificationItem notification) async {
    await _readWriteLock.synchronized(() async {
      try {
        final jsonString = await _storage.read(key: _notificationsHistoryKey) ?? '[]';
        final List<dynamic> notificationsList = jsonDecode(jsonString);
        List<NotificationItem> existingNotifications = notificationsList
            .map((json) => NotificationItem.fromJson(json))
            .toList();
        
        existingNotifications.removeWhere((n) => n.id == notification.id);
        
        if (existingNotifications.length >= 100) {
          existingNotifications.removeLast();
        }
        
        existingNotifications.insert(0, notification);
        final notificationsJson = existingNotifications.map((n) => n.toJson()).toList();
        await _storage.write(
          key: _notificationsHistoryKey,
          value: jsonEncode(notificationsJson),
        );
        
        print('📱 Уведомление сохранено в безопасное хранилище: ${notification.title}');
      } catch (e) {
        print('❌ Ошибка сохранения уведомления: $e');
        try {
          await _storage.write(
            key: _notificationsHistoryKey,
            value: jsonEncode([notification.toJson()]),
          );
        } catch (e2) {
          print('❌ Критическая ошибка сохранения уведомления: $e2');
        }
      }
    });
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _readWriteLock.synchronized(() async {
      try {
        final jsonString = await _storage.read(key: _notificationsHistoryKey) ?? '[]';
        final List<dynamic> notificationsList = jsonDecode(jsonString);
        List<NotificationItem> notifications = notificationsList
            .map((json) => NotificationItem.fromJson(json))
            .toList();
        
        bool changed = false;
      for (var i = 0; i < notifications.length; i++) {
        if (notifications[i].id == notificationId && !notifications[i].isRead) {
          notifications[i] = NotificationItem(
            id: notifications[i].id,
            title: notifications[i].title,
            message: notifications[i].message,
            timestamp: notifications[i].timestamp,
            type: notifications[i].type,
            isRead: true,
            payload: notifications[i].payload,
          );
          changed = true;
          break;
        }
      }
      
        if (changed) {
          final notificationsJson = notifications.map((n) => n.toJson()).toList();
          await _storage.write(
            key: _notificationsHistoryKey,
            value: jsonEncode(notificationsJson),
          );
          print('✅ Уведомление $notificationId отмечено как прочитанное');
        }
      } catch (e) {
        print('❌ Ошибка пометки уведомления как прочитанного: $e');
      }
    });
  }

  Future<void> clearNotificationsHistory() async {
    await _readWriteLock.synchronized(() async {
      try {
        await _storage.delete(key: _notificationsHistoryKey);
        print('✅ История уведомлений очищена');
      } catch (e) {
        print('❌ Ошибка очистки истории уведомлений: $e');
        await _clearStorageFile();
      }
    });
  }

  /// Метод для принудительной очистки файла хранилища при критических ошибках
  Future<void> _clearStorageFile() async {
    try {
      final allKeys = await _storage.readAll();
      
      for (final key in allKeys.keys) {
        try {
          await _storage.delete(key: key);
        } catch (e) {
          print('❌ Не удалось удалить ключ $key: $e');
        }
      }
      
      print('✅ Файл хранилища сброшен после ошибки');
    } catch (e) {
      print('❌ Критическая ошибка сброса хранилища: $e');
    }
  }

  /// Метод для безопасного массового сохранения
  Future<void> safeWrite(Map<String, String> data) async {
    await _readWriteLock.synchronized(() async {
      try {
        for (final entry in data.entries) {
          await _storage.write(key: entry.key, value: entry.value);
        }
      } catch (e) {
        print('❌ Ошибка массовой записи: $e');
        throw e;
      }
    });
  }

  /// Метод для безопасного массового чтения
  Future<Map<String, String>> safeRead(List<String> keys) async {
    return await _readWriteLock.synchronized<Map<String, String>>(() async {
      try {
        final result = <String, String>{};
        for (final key in keys) {
          final value = await _storage.read(key: key);
          if (value != null) {
            result[key] = value;
          }
        }
        return result;
      } catch (e) {
        print('❌ Ошибка массового чтения: $e');
        return {};
      }
    });
  }
}

/// Класс для асинхронной блокировки с поддержкой возвращаемых значений
/// ВЫНЕСТИ ЕГО. КАКОГО ОН ТУТ ЗАБЫЛ - 11.12.25
class AsyncLock {
  Future<void>? _lastOperation;
  
  Future<T> synchronized<T>(Future<T> Function() operation) {
    final previous = _lastOperation;
    final completer = Completer<T>();
    
    _lastOperation = completer.future;
    
    return previous?.then((_) => operation()).then((value) {
      completer.complete(value);
      return value;
    }).catchError((e) {
      completer.completeError(e);
      throw e;
    }) 
    ?? operation().then((value) {
      completer.complete(value);
      return value;
    }).catchError((e) {
      completer.completeError(e);
      throw e;
    });
  }
}