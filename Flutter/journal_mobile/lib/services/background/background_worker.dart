import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../settings/notification_service.dart';

class BackgroundWorker {
  static const String syncTask = "backgroundSyncTask";
  static const String notificationTask = "backgroundNotificationTask";

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
          default:
            return false;
        }
      } catch (e) {
        print('❌ Ошибка в фоновой задаче $task: $e');
        return false;
      }
    });
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
      
      // Проверяем настройки уведомлений
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
    
    // В фоне делаем более редкие проверки для экономии батареи
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
      // Синхронизация данных
      await Workmanager().registerPeriodicTask(
        "sync_1",
        syncTask,
        frequency: Duration(hours: 1),
        initialDelay: Duration(minutes: 10),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      // Проверка уведомлений
      await Workmanager().registerPeriodicTask(
        "notifications_1", 
        notificationTask,
        frequency: Duration(minutes: 30),
        initialDelay: Duration(minutes: 5),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
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