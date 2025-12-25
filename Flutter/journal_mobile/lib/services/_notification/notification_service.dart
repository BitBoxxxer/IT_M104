import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:journal_mobile/services/_notification/notification_state_service.dart';

import '../../_database/database_facade.dart';
import '../api_service.dart';
import '../time_manager.dart';

import 'package:journal_mobile/models/_widgets/notifications/notification_item.dart';
import 'package:journal_mobile/models/mark.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  final NotificationStateService _stateService = NotificationStateService();

  final DatabaseFacade _databaseFacade = DatabaseFacade();
  String? _currentAccountId;

  bool _isInitialized = false;

  final StreamController<List<NotificationItem>> _notificationsController = 
      StreamController<List<NotificationItem>>.broadcast();
  
  Stream<List<NotificationItem>> get notificationsStream => _notificationsController.stream;
  
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _lastMarksHashKey = 'last_marks_hash';
  static const String _lastAttendanceHashKey = 'last_attendance_hash';
  static const String _pollingEnabledKey = 'polling_enabled';
  static const String _lastSuccessfulCheckKey = 'last_successful_check';

  Timer? _pollingTimer;
  bool _pollingActive = false;

  void dispose() {
    _notificationsController.close();
    _pollingTimer?.cancel();
  }

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

   Future<void> _initializeWithAccount() async {
    final account = await _databaseFacade.getCurrentAccount();
    _currentAccountId = account?.id;
  }

  Future<void> saveNotificationToHistory(NotificationItem notification) async {
    if (_currentAccountId == null) await _initializeWithAccount();
    if (_currentAccountId == null) return;
    
    await _databaseFacade.saveNotification(notification, _currentAccountId!);
    _emitNotificationsUpdate();
  }

  Future<List<NotificationItem>> getNotificationsHistory() async {
    if (_currentAccountId == null) await _initializeWithAccount();
    if (_currentAccountId == null) return [];
    
    return await _databaseFacade.getNotifications(_currentAccountId!);
  }

  Future<void> markAsRead(int notificationId) async {
    if (_currentAccountId == null) await _initializeWithAccount();
    if (_currentAccountId == null) return;
    
    await _databaseFacade.markAsRead(notificationId, _currentAccountId!);
    _emitNotificationsUpdate();
  }

  Future<void> clearNotificationsHistory() async {
    if (_currentAccountId == null) await _initializeWithAccount();
    if (_currentAccountId == null) return;
    
    await _databaseFacade.clearNotifications(_currentAccountId!);
    _emitNotificationsUpdate();
  }

  Future<void> deleteNotification(int notificationId) async {
    if (_currentAccountId == null) await _initializeWithAccount();
    if (_currentAccountId == null) return;
    
    await _databaseFacade.deleteNotification(notificationId, _currentAccountId!);
    _emitNotificationsUpdate();
  }

  

  void _emitNotificationsUpdate() {
    if (!_notificationsController.isClosed) {
      getNotificationsHistory().then((notifications) {
        _notificationsController.add(notifications);
      });
    }
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
      print('Opening notification settings...');
      await AppSettings.openAppSettings();
      print('Notification settings opened successfully');
    } catch (e) {
      print('Error opening notification settings: $e');
      try {
        await AppSettings.openAppSettings();
        print('Fallback: App settings opened successfully');
      } catch (fallbackError) {
        print('Error opening app settings: $fallbackError');
        throw fallbackError;
      }
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
          },
          {
            'id': 'schedule_notes_channel',
            'name': 'Напоминания заметок',
            'created': true,
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

    // практика
    const AndroidNotificationChannel notesChannel = AndroidNotificationChannel(
      'schedule_notes_channel',
      'Напоминания заметок',
      description: 'Уведомления о заметках к расписанию',
      importance: Importance.high,
    );

    await notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(marksChannel);
    
    await notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(attendanceChannel);

    await notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(notesChannel);
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
  void startSmartPolling(String token) {
    if (_pollingActive) {
      print('⏭️ Polling уже активен');
      return;
    }
    
    _pollingActive = true;
    _startPollingLoop(token);
    
    print('🔔 Фоновый polling уведомлений запущен');
  }
  void stopSmartPolling() {
    _pollingActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    print('🔕 Фоновый polling уведомлений остановлен');
  }

  void _startPollingLoop(String token) {
    if (!_pollingActive) return;
    
    _pollingTimer = Timer(const Duration(minutes: 15), () async {
      if (await _shouldCheckNow() && await isPollingEnabled() && _pollingActive) {
        await checkForUpdates(token);
      }
      
      if (_pollingActive) {
        _startPollingLoop(token);
      }
    });
  }

  Future<bool> _shouldCheckNow() async {
    return await TimeManager.shouldCheckNotifications();
  }


  Future<void> checkForUpdates(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await _ensureInitialState(token, prefs);
      
      await _checkMarks(token, prefs);
      await _checkAttendance(token, prefs);
      
      await prefs.setInt(_lastSuccessfulCheckKey, 
        DateTime.now().millisecondsSinceEpoch);
        
    } catch (e) {
      print('Smart polling error: $e');
    }
  }

  Future<void> _ensureInitialState(String token, SharedPreferences prefs) async {
  try {
    final lastMarks = await _stateService.getLastMarksState();
    
    if (lastMarks.isEmpty) {
      final marks = await _apiService.getMarks(token);
      await _stateService.saveNotificationState(marks);
      
      print('✅ Initial notification state saved: ${marks.length} marks');
    }
    } catch (e) {
      print('❌ Error ensuring initial state: $e');
    }
  }

  Future<void> _checkMarks(String token, SharedPreferences prefs) async {
  try {
    print('🔍 Checking for new marks...');
    
    final lastMarks = await _stateService.getLastMarksState();
    print('📊 Last marks for notifications: ${lastMarks.length}');
  
    final currentMarks = await _apiService.getMarks(token);
    print('📊 Current marks from API: ${currentMarks.length}');
    
    final newMarks = _findNewMarks(currentMarks, lastMarks);
    print('🆕 New marks found: ${newMarks.length}');
    
    if (newMarks.isNotEmpty) {
      await showNewMarksNotification(newMarks.length);
      
      await _stateService.saveNotificationState(currentMarks);
      
      print('✅ New marks notification sent: ${newMarks.length} marks');
    } else {
      print('📭 No new marks found');
    }
    } catch (e) {
      print('❌ Error checking marks: $e');
    }
  }

  Future<void> _checkAttendance(String token, SharedPreferences prefs) async {
  try {
    print('🔍 Checking for attendance changes...');
    
    final lastAttendance = await _stateService.getLastAttendanceState();
    final currentMarks = await _apiService.getMarks(token);
    final currentAttendance = _extractAttendanceData(currentMarks);
    
    final attendanceChanges = _findAttendanceChanges(currentAttendance, lastAttendance);
    print('📊 Attendance changes: ${attendanceChanges}');
    
    if (attendanceChanges['absences']! > 0 || attendanceChanges['lates']! > 0) {
      await showAttendanceNotification(attendanceChanges);
      await _stateService.saveNotificationState(currentMarks);
      
      print('✅ Attendance notification sent');
    } else {
      print('📭 No attendance changes found');
    }
  } catch (e) {
    print('❌ Error checking attendance: $e');
  }
}

  Future<bool> openNotificationSettings() async {
  try {
    if (Platform.isAndroid) {
      const platform = MethodChannel('notification_settings_channel');
      final result = await platform.invokeMethod<bool>('openNotificationSettings');
      return result ?? false;
    } else if (Platform.isIOS) {
      await AppSettings.openAppSettings();
      return true;
    }
    return false;
  } catch (e) {
    print('Ошибка открытия настроек уведомлений: $e');
    
    try {
      await AppSettings.openAppSettings();
      return true;
    } catch (fallbackError) {
      print('Fallback также не сработал: $fallbackError');
      return false;
    }
  }
}

  List<Map<String, dynamic>> _extractAttendanceData(List<Mark> marks) {
    return marks.map((mark) => {
      'dateVisit': mark.dateVisit,
      'specName': mark.specName,
      'statusWas': mark.statusWas,
      'lessonTheme': mark.lessonTheme,
    }).toList();
  }

  List<Mark> _findNewMarks(List<Mark> currentMarks, List<Mark> lastMarks) {
    final newMarks = <Mark>[];
    
    for (final currentMark in currentMarks) {
      final existingMark = lastMarks.firstWhere(
        (lastMark) => 
          lastMark.dateVisit == currentMark.dateVisit &&
          lastMark.specName == currentMark.specName,
        orElse: () => Mark(
          specName: '',
          lessonTheme: '',
          dateVisit: '',
        ),
      );
      
      final hasNewMark = 
          (currentMark.homeWorkMark != null && existingMark.homeWorkMark == null) ||
          (currentMark.controlWorkMark != null && existingMark.controlWorkMark == null) ||
          (currentMark.labWorkMark != null && existingMark.labWorkMark == null) ||
          (currentMark.classWorkMark != null && existingMark.classWorkMark == null) ||
          (currentMark.practicalWorkMark != null && existingMark.practicalWorkMark == null);
      
      if (hasNewMark) {
        newMarks.add(currentMark);
      }
    }
    
    return newMarks;
  }

  Map<String, int> _findAttendanceChanges(
    List<Map<String, dynamic>> currentAttendance, 
    List<Map<String, dynamic>> lastAttendance
  ) {
    int newAbsences = 0;
    int newLates = 0;
    
    for (final current in currentAttendance) {
      final existing = lastAttendance.firstWhere(
        (last) => 
          last['dateVisit'] == current['dateVisit'] &&
          last['specName'] == current['specName'],
        orElse: () => {},
      );
      
      if (existing.isEmpty) {
        if (current['statusWas'] == 0) newAbsences++;
        if (current['statusWas'] == 2) newLates++;
      } else {
        final lastStatus = existing['statusWas'];
        final currentStatus = current['statusWas'];
        
        if (lastStatus != currentStatus) {
          if (currentStatus == 0) newAbsences++;
          if (currentStatus == 2) newLates++;
        }
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
      await checkForUpdates(token);
    }
  }

  Future<void> manualCheckWithNotification(String token) async {
    try {
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '🔄 Проверка обновлений',
        message: 'Выполняется ручная проверка новых данных...',
        timestamp: DateTime.now(),
        type: NotificationType.system,
      );
      
      await saveNotificationToHistory(notification);
    if (await isPollingEnabled()) {
      await checkForUpdates(token);
      
      final resultNotification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        title: '✅ Проверка завершена',
        message: 'Система проверила наличие новых оценок и изменений посещаемости',
        timestamp: DateTime.now(),
        type: NotificationType.system,
      );
      
      await saveNotificationToHistory(resultNotification);
    }
  } catch (e) {
    print('Error in manual check: $e');
    
    final errorNotification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '❌ Ошибка проверки',
      message: 'Не удалось проверить обновления: $e',
      timestamp: DateTime.now(),
      type: NotificationType.system,
    );
    
    await saveNotificationToHistory(errorNotification);
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