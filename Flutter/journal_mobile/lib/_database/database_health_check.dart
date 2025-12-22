// lib/_database/database_health_check.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import './database_service.dart';
import './sqflite_init.dart';

class DatabaseHealthCheck {
  static Future<bool> checkDatabaseHealth() async {
    try {
      print('🔍 Проверка здоровья базы данных...');
      
      if (!SqfliteInitializer.isInitialized) {
        print('❌ Sqflite не инициализирован');
        return false;
      }
      
      final dbService = DatabaseService();
      final db = await dbService.database;
      
      final stats = await dbService.getDatabaseStats();
      print('📊 Статистика базы данных: $stats');
      
      print('✅ База данных в рабочем состоянии');
      return true;
    } catch (e) {
      print('❌ Ошибка проверки базы данных: $e');
      return false;
    }
  }
  
  static Future<void> repairDatabaseIfNeeded() async {
    try {
      final isHealthy = await checkDatabaseHealth();
      if (!isHealthy) {
        print('🛠️ Пытаемся восстановить базу данных...');
        
        // Переинициализируем sqflite
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        
        // Пробуем переоткрыть БД
        final dbService = DatabaseService();
        await dbService.close();
        
        // Очищаем кэш через публичный метод
        await DatabaseService.clearDatabaseCache();
        
        // Пробуем снова
        await dbService.database;
        
        print('✅ База данных восстановлена');
      }
    } catch (e) {
      print('❌ Не удалось восстановить базу данных: $e');
    }
  }
}