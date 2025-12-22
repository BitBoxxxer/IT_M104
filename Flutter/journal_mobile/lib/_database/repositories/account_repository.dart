// В файле account_repository.dart
import '../../models/_system/account_model.dart';
import '../database_config.dart';
import '../database_service.dart';

class AccountRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveAccount(Account account) async {
    await _dbService.insert(DatabaseConfig.tableAccounts, {
      'id': account.id,
      'username': account.username,
      'full_name': account.fullName,
      'group_name': account.groupName,
      'photo_path': account.photoPath,
      'token': account.token,
      'last_login': account.lastLogin.toIso8601String(), // Исправлено: храним как строку
      'is_active': account.isActive ? 1 : 0,
      'student_id': account.studentId,
    });
  }

  Future<List<Account>> getAllAccounts() async {
    final accountsData = await _dbService.query(
      DatabaseConfig.tableAccounts,
      orderBy: 'last_login DESC',
    );

    return accountsData.map((data) {
      try {
        // Парсим строку даты
        DateTime lastLogin;
        if (data['last_login'] is int) {
          // Если хранится как timestamp
          lastLogin = DateTime.fromMillisecondsSinceEpoch(data['last_login'] as int);
        } else if (data['last_login'] is String) {
          // Если хранится как строка ISO
          lastLogin = DateTime.parse(data['last_login'] as String);
        } else {
          lastLogin = DateTime.now();
        }

        return Account.fromJson({
          'id': data['id'].toString(),
          'username': data['username'].toString(),
          'fullName': data['full_name'].toString(),
          'groupName': data['group_name'].toString(),
          'photoPath': data['photo_path'].toString(),
          'token': data['token'].toString(),
          'lastLogin': lastLogin.toIso8601String(), // Преобразуем в строку
          'isActive': (data['is_active'] as int?) == 1,
          'studentId': (data['student_id'] as int?) ?? 0,
        });
      } catch (e) {
        print('❌ Ошибка парсинга аккаунта: $e');
        // Возвращаем заглушку
        return Account(
          id: 'error',
          username: 'Ошибка',
          fullName: 'Ошибка парсинга',
          groupName: '',
          photoPath: '',
          token: '',
          lastLogin: DateTime.now(),
          isActive: false,
          studentId: 0,
        );
      }
    }).toList();
  }

  Future<Account?> getAccountById(String accountId) async {
    final accountsData = await _dbService.query(
      DatabaseConfig.tableAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (accountsData.isEmpty) return null;

    final data = accountsData.first;
    try {
      // Парсим строку даты
      DateTime lastLogin;
      if (data['last_login'] is int) {
        lastLogin = DateTime.fromMillisecondsSinceEpoch(data['last_login'] as int);
      } else if (data['last_login'] is String) {
        lastLogin = DateTime.parse(data['last_login'] as String);
      } else {
        lastLogin = DateTime.now();
      }

      return Account.fromJson({
        'id': data['id'].toString(),
        'username': data['username'].toString(),
        'fullName': data['full_name'].toString(),
        'groupName': data['group_name'].toString(),
        'photoPath': data['photo_path'].toString(),
        'token': data['token'].toString(),
        'lastLogin': lastLogin.toIso8601String(),
        'isActive': (data['is_active'] as int?) == 1,
        'studentId': (data['student_id'] as int?) ?? 0,
      });
    } catch (e) {
      print('❌ Ошибка парсинга аккаунта по ID: $e');
      return null;
    }
  }

  Future<Account?> getCurrentAccount() async {
    final accountsData = await _dbService.query(
      DatabaseConfig.tableAccounts,
      where: 'is_active = 1',
      limit: 1,
    );

    if (accountsData.isEmpty) return null;

    final data = accountsData.first;
    try {
      // Парсим строку даты
      DateTime lastLogin;
      if (data['last_login'] is int) {
        lastLogin = DateTime.fromMillisecondsSinceEpoch(data['last_login'] as int);
      } else if (data['last_login'] is String) {
        lastLogin = DateTime.parse(data['last_login'] as String);
      } else {
        lastLogin = DateTime.now();
      }

      return Account.fromJson({
        'id': data['id'].toString(),
        'username': data['username'].toString(),
        'fullName': data['full_name'].toString(),
        'groupName': data['group_name'].toString(),
        'photoPath': data['photo_path'].toString(),
        'token': data['token'].toString(),
        'lastLogin': lastLogin.toIso8601String(),
        'isActive': (data['is_active'] as int?) == 1,
        'studentId': (data['student_id'] as int?) ?? 0,
      });
    } catch (e) {
      print('❌ Ошибка парсинга текущего аккаунта: $e');
      return null;
    }
  }

  Future<void> deleteAccount(String accountId) async {
    await _dbService.delete(
      DatabaseConfig.tableAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  /// Очистить все аккаунты
  Future<void> deleteAllAccounts() async {
    await _dbService.delete(DatabaseConfig.tableAccounts);
  }

  Future<void> setCurrentAccount(String accountId) async {
    // Сначала сбрасываем все флаги активности
    await _dbService.update(
      DatabaseConfig.tableAccounts,
      {'is_active': 0},
      where: '1=1',
    );

    // Устанавливаем активный аккаунт
    await _dbService.update(
      DatabaseConfig.tableAccounts,
      {
        'is_active': 1,
        'last_login': DateTime.now().toIso8601String(), // Исправлено: сохраняем как строку
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> updateAccountToken(String accountId, String token) async {
    await _dbService.update(
      DatabaseConfig.tableAccounts,
      {
        'token': token,
        'last_login': DateTime.now().toIso8601String(), // Исправлено: сохраняем как строку
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<int> getAccountsCount() async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableAccounts}',
    );
    
    if (result.isEmpty) return 0;
    return result.first['count'] as int;
  }
}