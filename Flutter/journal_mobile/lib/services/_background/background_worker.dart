import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../_notification/notification_service.dart';
import '../schedule_note_service.dart';

class BackgroundWorker {
  static const String syncTask = "backgroundSyncTask";
  static const String notificationTask = "backgroundNotificationTask";
  static const String noteReminderTask = "noteReminderTask";
  static const String rescheduleRemindersTask = "rescheduleRemindersTask";

  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );
      _isInitialized = true;
      print('✅ Workmanager инициализирован');
    } catch (e) {
      print('❌ Ошибка инициализации Workmanager: $e');
      _isInitialized = false;
    }
  }
  
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      print('🔄 Фоновая задача запущена: $task');
      
      try {
        switch (task) {
          case syncTask:
            return await _performBackgroundSync();
          case notificationTask:
            return await _performBackgroundNotificationCheck();
          case noteReminderTask:
            return await _performNoteReminderCheck();
          case rescheduleRemindersTask:
            return await _rescheduleAllNoteReminders();
          default:
            return false;
        }
      } catch (e) {
        print('❌ Ошибка в фоновой задаче $task: $e');
        return false;
      }
    });
  }

  static Future<bool> _rescheduleAllNoteReminders() async {
    try {
      print('🔄 Перепланирование всех напоминаний заметок...');
      
      final scheduleNoteService = ScheduleNoteService();
      
      // все заметки с активными напоминаниями
      await scheduleNoteService.scheduleAllReminders();
      
      print('✅ Все напоминания перепланированы');
      return true;
    } catch (e) {
      print('❌ Ошибка перепланирования напоминаний: $e');
      return false;
    }
  }

  static Future<bool> _performNoteReminderCheck() async {
    try {
      print('🔔 Проверка напоминаний заметок...');
      
      final scheduleNoteService = ScheduleNoteService();
      await scheduleNoteService.checkAndTriggerReminders();
      
      final upcoming = await scheduleNoteService.getUpcomingReminders(limit: 3);
      print('📅 Предстоящие напоминания: ${upcoming.length}');
      
      print('✅ Проверка напоминаний завершена');
      return true;
    } catch (e) {
      print('❌ Ошибка проверки напоминаний заметок: $e');
      return false;
    }
  }
  
  static Future<bool> _performBackgroundSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        print('❌ Нет токена для фоновой синхронизации');
        return false;
      }
      
      // Умная проверка необходимости синхронизации
      final lastSync = prefs.getInt('last_sync_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final syncInterval = _getBackgroundSyncInterval();
      
      if (now - lastSync < syncInterval) {
        print('⏭️ Фоновая синхронизация не требуется');
        return true;
      }
      
      print('🔄 Выполняем фоновую синхронизацию...');
      
      final apiService = ApiService();
      await apiService.syncAllData(token);
      
      print('✅ Фоновая синхронизация завершена');
      return true;
    } catch (e) {
      print('❌ Ошибка фоновой синхронизации: $e');
      return false;
    }
  }
  
  static Future<bool> _performBackgroundNotificationCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        return false;
      }
      
      final notificationService = NotificationService();
      
      if (await notificationService.isPollingEnabled()) {
        print('🔔 Фоновая проверка уведомлений...');
        await notificationService.checkForUpdates(token);
      }
      
      return true;
    } catch (e) {
      print('❌ Ошибка фоновой проверки уведомлений: $e');
      return false;
    }
  }
  
  static int _getBackgroundSyncInterval() {
    final hour = DateTime.now().hour;
    
    if (hour >= 0 && hour < 6) { // Ночь
      return 2 * 60 * 60 * 1000; // 2 часа
    } else if (hour >= 6 && hour < 12) { // Утро
      return 60 * 60 * 1000; // 1 час
    } else if (hour >= 12 && hour < 18) { // День
      return 90 * 60 * 1000; // 1.5 часа
    } else { // Вечер
      return 2 * 60 * 60 * 1000; // 2 часа
    }
  }
  
  static Future<void> scheduleBackgroundSync() async {
    if (!_isInitialized) {
      print('⚠️ Workmanager не инициализирован, пропускаем планирование');
      return;
    }
    
    try {
      await Workmanager().registerPeriodicTask(
        "sync_1",
        syncTask,
        frequency: Duration(hours: 1),
        initialDelay: Duration(minutes: 10),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      await Workmanager().registerPeriodicTask(
        "notifications_1", 
        notificationTask,
        frequency: Duration(minutes: 30),
        initialDelay: Duration(minutes: 5),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      await Workmanager().registerPeriodicTask(
        "notes_reminders",
        noteReminderTask,
        frequency: Duration(minutes: 5),
        initialDelay: Duration(minutes: 1),
      );
      
      print('📅 Фоновые задачи запланированы через Workmanager');
    } catch (e) {
      print('❌ Ошибка планирования фоновых задач: $e');
    }
  }
  
  static void cancelBackgroundSync() {
    Workmanager().cancelByTag("sync_1");
    Workmanager().cancelByTag("notifications_1");
    print('📅 Фоновые задачи Workmanager отменены');
  }
}