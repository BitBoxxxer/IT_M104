import '../api_service.dart';
import 'account_manager_service.dart';

class AccountAuthService {
  final ApiService _apiService = ApiService();
  final AccountManagerService _accountManager = AccountManagerService();

  /// Че, по названию не понятно ? [account_auth_service]
  Future<String?> reauthenticateAccount(String accountId) async {
    try {
      print('🔄 Пробуем перелогин для аккаунта: $accountId');
      
      final credentials = await _accountManager.getAccountCredentials(accountId);
      final username = credentials['username'];
      final password = credentials['password'];
      
      if (username == null || password == null) {
        print('❌ Нет сохраненных учетных данных для аккаунта $accountId');
        return null;
      }
      
      print('🔑 Найдены учетные данные для: $username');
      
      final newToken = await _apiService.login(username, password);
      
      if (newToken == null) {
        print('❌ Перелогин не удался для: $username');
        return null;
      }
      
      print('✅ Успешный перелогин, получен новый токен');
      
      final accounts = await _accountManager.getAllAccounts();
      final accountIndex = accounts.indexWhere((a) => a.id == accountId);
      
      if (accountIndex >= 0) {
        final updatedAccount = accounts[accountIndex].copyWith(token: newToken);
        await _accountManager.updateAccount(updatedAccount);
        print('📝 Токен обновлен в аккаунте');
      }
      
      return newToken;
    } catch (e) {
      print('❌ Ошибка перелогина: $e');
      return null;
    }
  }

  /// Проверить токен и обновить при необходимости [account_auth_service]
  Future<String> getValidTokenForAccount(String accountId) async {
    try {
      final accounts = await _accountManager.getAllAccounts();
      final account = accounts.firstWhere((a) => a.id == accountId);
      
      print('🔍 Проверяем токен аккаунта: ${account.username}');
      
      final isTokenValid = await _apiService.validateToken(account.token);
      
      if (isTokenValid) {
        print('✅ Токен действителен');
        return account.token;
      }
      
      print('⚠️ Токен недействителен, пытаемся обновить...');
      
      final newToken = await reauthenticateAccount(accountId);
      
      if (newToken != null) {
        print('✅ Токен успешно обновлен через перелогин');
        return newToken;
      }
      
      print('⚠️ Не удалось обновить токен, используем старый');
      return account.token;
    } catch (e) {
      print('❌ Ошибка getValidTokenForAccount: $e');
      rethrow;
    }
  }

  /// Принудительный перелогин для всех аккаунтов [account_auth_service]
  Future<void> reauthenticateAllAccounts() async {
    try {
      print('🔄 Начинаем перелогин всех аккаунтов...');
      
      final accounts = await _accountManager.getAllAccounts();
      int successCount = 0;
      int failCount = 0;
      
      for (var account in accounts) {
        try {
          final newToken = await reauthenticateAccount(account.id);
          if (newToken != null) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          print('❌ Ошибка для аккаунта ${account.username}: $e');
          failCount++;
        }
      }
      
      print('📊 Результат: успешно $successCount, не удалось $failCount');
    } catch (e) {
      print('❌ Ошибка reauthenticateAllAccounts: $e');
    }
  }
}