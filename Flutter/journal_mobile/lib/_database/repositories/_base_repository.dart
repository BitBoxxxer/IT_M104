import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../database_config.dart';

abstract class BaseRepository<T> {
  final DatabaseService _dbService = DatabaseService();
  
  DatabaseService get dbService => _dbService;
  
  String getUniqueKey(T item);
  
  /// Преобразование в Map для вставки в БД
  Map<String, dynamic> toMap(T item, String accountId);
  
  /// Преобразование из Map
  T fromMap(Map<String, dynamic> map);
  
  /// Получить имя таблицы
  String get tableName;
  
  /// Получить список полей для уникального ключа (для WHERE в обновлении)
  Map<String, dynamic> getUniqueWhereClause(T item);
  
  /// Основной метод сохранения с выбранной стратегией
  Future<void> saveItems(
    List<T> items, 
    String accountId, {
    SyncStrategy strategy = DatabaseConfig.syncStrategy,
    String? extraWhere,
    List<Object?>? extraWhereArgs,
    bool cleanupMissing = DatabaseConfig.cleanupMissingItems,
  }) async {
    final db = await _dbService.database;
    
    await db.transaction((txn) async {
      switch (strategy) {
        case SyncStrategy.replace:
          await _saveWithReplace(txn, items, accountId, extraWhere, extraWhereArgs);
          break;
        case SyncStrategy.merge:
          await _saveWithMerge(txn, items, accountId, extraWhere, extraWhereArgs, cleanupMissing);
          break;
        case SyncStrategy.append:
          await _saveWithAppend(txn, items, accountId);
          break;
      }
    });
  }
  
  /// Стратегия 1: Переписать всю таблицу с нуля
  Future<void> _saveWithReplace(
    Transaction txn,
    List<T> items,
    String accountId,
    String? extraWhere,
    List<Object?>? extraWhereArgs,
  ) async {
    String whereClause = 'account_id = ?';
    final whereArgs = <Object?>[accountId];
    
    if (extraWhere != null && extraWhereArgs != null) {
      whereClause += ' AND $extraWhere';
      whereArgs.addAll(extraWhereArgs);
    }
    
    await txn.delete(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    for (final item in items) {
      await txn.insert(
        tableName,
        toMap(item, accountId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
  
  /// Стратегия 2: Объединить (обновить существующие, добавить новые)
  Future<void> _saveWithMerge(
    Transaction txn,
    List<T> items,
    String accountId,
    String? extraWhere,
    List<Object?>? extraWhereArgs,
    bool cleanupMissing,
  ) async {
    final existingItems = await _getExistingItems(txn, accountId, extraWhere, extraWhereArgs);
    final existingKeys = existingItems.map(getUniqueKey).toSet();
    
    final itemsToUpdate = <T>[];
    final itemsToInsert = <T>[];
    
    for (final item in items) {
      if (existingKeys.contains(getUniqueKey(item))) {
        itemsToUpdate.add(item);
      } else {
        itemsToInsert.add(item);
      }
    }
    
    for (final item in itemsToUpdate) {
      await _updateItem(txn, item, accountId);
    }
    
    for (final item in itemsToInsert) {
      await txn.insert(
        tableName,
        toMap(item, accountId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    if (cleanupMissing) {
      await _cleanupMissingItems(txn, items, accountId, extraWhere, extraWhereArgs);
    }
  }
  
  /// Стратегия 3: Добавить (без удаления старых)
  Future<void> _saveWithAppend(
    Transaction txn,
    List<T> items,
    String accountId,
  ) async {
    for (final item in items) {
      await txn.insert(
        tableName,
        toMap(item, accountId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
  
  /// Получить существующие записи
  Future<List<T>> _getExistingItems(
    Transaction txn, 
    String accountId,
    String? extraWhere,
    List<Object?>? extraWhereArgs,
  ) async {
    final whereClause = _buildWhereClause(extraWhere);
    final whereArgs = _buildWhereArgs(accountId, extraWhereArgs);
    
    final maps = await txn.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.map(fromMap).toList();
  }
  
  /// Обновить запись (базовая реализация)
  Future<void> _updateItem(Transaction txn, T item, String accountId) async {
    final map = toMap(item, accountId);
    final whereClause = _buildUpdateWhereClause(item, accountId);
    
    map.removeWhere((key, value) => key == 'id' || key == 'account_id');
    
    await txn.update(
      tableName,
      map,
      where: whereClause.where,
      whereArgs: whereClause.args,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Очистить записи, которых нет в новых данных
  Future<void> _cleanupMissingItems(
    Transaction txn,
    List<T> newItems,
    String accountId,
    String? extraWhere,
    List<Object?>? extraWhereArgs,
  ) async {
    final existingItems = await _getExistingItems(txn, accountId, extraWhere, extraWhereArgs);
    final newKeys = newItems.map(getUniqueKey).toSet();
    
    for (final existingItem in existingItems) {
      if (!newKeys.contains(getUniqueKey(existingItem))) {
        await _deleteItem(txn, existingItem, accountId);
      }
    }
  }
  
  /// Удалить конкретную запись
  Future<void> _deleteItem(Transaction txn, T item, String accountId) async {
    final whereClause = _buildUpdateWhereClause(item, accountId);
    await txn.delete(
      tableName,
      where: whereClause.where,
      whereArgs: whereClause.args,
    );
  }
  
  /// Построить WHERE для запроса
  String _buildWhereClause(String? extraWhere) {
    final baseWhere = 'account_id = ?';
    if (extraWhere == null) return baseWhere;
    return '$baseWhere AND $extraWhere';
  }
  
  /// Построить аргументы для WHERE
  List<Object?> _buildWhereArgs(String accountId, List<Object?>? extraArgs) {
    if (extraArgs == null) return [accountId];
    return [accountId, ...extraArgs];
  }
  
  /// Построить WHERE для обновления
  WhereClause _buildUpdateWhereClause(T item, String accountId) {
    final uniqueClause = getUniqueWhereClause(item);
    
    final whereParts = <String>['account_id = ?'];
    final args = <Object?>[accountId];
    
    uniqueClause.forEach((key, value) {
      whereParts.add('$key = ?');
      args.add(value);
    });
    
    return WhereClause(
      where: whereParts.join(' AND '),
      args: args,
    );
  }
}

/// Вспомогательный класс для WHERE условия
class WhereClause {
  final String where;
  final List<Object?> args;
  
  WhereClause({required this.where, required this.args});
}