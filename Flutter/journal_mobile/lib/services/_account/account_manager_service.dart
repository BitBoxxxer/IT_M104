import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/_system/account_model.dart';

class AccountManagerService {
  static final AccountManagerService _instance = AccountManagerService._internal();
  factory AccountManagerService() => _instance;
  AccountManagerService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _accountsKey = 'multi_accounts_list';
  static const String _currentAccountIdKey = 'current_account_id';

  /// Получить список всех сохраненных аккаунтов
  Future<List<Account>> getAllAccounts() async {
    try {
      final jsonString = await _storage.read(key: _accountsKey) ?? '[]';
      final List<dynamic> accountsList = jsonDecode(jsonString);
      
      return accountsList
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Ошибка загрузки аккаунтов: $e');
      return [];
    }
  }

  /// Добавить/обновить аккаунт
  Future<void> addAccount(Account account) async {
    try {
      List<Account> accounts = await getAllAccounts();
      
      accounts = accounts.map((acc) => acc.copyWith(isActive: false)).toList();
      
      final existingIndex = accounts.indexWhere((a) => a.username == account.username);
      
      if (existingIndex >= 0) {
        accounts[existingIndex] = account.copyWith(
          isActive: true,
          lastLogin: DateTime.now(),
        );
        print('🔄 Аккаунт обновлен: ${account.username}');
      } else {
        final newAccount = account.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isActive: true,
          lastLogin: DateTime.now(),
        );
        accounts.add(newAccount);
        print('➕ Новый аккаунт добавлен: ${account.username}');
      }
      
      await _saveAccounts(accounts);
      await _setCurrentAccountId(account.id);
      
      print('📊 Всего аккаунтов: ${accounts.length}, активен: ${account.username}');
    } catch (e) {
      print('❌ Ошибка addAccount: $e');
      rethrow;
    }
  }

  /// Переключиться на другой аккаунт
  Future<void> switchAccount(String accountId) async {
    try {
      print('🔄 Переключение на аккаунт: $accountId');
      
      List<Account> accounts = await getAllAccounts();
      bool found = false;
      
      accounts = accounts.map((acc) => acc.copyWith(isActive: false)).toList();
      
      for (int i = 0; i < accounts.length; i++) {
        if (accounts[i].id == accountId) {
          accounts[i] = accounts[i].copyWith(
            isActive: true,
            lastLogin: DateTime.now(),
          );
          found = true;
          print('✅ Аккаунт активирован: ${accounts[i].username}');
          break;
        }
      }
      
      if (!found) {
        throw Exception('Аккаунт с ID $accountId не найден');
      }
      
      await _saveAccounts(accounts);
      await _setCurrentAccountId(accountId);
      
      final activeAccounts = accounts.where((a) => a.isActive).length;
      print('📊 Статистика: всего ${accounts.length} акк., активно: $activeAccounts');
      
      if (activeAccounts != 1) {
        print('⚠️ ВНИМАНИЕ: $activeAccounts активных аккаунтов (должен быть 1)');
      }
    } catch (e) {
      print('❌ Ошибка switchAccount: $e');
      rethrow;
    }
  }

  /// Удалить аккаунт
  Future<void> removeAccount(String accountId) async {
    try {
      List<Account> accounts = await getAllAccounts();
      final accountToRemove = accounts.firstWhere((a) => a.id == accountId);
      
      accounts.removeWhere((account) => account.id == accountId);
      
      if (accountToRemove.isActive && accounts.isNotEmpty) {
        accounts[0] = accounts[0].copyWith(isActive: true);
        await _setCurrentAccountId(accounts[0].id);
      }
      
      await _saveAccounts(accounts);
      print('🗑️ Аккаунт удален: ${accountToRemove.username}');
    } catch (e) {
      print('❌ Ошибка removeAccount: $e');
      rethrow;
    }
  }

  /// Получить текущий активный аккаунт
  Future<Account?> getCurrentAccount() async {
    try {
      final accounts = await getAllAccounts();
      
      final activeAccounts = accounts.where((a) => a.isActive).toList();
      
      if (activeAccounts.isEmpty) {
        print('⚠️ Нет активных аккаунтов');
        return null;
      }
      
      if (activeAccounts.length > 1) {
        print('⚠️ ВНИМАНИЕ: найдено ${activeAccounts.length} активных аккаунтов!');
        
        for (int i = 1; i < activeAccounts.length; i++) {
          final index = accounts.indexWhere((a) => a.id == activeAccounts[i].id);
          if (index >= 0) {
            accounts[index] = accounts[index].copyWith(isActive: false);
          }
        }
        await _saveAccounts(accounts);
        
        print('🛠️ Исправлено: теперь 1 активный аккаунт');
        return activeAccounts.first;
      }
      
      return activeAccounts.first;
    } catch (e) {
      print('❌ Ошибка getCurrentAccount: $e');
      return null;
    }
  }

  /// Обновить данные аккаунта
  Future<void> updateAccount(Account updatedAccount) async {
    try {
      List<Account> accounts = await getAllAccounts();
      final index = accounts.indexWhere((a) => a.id == updatedAccount.id);
      
      if (index >= 0) {
        accounts[index] = updatedAccount;
        await _saveAccounts(accounts);
        print('📝 Аккаунт обновлен: ${updatedAccount.username}');
      }
    } catch (e) {
      print('❌ Ошибка updateAccount: $e');
      rethrow;
    }
  }

  /// Восстановить корректность (только 1 активный аккаунт)
  Future<void> fixMultipleActiveAccounts() async {
    try {
      List<Account> accounts = await getAllAccounts();
      final activeAccounts = accounts.where((a) => a.isActive).toList();
      
      if (activeAccounts.length > 1) {
        print('🛠️ Исправляем ${activeAccounts.length} активных аккаунтов...');
        
        final mostRecent = activeAccounts.reduce((a, b) => 
          a.lastLogin.isAfter(b.lastLogin) ? a : b
        );
        
        for (int i = 0; i < accounts.length; i++) {
          accounts[i] = accounts[i].copyWith(
            isActive: accounts[i].id == mostRecent.id,
          );
        }
        
        await _saveAccounts(accounts);
        print('✅ Исправлено: теперь активен только ${mostRecent.username}');
      }
    } catch (e) {
      print('❌ Ошибка fixMultipleActiveAccounts: $e');
    }
  }

  /// Получить статистику
  Future<Map<String, dynamic>> getAccountsStats() async {
    final accounts = await getAllAccounts();
    final activeAccounts = accounts.where((a) => a.isActive).toList();
    
    return {
      'total': accounts.length,
      'active': activeAccounts.length,
      'multiple_active': activeAccounts.length > 1,
      'accounts': accounts.map((a) => {
        'username': a.username,
        'isActive': a.isActive,
        'lastLogin': a.lastLogin,
      }).toList(),
    };
  }

  /// Очистить все аккаунты
  Future<void> clearAllAccounts() async {
    try {
      await _storage.delete(key: _accountsKey);
      await _storage.delete(key: _currentAccountIdKey);
      print('🗑️ Все аккаунты очищены');
    } catch (e) {
      print('❌ Ошибка clearAllAccounts: $e');
    }
  }

  // Приватные методы
  Future<void> _saveAccounts(List<Account> accounts) async {
    final accountsJson = accounts.map((account) => account.toJson()).toList();
    await _storage.write(
      key: _accountsKey,
      value: jsonEncode(accountsJson),
    );
  }

  Future<void> _setCurrentAccountId(String accountId) async {
    await _storage.write(key: _currentAccountIdKey, value: accountId);
  }

  /// Отладочный метод для проверки состояния
  Future<void> debugAccounts() async {
    try {
      final accounts = await getAllAccounts();
      print('\n=== ДЕБАГ АККАУНТОВ ===');
      print('Всего аккаунтов: ${accounts.length}');
      
      for (var account in accounts) {
        print('👤 ${account.username}: активен=${account.isActive}, '
              'последний вход=${account.lastLogin}');
      }
      
      final active = accounts.where((a) => a.isActive).toList();
      print('Активных: ${active.length}');
      
      if (active.length != 1) {
        print('⚠️ ПРОБЛЕМА: ${active.length} активных аккаунтов!');
      }
      
      print('======================\n');
    } catch (e) {
      print('❌ Ошибка debugAccounts: $e');
    }
  }

  Future<void> saveAccountCredentials(String accountId, String username, String password) async {
    try {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'acc_${accountId}_username', value: username);
      await storage.write(key: 'acc_${accountId}_password', value: password);
      print('🔐 Учетные данные сохранены для аккаунта: $username');
    } catch (e) {
      print('❌ Ошибка сохранения учетных данных: $e');
    }
  }

  Future<Map<String, String?>> getAccountCredentials(String accountId) async {
    try {
      final storage = FlutterSecureStorage();
      final username = await storage.read(key: 'acc_${accountId}_username');
      final password = await storage.read(key: 'acc_${accountId}_password');
      
      return {
        'username': username,
        'password': password,
      };
    } catch (e) {
      print('❌ Ошибка получения учетных данных: $e');
      return {'username': null, 'password': null};
    }
  }
}