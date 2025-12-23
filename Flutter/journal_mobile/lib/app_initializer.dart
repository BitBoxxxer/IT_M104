import 'package:journal_mobile/services/_account/account_manager_service.dart';

/// дедупликация. [AppInitializer]
class AppInitializer {
  final AccountManagerService _accountManager = AccountManagerService();
  
  Future<void> initializeApp() async {
    try {
      print('🚀 Инициализация приложения...');
      
      await _accountManager.cleanupDuplicateAccounts();
      
      await _accountManager.fixMultipleActiveAccounts();
      
      await _accountManager.debugAccounts();
      
      print('✅ Приложение инициализировано');
    } catch (e) {
      print('❌ Ошибка инициализации приложения: $e');
    }
  }
  
  Future<void> checkDataMigration() async {
    try {
      await _accountManager.checkAndMigrateOldData();
    } catch (e) {
      print('⚠️ Ошибка миграции данных: $e');
    }
  }
}