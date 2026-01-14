import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../_database/database_facade.dart';
import '../../models/_system/account_model.dart';
import '../_offline_service/offline_storage_service.dart';
import '../api_service.dart';
import '../secure_storage_service.dart';
import 'account_id_generator.dart';

class AccountManagerService {
  static final AccountManagerService _instance = AccountManagerService._internal();
  factory AccountManagerService() => _instance;
  AccountManagerService._internal();

  final DatabaseFacade _databaseFacade = DatabaseFacade();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Ключи для SecureStorage (ТОЛЬКО для паролей)
  static String _getUsernameKey(String accountId) => 'acc_${accountId}_username';
  static String _getPasswordKey(String accountId) => 'acc_${accountId}_password';
  static const String _masterPasswordKey = 'master_password';
  static const String _biometricKey = 'biometric_enabled';

  /// ==================== ОСНОВНЫЕ МЕТОДЫ ====================

  /// Получить список всех сохраненных аккаунтов (из SQLite)

  Future<List<Account>> getAllAccounts() async {
    try {
      // Используем фасад вместо прямого запроса к БД
      return await _databaseFacade.getAllAccounts();
    } catch (e) {
      print('❌ Ошибка getAllAccounts: $e');
      return [];
    }
  }

  /// Добавить/обновить аккаунт
  Future<void> addAccount(Account account, {String? password}) async {
    try {
      print('➕ Добавление аккаунта: ${account.username} ${password != null ? 'с паролем' : 'без пароля'}');
      
      final allAccounts = await getAllAccounts();
      
      for (var existingAccount in allAccounts) {
        if (existingAccount.isActive) {
          final deactivated = existingAccount.copyWith(isActive: false);
          await _databaseFacade.saveAccount(deactivated);
        }
      }
      
      final existingIndex = allAccounts.indexWhere((a) => a.username == account.username);
      
      if (existingIndex >= 0) {
        final updatedAccount = account.copyWith(
          id: allAccounts[existingIndex].id,
          isActive: true,
          lastLogin: DateTime.now(),
        );
        await _databaseFacade.saveAccount(updatedAccount);
        
        if (password != null) {
          await saveAccountCredentials(updatedAccount.id, account.username, password);
        }
        
        print('🔄 Аккаунт обновлен: ${account.username}');
      } else {
        final newAccount = account.copyWith(
          id: _generateAccountId(),
          isActive: true,
          lastLogin: DateTime.now(),
        );
        await _databaseFacade.saveAccount(newAccount);
        
        if (password != null) {
          await saveAccountCredentials(newAccount.id, account.username, password);
        }
        
        print('✅ Новый аккаунт добавлен: ${account.username}');
      }
      
      await _ensureSingleActiveAccount();
      
      print('📊 Всего аккаунтов: ${(await getAllAccounts()).length}');
      
    } catch (e) {
      print('❌ Ошибка addAccount: $e');
      rethrow;
    }
  }

