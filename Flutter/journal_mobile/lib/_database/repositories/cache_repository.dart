import 'dart:convert';
import '../database_service.dart';
import '../database_config.dart';

class CacheRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> save(
    String key, 
    dynamic value, {
    String? accountId,
    Duration? expiry,
  }) async {
    final expiryTimestamp = expiry != null 
      ? DateTime.now().add(expiry).millisecondsSinceEpoch 
      : null;

    await _dbService.insert(DatabaseConfig.tableCache, {
      'key': key,
      'account_id': accountId,
      'value': jsonEncode(value),
    });
  }

  Future<T?> get<T>(String key, {String? accountId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final cacheData = await _dbService.query(
      DatabaseConfig.tableCache,
      where: 'key = ? AND (account_id = ? OR account_id IS NULL)',
      whereArgs: [key, accountId],
      limit: 1,
    );

    if (cacheData.isEmpty) return null;

    final data = cacheData.first;

    try {
      final value = jsonDecode(data['value'] as String);
      return value as T;
    } catch (e) {
      return null;
    }
  }

  Future<void> remove(String key, {String? accountId}) async {
    await _dbService.delete(
      DatabaseConfig.tableCache,
      where: 'key = ? AND (account_id = ? OR account_id IS NULL)',
      whereArgs: [key, accountId],
    );
  }

  Future<void> clear({String? accountId}) async {
    if (accountId != null) {
      await _dbService.delete(
        DatabaseConfig.tableCache,
        where: 'account_id = ?',
        whereArgs: [accountId],
      );
    } else {
      await _dbService.delete(DatabaseConfig.tableCache);
    }
  }

  Future<void> cleanupExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await _dbService.delete(
      DatabaseConfig.tableCache,
      whereArgs: [now],
    );
  }

  Future<int> getCacheSize({String? accountId}) async {
    if (accountId != null) {
      final result = await _dbService.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableCache} WHERE account_id = ?',
        [accountId],
      );
      return result.isEmpty ? 0 : result.first['count'] as int;
    } else {
      final result = await _dbService.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableCache}',
      );
      return result.isEmpty ? 0 : result.first['count'] as int;
    }
  }
} // tableCache