import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:journal_mobile/models/mark.dart';
import '../api_service.dart';
import 'package:journal_mobile/services/secure_storage_service.dart';
import 'package:journal_mobile/models/notification_item.dart';
import 'dart:convert';

class NotificationService {
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _lastMarksHashKey = 'last_marks_hash';
  static const String _lastAttendanceHashKey = 'last_attendance_hash';
  static const String _pollingEnabledKey = 'polling_enabled';
  static const String _lastSuccessfulCheckKey = 'last_successful_check';

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );
    
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    try {
      await notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('📱 Уведомление нажато: ${response.payload}');
        },
      );

      await _createNotificationChannels();
      _isInitialized = true;
      
      print('✅ Уведомления инициализированы успешно');
      
    } catch (e) {
      print('❌ Ошибка инициализации уведомлений: $e');
      _isInitialized = false;
    }
  }

  Future<void> saveNotificationToHistory(NotificationItem notification) async {
    await _secureStorage.addNotificationToHistory(notification);
  }

  Future<List<NotificationItem>> getNotificationsHistory() async {
    return await _secureStorage.getNotificationsHistory();
  }

  Future<void> markAsRead(int notificationId) async {
    await _secureStorage.markNotificationAsRead(notificationId);
  }

  Future<void> clearNotificationsHistory() async {
    await _secureStorage.clearNotificationsHistory();
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_marks_channel',
      'Новые оценки',
      channelDescription: 'Уведомления о новых оценках',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: Colors.blue,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    
    await notifications.show(
      999,
      '🎯 ТЕСТ СИСТЕМЫ',
      'Время: ${DateTime.now().toString()}',
      details,
    );
  }

  Future<bool?> areNotificationsEnabled() async {
    return await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
  }

  Future<bool> requestPermissions() async {
    try {
      return true;
    } catch (e) {
      print('❌ Ошибка запроса разрешений: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> checkPermissionStatus() async {
    final status = <String, dynamic>{};
    
    try {
      final androidPlugin = notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        status['enabled'] = await androidPlugin.areNotificationsEnabled();
        status['platform'] = 'android';
      } else {
        status['enabled'] = true;
        status['platform'] = 'ios';
      }
      
      status['initialized'] = _isInitialized;
      return status;
    } catch (e) {
      status['error'] = e.toString();
      return status;
    }
  }

  Future<void> openAppNotificationSettings() async {
    try {
      print('📱 Откройте настройки уведомлений вручную:');
      print('   Настройки → Приложения → journal_mobile → Уведомления');
    } catch (e) {
      print('❌ Ошибка открытия настроек: $e');
    }
  }

  Future<List<AndroidNotificationChannel>?> getActiveNotificationChannels() async {
    try {
      return [
        const AndroidNotificationChannel(
          'new_marks_channel',
          'Новые оценки',
          description: 'Уведомления о новых оценках',
          importance: Importance.high,
        ),
        const AndroidNotificationChannel(
          'attendance_channel', 
          'Посещаемость',
          description: 'Уведомления о пропусках и опозданиях',
          importance: Importance.high,
        ),
      ];
    } catch (e) {
      print('❌ Ошибка получения каналов: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    final status = <String, dynamic>{};
    
    try {
      status['initialized'] = _isInitialized;
      
      final androidPlugin = notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        status['notificationsEnabled'] = await androidPlugin.areNotificationsEnabled();
        
        status['channels'] = [
          {
            'id': 'new_marks_channel',
            'name': 'Новые оценки',
            'created': true
          },
          {
            'id': 'attendance_channel', 
            'name': 'Посещаемость',
            'created': true
          }
        ];
      }
      
      return status;
    } catch (e) {
      status['error'] = e.toString();
      return status;
    }
  }

  Future<bool> isInitialized() async {
    return _isInitialized;
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final List<NotificationItem> notifications = await getNotificationsHistory();
      final updatedNotifications = notifications.where((n) => n.id != notificationId).toList();
      await _secureStorage.saveNotificationsHistory(updatedNotifications);
      print('🗑️ Уведомление $notificationId удалено');
    } catch (e) {
      print('❌ Ошибка удаления уведомления: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel marksChannel = AndroidNotificationChannel(
      'new_marks_channel',
      'Новые оценки',
      description: 'Уведомления о новых оценках',
      importance: Importance.high,
    );

    const AndroidNotificationChannel attendanceChannel = AndroidNotificationChannel(
      'attendance_channel', 
      'Посещаемость',
      description: 'Уведомления о пропусках и опозданиях',
      importance: Importance.high,
    );

    await notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(marksChannel);
    
    await notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(attendanceChannel);
  }

  Future<bool> isPollingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pollingEnabledKey) ?? true;
  }

  Future<void> setPollingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pollingEnabledKey, enabled);
  }

  // Умный Polling с адаптивным интервалом - Ди
  Future<void> startSmartPolling(String token) async {
    if (!await isPollingEnabled()) return;
    _startPollingLoop(token);
  }

  void _startPollingLoop(String token) {
    Future.delayed(Duration(minutes: 15), () async {
      if (await _shouldCheckNow() && await isPollingEnabled()) {
        await _checkForUpdates(token);
      }
      _startPollingLoop(token);
    });
  }

  Future<bool> _shouldCheckNow() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastSuccessfulCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return (now - lastCheck) > 5 * 60 * 1000;
  }

  Future<void> _checkForUpdates(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await _checkMarks(token, prefs);
      await _checkAttendance(token, prefs);
      
      await prefs.setInt(_lastSuccessfulCheckKey, 
        DateTime.now().millisecondsSinceEpoch);
        
    } catch (e) {
      print('Smart polling error: $e');
    }
  }

  Future<void> _checkMarks(String token, SharedPreferences prefs) async {
    try {
      final lastMarksHash = prefs.getString(_lastMarksHashKey) ?? '';
      final currentMarks = await _apiService.getMarks(token);
      final currentHash = _calculateMarksHash(currentMarks);
      
      if (lastMarksHash != currentHash && lastMarksHash.isNotEmpty) {
        final newMarksCount = _countNewMarks(currentMarks, lastMarksHash);
        await showNewMarksNotification(newMarksCount);
      }
      
      await prefs.setString(_lastMarksHashKey, currentHash);
    } catch (e) {
      print('Error checking marks: $e');
    }
  }

  Future<void> _checkAttendance(String token, SharedPreferences prefs) async {
    try {
      final lastAttendanceHash = prefs.getString(_lastAttendanceHashKey) ?? '';
      final currentMarks = await _apiService.getMarks(token);
      final currentHash = _calculateAttendanceHash(currentMarks);
      
      if (lastAttendanceHash != currentHash && lastAttendanceHash.isNotEmpty) {
        final attendanceChanges = _analyzeAttendanceChanges(currentMarks, lastAttendanceHash);
        await showAttendanceNotification(attendanceChanges);
      }
      
      await prefs.setString(_lastAttendanceHashKey, currentHash);
    } catch (e) {
      print('Error checking attendance: $e');
    }
  }

  String _calculateMarksHash(List<Mark> marks) {
    final marksString = marks.map((m) => 
      '${m.dateVisit}-${m.homeWorkMark}-${m.controlWorkMark}-${m.labWorkMark}-${m.classWorkMark}'
    ).join('|');
    
    return marksString.hashCode.toString();
  }

  String _calculateAttendanceHash(List<Mark> marks) {
    final attendanceString = marks.map((m) => 
      '${m.dateVisit}-${m.statusWas}-${m.specName}'
    ).join('|');
    
    return attendanceString.hashCode.toString();
  }

  int _countNewMarks(List<Mark> currentMarks, String lastHash) {
    return currentMarks.where((mark) =>
      mark.homeWorkMark != null || 
      mark.controlWorkMark != null || 
      mark.labWorkMark != null || 
      mark.classWorkMark != null
    ).length;
  }

  Map<String, int> _analyzeAttendanceChanges(List<Mark> currentMarks, String lastHash) {
    int newAbsences = 0;
    int newLates = 0;
    
    for (var mark in currentMarks) {
      if (mark.statusWas == 0) {
        newAbsences++;
      } else if (mark.statusWas == 2) {
        newLates++;
      }
    }
    
    return {
      'absences': newAbsences,
      'lates': newLates,
    };
  }

  Future<void> showNewMarksNotification(int newMarksCount) async {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '📚 Новые оценки!',
      message: 'Появилось $newMarksCount новых оценок',
      timestamp: DateTime.now(),
      type: NotificationType.newMarks,
      payload: {'newMarksCount': newMarksCount},
    );
    
    await saveNotificationToHistory(notification);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_marks_channel',
      'Новые оценки',
      channelDescription: 'Уведомления о новых оценках',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.green,
      ledColor: Colors.green,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await notifications.show(
      1,
      notification.title,
      notification.message,
      details,
      payload: jsonEncode(notification.payload),
    );
  }

  Future<void> showAttendanceNotification(Map<String, int> changes) async {
    final absences = changes['absences'] ?? 0;
    final lates = changes['lates'] ?? 0;
    
    if (absences == 0 && lates == 0) return;

    String title = '';
    String message = '';

    if (absences > 0 && lates > 0) {
      title = '⚠️ Посещаемость';
      message = 'Пропусков: $absences, Опозданий: $lates';
    } else if (absences > 0) {
      title = '❌ Пропуски';
      message = 'Обнаружено $absences пропусков';
    } else if (lates > 0) {
      title = '⏰ Опоздания';
      message = 'Обнаружено $lates опозданий';
    }

    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: NotificationType.attendance,
      payload: {'absences': absences, 'lates': lates},
    );
    
    await saveNotificationToHistory(notification);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Посещаемость',
      channelDescription: 'Уведомления о пропусках и опозданиях',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.orange,
      ledColor: Colors.orange,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await notifications.show(
      2,
      notification.title,
      notification.message,
      details,
      payload: jsonEncode(notification.payload),
    );
  }

  Future<void> manualCheck(String token) async {
    if (await isPollingEnabled()) {
      await _checkForUpdates(token);
    }
  }

  Future<void> manualCheckWithNotification(String token) async {
    if (await isPollingEnabled()) {
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '🔄 Проверка обновлений',
        message: 'Выполняется ручная проверка новых данных...',
        timestamp: DateTime.now(),
        type: NotificationType.system,
      );
      
      await saveNotificationToHistory(notification);
      await _checkForUpdates(token);
    }
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastMarksHashKey);
    await prefs.remove(_lastAttendanceHashKey);
    await prefs.remove(_lastSuccessfulCheckKey);
    await clearNotificationsHistory();
  }
}