  /// Переключиться на другой аккаунт
  Future<void> switchAccount(String accountId) async {
    try {
      print('🔄 Переключение на аккаунт: $accountId');
      
      // 1. Получаем все аккаунты
      final allAccounts = await getAllAccounts();
      
      // 2. Находим целевой аккаунт
      final targetAccount = allAccounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => throw Exception('Аккаунт с ID $accountId не найден'),
      );
      
      // 3. Деактивируем ВСЕ аккаунты
      for (var account in allAccounts) {
        if (account.isActive && account.id != accountId) {
          final deactivated = account.copyWith(isActive: false);
          await _databaseFacade.saveAccount(deactivated);
        }
      }
      
      // 4. Активируем целевой аккаунт
      final activatedAccount = targetAccount.copyWith(
        isActive: true,
        lastLogin: DateTime.now(),
      );
      await _databaseFacade.saveAccount(activatedAccount);
      
      print('✅ Аккаунт активирован: ${targetAccount.username}');
      
      // 5. Проверяем целостность
      await _ensureSingleActiveAccount();
      
    } catch (e) {
      print('❌ Ошибка switchAccount: $e');
      rethrow;
    }
  }

  /// Удалить аккаунт
  Future<void> removeAccount(String accountId) async {
    try {
      final account = await getAccountById(accountId);
      if (account == null) {
        throw Exception('Аккаунт не найден');
      }
      
      print('🗑️ Удаление аккаунта: ${account.username} (ID: $accountId)');
      
      // 1. Очищаем данные через фасад (SQLite)
      await _databaseFacade.clearAllForAccount(accountId);
      
      // 2. Удаляем аккаунт из таблицы accounts
      await _databaseFacade.deleteAccount(accountId);
      
      // 3. Удаляем учетные данные из SecureStorage
      await _deleteAccountCredentials(accountId);
      
      // 4. Очищаем кэши сервисов
      await _clearServiceCaches(accountId);
      
      print('✅ Аккаунт удален из SQLite и SecureStorage');
      
    } catch (e) {
      print('❌ Ошибка удаления аккаунта: $e');
      rethrow;
    }
  }

  /// Очистить кэши сервисов
  Future<void> _clearServiceCaches(String accountId) async {
    try {
      final offlineService = OfflineStorageService();
      offlineService.clearCache();
      
      await _secureStorage.delete(key: 'user_token');
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'current_account_id');
      
      print('🧹 Кэши сервисов очищены');
    } catch (e) {
      print('⚠️ Ошибка очистки кэшей: $e');
    }
  }
  /// Выйти из текущего аккаунта (без удаления)
  Future<void> logoutCurrentAccount() async {
    try {
      final currentAccount = await getCurrentAccount();
      if (currentAccount == null) {
        print('📭 Нет активного аккаунта для выхода');
        return;
      }
      
      print('🚪 Выход из аккаунта: ${currentAccount.username}');
      
      // Деактивируем текущий аккаунт
      final deactivatedAccount = currentAccount.copyWith(isActive: false);
      await updateAccount(deactivatedAccount);
      
      // Очищаем кэши сервисов
      await _clearServiceCaches(currentAccount.id);
      
      // Очищаем кэш OfflineStorage
      final offlineService = OfflineStorageService();
      offlineService.clearCache();
      
      print('✅ Выход выполнен, аккаунт деактивирован');
      
    } catch (e) {
      print('❌ Ошибка выхода: $e');
      rethrow;
    }
  }

  /// Удалить текущий аккаунт с переходом на логин если нужно
  Future<bool> removeCurrentAccountWithNavigation(BuildContext context) async {
    try {
      final currentAccount = await getCurrentAccount();
      if (currentAccount == null) {
        // Если нет аккаунта, сразу переходим на логин
        _navigateToLogin(context);
        return true;
      }
      
      // Удаляем аккаунт
      await removeAccount(currentAccount.id);
      
      // Проверяем, остались ли аккаунты
      final remainingAccounts = await getAllAccounts();
      
      if (remainingAccounts.isEmpty) {
        // Нет аккаунтов - переходим на логин
        _navigateToLogin(context);
        return true;
      } else {
        // Есть другие аккаунты - переключаемся на первый
        await switchAccount(remainingAccounts.first.id);
        return false;
      }
      
    } catch (e) {
      print('❌ Ошибка удаления текущего аккаунта: $e');
      return false;
    }
  }

  /// Приватный метод для навигации
  void _navigateToLogin(BuildContext context) {
    // Эта функция будет завершена в menu_screen
    print('🔀 Навигация на экран логина');
  }

  /// Получить текущий активный аккаунт
  Future<Account?> getCurrentAccount() async {
    try {
      final account = await _databaseFacade.getCurrentAccount();
      
      // Если активного аккаунта нет, но есть другие - выбираем первый
      if (account == null) {
        final allAccounts = await getAllAccounts();
        if (allAccounts.isNotEmpty) {
          await switchAccount(allAccounts.first.id);
          return allAccounts.first.copyWith(isActive: true);
        }
      }
      
      return account;
    } catch (e) {
      print('❌ Ошибка getCurrentAccount: $e');
      return null;
    }
  }

  /// Получить аккаунт по ID
  Future<Account?> getAccountById(String accountId) async {
    try {
      return await _databaseFacade.getAccountById(accountId);
    } catch (e) {
      print('❌ Ошибка getAccountById: $e');
      return null;
    }
  }

  /// Обновить данные аккаунта
  Future<void> updateAccount(Account updatedAccount) async {
    try {
      await _databaseFacade.saveAccount(updatedAccount);
      print('📝 Аккаунт обновлен: ${updatedAccount.username}');
    } catch (e) {
      print('❌ Ошибка updateAccount: $e');
      rethrow;
    }
  }

  /// Обновить токен аккаунта
  Future<void> updateAccountToken(String accountId, String token) async {
    try {
      final account = await getAccountById(accountId);
      if (account == null) throw Exception('Аккаунт не найден');
      
      final updatedAccount = account.copyWith(
        token: token,
        lastLogin: DateTime.now(),
      );
      
      await updateAccount(updatedAccount);
      print('🔑 Токен обновлен для аккаунта: ${account.username}');
    } catch (e) {
      print('❌ Ошибка updateAccountToken: $e');
      rethrow;
    }
  }

  /// Получить валидный токен для текущего аккаунта (с перелогином при необходимости)
  Future<String?> getValidTokenForCurrentAccount() async {
    try {
      final currentAccount = await getCurrentAccount();
      if (currentAccount == null) {
        print('❌ Нет активного аккаунта для получения токена');
        return null;
      }
      
      print('🔄 Получение валидного токена для аккаунта: ${currentAccount.username}');
      
      // 1. Проверяем текущий токен
      final apiService = ApiService();
      try {
        final isValid = await apiService.validateToken(currentAccount.token);
        if (isValid && currentAccount.token.isNotEmpty) {
          print('✅ Токен аккаунта ${currentAccount.username} валиден');
          return currentAccount.token;
        }
      } catch (e) {
        print('⚠️ Ошибка проверки токена: $e');
      }
      
      // 2. Пробуем перелогин с сохраненными учетными данными
      final credentials = await getAccountCredentials(currentAccount.id);
      final username = credentials['username'];
      final password = credentials['password'];
      
      if (username != null && password != null) {
        print('🔄 Пробуем перелогин для аккаунта: $username');
        try {
          final newToken = await apiService.login(username, password);
          if (newToken != null) {
            print('✅ Перелогин успешен, получен новый токен');
            
            // Обновляем токен в аккаунте
            final updatedAccount = currentAccount.copyWith(token: newToken);
            await updateAccount(updatedAccount);
            
            return newToken;
          }
        } catch (e) {
          print('❌ Ошибка перелогина: $e');
        }
      } else {
        print('⚠️ Нет сохраненных учетных данных для перелогина');
      }
      
      // 3. Проверяем токен из SecureStorage (legacy)
      final secureStorage = SecureStorageService();
      final legacyToken = await secureStorage.getToken();
      if (legacyToken != null && legacyToken.isNotEmpty) {
        try {
          final isValid = await apiService.validateToken(legacyToken);
          if (isValid) {
            print('✅ Легаси токен из SecureStorage валиден');
            
            // Обновляем токен в аккаунте
            final updatedAccount = currentAccount.copyWith(token: legacyToken);
            await updateAccount(updatedAccount);
            
            return legacyToken;
          }
        } catch (e) {
          print('⚠️ Легаси токен невалиден: $e');
        }
      }
      
      print('❌ Не удалось получить валидный токен для аккаунта ${currentAccount.username}');
      return null;
      
    } catch (e) {
      print('❌ Ошибка получения валидного токена: $e');
      return null;
    }
  }

  /// ==================== УЧЕТНЫЕ ДАННЫЕ (SecureStorage) ====================

  /// Сохранить учетные данные
  Future<void> saveAccountCredentials(String accountId, String username, String password) async {
    try {
      await _secureStorage.write(
        key: _getUsernameKey(accountId),
        value: username,
      );
      await _secureStorage.write(
        key: _getPasswordKey(accountId),
        value: password,
      );
      print('🔐 Учетные данные сохранены для аккаунта: $username');
    } catch (e) {
      print('❌ Ошибка сохранения учетных данных: $e');
    }
  }

  /// Получить учетные данные
  Future<Map<String, String?>> getAccountCredentials(String accountId) async {
    try {
      final username = await _secureStorage.read(key: _getUsernameKey(accountId));
      final password = await _secureStorage.read(key: _getPasswordKey(accountId));
      
      return {
        'username': username,
        'password': password,
      };
    } catch (e) {
      print('❌ Ошибка получения учетных данных: $e');
      return {'username': null, 'password': null};
    }
  }

  /// Удалить учетные данные
  Future<void> _deleteAccountCredentials(String accountId) async {
    try {
      await _secureStorage.delete(key: _getUsernameKey(accountId));
      await _secureStorage.delete(key: _getPasswordKey(accountId));
      print('🗑️ Учетные данные удалены для аккаунта: $accountId');
    } catch (e) {
      print('❌ Ошибка удаления учетных данных: $e');
    }
  }

  /// ==================== МАСТЕР-ПАРОЛЬ И БИОМЕТРИЯ ====================

  /// Сохранить мастер-пароль
  Future<void> saveMasterPassword(String password) async {
    try {
      await _secureStorage.write(key: _masterPasswordKey, value: password);
      print('🔑 Мастер-пароль сохранен');
    } catch (e) {
      print('❌ Ошибка сохранения мастер-пароля: $e');
    }
  }

  /// Получить мастер-пароль
  Future<String?> getMasterPassword() async {
    try {
      return await _secureStorage.read(key: _masterPasswordKey);
    } catch (e) {
      print('❌ Ошибка получения мастер-пароля: $e');
      return null;
    }
  }

  /// Включить/выключить биометрию
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _biometricKey,
        value: enabled.toString(),
      );
      print('👆 Биометрия ${enabled ? 'включена' : 'выключена'}');
    } catch (e) {
      print('❌ Ошибка настройки биометрии: $e');
    }
  }

  /// Проверить, включена ли биометрия
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricKey);
      return value == 'true';
    } catch (e) {
      print('❌ Ошибка проверки биометрии: $e');
      return false;
    }
  }

  /// ==================== ВОССТАНОВЛЕНИЕ ЦЕЛОСТНОСТИ ====================

  /// Восстановить корректность (только 1 активный аккаунт)
  Future<void> fixMultipleActiveAccounts() async {
    try {
      final allAccounts = await getAllAccounts();
      final activeAccounts = allAccounts.where((a) => a.isActive).toList();
      
      if (activeAccounts.length > 1) {
        print('🛠️ Исправляем ${activeAccounts.length} активных аккаунтов...');
        
        // Выбираем самый "свежий" аккаунт
        final mostRecent = activeAccounts.reduce((a, b) => 
          a.lastLogin.isAfter(b.lastLogin) ? a : b
        );
        
        // Деактивируем все, кроме самого свежего
        for (var account in allAccounts) {
          if (account.id != mostRecent.id && account.isActive) {
            final deactivated = account.copyWith(isActive: false);
            await _databaseFacade.saveAccount(deactivated);
          }
        }
        
        print('✅ Исправлено: теперь активен только ${mostRecent.username}');
      }
    } catch (e) {
      print('❌ Ошибка fixMultipleActiveAccounts: $e');
    }
  }

  /// Гарантировать, что активен только один аккаунт
  Future<void> _ensureSingleActiveAccount() async {
    try {
      final allAccounts = await getAllAccounts();
      final activeAccounts = allAccounts.where((a) => a.isActive).toList();
      
      if (activeAccounts.length != 1) {
        print('⚠️ Нарушение целостности: ${activeAccounts.length} активных аккаунтов');
        await fixMultipleActiveAccounts();
      }
    } catch (e) {
      print('❌ Ошибка _ensureSingleActiveAccount: $e');
    }
  }

  /// ==================== УТИЛИТЫ ====================

  /// Получить статистику
  Future<Map<String, dynamic>> getAccountsStats() async {
    try {
      final accounts = await getAllAccounts();
      final activeAccounts = accounts.where((a) => a.isActive).toList();
      
      // Проверяем учетные данные
      final accountsWithCredentials = <Map<String, dynamic>>[];
      for (var account in accounts) {
        final credentials = await getAccountCredentials(account.id);
        accountsWithCredentials.add({
          'username': account.username,
          'isActive': account.isActive,
          'lastLogin': account.lastLogin,
          'hasCredentials': credentials['password'] != null,
          'hasUsername': credentials['username'] != null,
        });
      }
      
      return {
        'total': accounts.length,
        'active': activeAccounts.length,
        'multiple_active': activeAccounts.length > 1,
        'accounts': accountsWithCredentials,
      };
    } catch (e) {
      print('❌ Ошибка getAccountsStats: $e');
      return {'error': e.toString()};
    }
  }

  /// Очистить все аккаунты
  Future<void> clearAllAccounts() async {
    try {
      print('🗑️ Начинаем очистку всех аккаунтов...');
      
      // 1. Получаем все аккаунты
      final allAccounts = await getAllAccounts();
      
      // 2. Удаляем учетные данные каждого аккаунта
      for (var account in allAccounts) {
        await _deleteAccountCredentials(account.id);
      }
      
      // 3. Удаляем все данные из SQLite
      for (var account in allAccounts) {
        await _databaseFacade.clearAllForAccount(account.id);
      }
      
      // 4. Удаляем все аккаунты из SQLite
      await _databaseFacade.deleteAllAccounts();
      
      // 5. Очищаем мастер-пароль и биометрию
      await _secureStorage.delete(key: _masterPasswordKey);
      await _secureStorage.delete(key: _biometricKey);
      
      print('✅ Все аккаунты и данные очищены');
      
    } catch (e) {
      print('❌ Ошибка clearAllAccounts: $e');
    }
  }

  /// Получить количество аккаунтов
  Future<int> getAccountsCount() async {
    try {
      final accounts = await getAllAccounts();
      return accounts.length;
    } catch (e) {
      print('❌ Ошибка getAccountsCount: $e');
      return 0;
    }
  }

  /// ==================== ОТЛАДКА ====================

  /// Отладочный метод для проверки состояния
  Future<void> debugAccounts() async {
    try {
      final accounts = await getAllAccounts();
      print('\n=== ДЕБАГ АККАУНТОВ ===');
      print('Всего аккаунтов: ${accounts.length}');
      
      for (var account in accounts) {
        final credentials = await getAccountCredentials(account.id);
        print('👤 ${account.username}:');
        print('   ID: ${account.id}');
        print('   Активен: ${account.isActive}');
        print('   Последний вход: ${account.lastLogin}');
        print('   Токен: ${account.token.substring(0, 20)}...');
        print('   Учетные данные: ${credentials['username'] != null ? 'есть' : 'нет'}');
        print('   Пароль: ${credentials['password'] != null ? 'сохранен' : 'отсутствует'}');
        print('   ---');
      }
      
      final active = accounts.where((a) => a.isActive).toList();
      print('Активных: ${active.length}');
      
      if (active.length != 1) {
        print('⚠️ ПРОБЛЕМА: ${active.length} активных аккаунтов!');
      }
      
      // Проверяем мастер-пароль и биометрию
      final masterPassword = await getMasterPassword();
      final biometricEnabled = await isBiometricEnabled();
      print('Мастер-пароль: ${masterPassword != null ? 'установлен' : 'нет'}');
      print('Биометрия: ${biometricEnabled ? 'включена' : 'выключена'}');
      
      print('======================\n');
    } catch (e) {
      print('❌ Ошибка debugAccounts: $e');
    }
  }

  /// Проверить миграцию старых данных
  Future<void> checkAndMigrateOldData() async {
    try {
      print('🔄 Проверка старых данных...');
      
      // Старые ключи из предыдущей версии
      final oldAccountsKey = 'multi_accounts_list';
      final oldCurrentAccountKey = 'current_account_id';
      
      final oldAccountsJson = await _secureStorage.read(key: oldAccountsKey);
      
      if (oldAccountsJson != null) {
        print('📦 Найдены старые данные, начинаем миграцию...');
        
        // Парсим старые аккаунты
        final List<dynamic> oldAccountsList = jsonDecode(oldAccountsJson);
        final oldCurrentId = await _secureStorage.read(key: oldCurrentAccountKey);
        
        for (var oldAccount in oldAccountsList) {
          try {
            final account = Account.fromJson(oldAccount);
            
            // Сохраняем в новую систему
            await addAccount(account);
            
            // Пробуем получить старые учетные данные
            final oldUsername = await _secureStorage.read(key: 'username_${account.id}');
            final oldPassword = await _secureStorage.read(key: 'password_${account.id}');
            
            if (oldUsername != null && oldPassword != null) {
              await saveAccountCredentials(account.id, oldUsername, oldPassword);
              
              // Очищаем старые данные
              await _secureStorage.delete(key: 'username_${account.id}');
              await _secureStorage.delete(key: 'password_${account.id}');
            }
            
            // Если это был текущий аккаунт
            if (oldCurrentId == account.id) {
              await switchAccount(account.id);
            }
            
          } catch (e) {
            print('❌ Ошибка миграции аккаунта: $e');
          }
        }
        
        // Очищаем старые ключи
        await _secureStorage.delete(key: oldAccountsKey);
        await _secureStorage.delete(key: oldCurrentAccountKey);
        
        print('✅ Миграция завершена');
      } else {
        print('📭 Старых данных не найдено');
      }
      
    } catch (e) {
      print('❌ Ошибка миграции: $e');
    }
  }

  /// Очистить дублирующиеся аккаунты по username
