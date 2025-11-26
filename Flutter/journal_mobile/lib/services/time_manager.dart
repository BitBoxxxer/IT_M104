import 'package:shared_preferences/shared_preferences.dart';

class TimeManager {
  static Future<bool> shouldSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('last_sync_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final syncInterval = _getSyncInterval();
    
    return (now - lastSync) > syncInterval;
  }
  
  static Future<bool> shouldCheckNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('last_successful_check') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return (now - lastCheck) > 5 * 60 * 1000;
  }
  
  static int _getSyncInterval() {
    final hour = DateTime.now().hour;
    
    if (hour >= 0 && hour < 6) { // Ночь
      return 60 * 60 * 1000; // 1 час
    } else if (hour >= 6 && hour < 12) { // Утро
      return 20 * 60 * 1000; // 20 минут
    } else if (hour >= 12 && hour < 18) { // День
      return 30 * 60 * 1000; // 30 минут
    } else { // Вечер
      return 45 * 60 * 1000; // 45 минут
    }
  }
}