Future<void> cleanupDuplicateAccounts() async {
  try {
    print('🧹 Очистка дублирующихся аккаунтов...');
    
    final allAccounts = await getAllAccounts();
    final uniqueUsernames = <String>{};
    final accountsToDelete = <Account>[];
    
    // Ищем дубли
    for (var account in allAccounts) {
      final lowercaseUsername = account.username.toLowerCase();
      
      if (uniqueUsernames.contains(lowercaseUsername)) {
        // Нашли дубль
        accountsToDelete.add(account);
        print('❌ Найден дублирующийся аккаунт: ${account.username} (ID: ${account.id})');
      } else {
        uniqueUsernames.add(lowercaseUsername);
      }
    }
    
    // Удаляем дубли
    for (var duplicateAccount in accountsToDelete) {
      // Сохраняем учетные данные перед удалением
      final credentials = await getAccountCredentials(duplicateAccount.id);
      final remainingAccount = allAccounts.firstWhere(
        (a) => a.username.toLowerCase() == duplicateAccount.username.toLowerCase() 
            && a.id != duplicateAccount.id
      );
      
      if (remainingAccount.id.isNotEmpty && credentials['password'] != null) {
        // Переносим учетные данные на оставшийся аккаунт
        await saveAccountCredentials(
          remainingAccount.id, 
          credentials['username'] ?? '', 
          credentials['password'] ?? ''
        );
      }
      
      await removeAccount(duplicateAccount.id);
    }
    
    if (accountsToDelete.isNotEmpty) {
      print('✅ Удалено ${accountsToDelete.length} дублирующихся аккаунтов');
    } else {
      print('✅ Дублирующихся аккаунтов не найдено');
    }
    
  } catch (e) {
    print('❌ Ошибка очистки дублей: $e');
  }
}

  /// Миграция старых ID аккаунтов в новый формат
  Future<void> migrateOldAccountIds() async {
    try {
      print('🔄 Проверка старых ID аккаунтов...');
      
      final allAccounts = await getAllAccounts();
      int migratedCount = 0;
      
      for (var account in allAccounts) {
        if (!account.id.startsWith('acc_') && account.id.isNotEmpty) {
          print('🔄 Миграция аккаунта ${account.username} со старым ID: ${account.id}');
          
          final newAccount = account.copyWith(
            id: _generateAccountId(),
          );
          
          await _databaseFacade.saveAccount(newAccount);
          
          final credentials = await getAccountCredentials(account.id);
          if (credentials['username'] != null && credentials['password'] != null) {
            await saveAccountCredentials(
              newAccount.id,
              credentials['username']!,
              credentials['password']!,
            );
          }
          
          await _databaseFacade.deleteAccount(account.id);
          await _deleteAccountCredentials(account.id);
          
          migratedCount++;
        }
      }
      
      if (migratedCount > 0) {
        print('✅ Мигрировано $migratedCount аккаунтов в новый формат ID');
      } else {
        print('✅ Все аккаунты уже в правильном формате');
      }
    } catch (e) {
      print('❌ Ошибка миграции ID аккаунтов: $e');
    }
  }

  // Господи спасибо за дубликаты
  Future<Account> addAccountWithCredentials({
    required String username,
    required String password,
    String? token,
    String? fullName,
    String? groupName,
    String? photoPath,
    int studentId = 0,
  }) async {
    try {
      print('➕ Создание нового аккаунта с паролем: $username');
      
      final accountId = _generateAccountId();
      
      final account = Account(
        id: accountId,
        username: username,
        fullName: fullName ?? '',
        groupName: groupName ?? '',
        photoPath: photoPath ?? '',
        token: token ?? '',
        lastLogin: DateTime.now(),
        isActive: true,
        studentId: studentId,
      );
      
      await addAccount(account, password: password);
      
      print('✅ Аккаунт создан с ID: $accountId и сохраненным паролем');
      
      return account;
    } catch (e) {
      print('❌ Ошибка создания аккаунта: $e');
      rethrow;
    }
  }

  /// ==================== ПРИВАТНЫЕ МЕТОДЫ ====================

  /// Генерация ID для нового аккаунта
  String _generateAccountId() {
    return AccountIdGenerator.generateAccountId();
  }
}