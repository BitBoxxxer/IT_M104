import 'package:journal_mobile/models/activity_record.dart';
import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../database_config.dart';

class ActivityRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveActivities(
    List<ActivityRecord> activities, 
    String accountId, {
    SyncStrategy strategy = SyncStrategy.merge,
  }) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      switch (strategy) {
        case SyncStrategy.replace:
          await txn.delete(
            DatabaseConfig.tableActivityRecords,
            where: 'account_id = ?',
            whereArgs: [accountId],
          );
          
          for (final activity in activities) {
            await txn.insert(
              DatabaseConfig.tableActivityRecords,
              _toMap(activity, accountId),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;
          
        case SyncStrategy.merge:
          final existing = await _getExistingItemsForDates(
            txn, 
            accountId, 
            activities.map((a) => a.date).toList(),
          );
          final existingKeys = existing.map((a) => _getUniqueKey(a)).toSet();
          
          for (final activity in activities) {
            if (existingKeys.contains(_getUniqueKey(activity))) {
              await _updateItem(txn, activity, accountId);
            } else {
              await txn.insert(
                DatabaseConfig.tableActivityRecords,
                _toMap(activity, accountId),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
          break;
          
        case SyncStrategy.append:
          for (final activity in activities) {
            await txn.insert(
              DatabaseConfig.tableActivityRecords,
              _toMap(activity, accountId),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          break;
      }
    });
    
    print('✅ Активности сохранены (стратегия: $strategy): ${activities.length} шт');
  }

  Future<List<ActivityRecord>> getActivities(String accountId) async {
    final activitiesData = await _dbService.query(
      DatabaseConfig.tableActivityRecords,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );

    return activitiesData.map(_fromMap).toList();
  }

  Future<List<ActivityRecord>> getRecentActivities(String accountId, int limit) async {
    final activitiesData = await _dbService.query(
      DatabaseConfig.tableActivityRecords,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
      limit: limit,
    );

    return activitiesData.map(_fromMap).toList();
  }

  Future<int> getActivitiesCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableActivityRecords} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
  
  // ====== Вспомогательные методы ======
  
  Map<String, dynamic> _toMap(ActivityRecord activity, String accountId) {
    return {
      'account_id': accountId,
      'date': activity.date,
      'action': activity.action,
      'current_point': activity.currentPoint,
      'point_types_id': activity.pointTypesId,
      'point_types_name': activity.pointTypesName,
      'achievements_id': activity.achievementsId,
      'achievements_name': activity.achievementsName,
      'achievements_type': activity.achievementsType,
      'badge': activity.badge,
      'old_competition': activity.oldCompetition ? 1 : 0,
    };
  }
  
  ActivityRecord _fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      date: map['date'] as String,
      action: map['action'] as int,
      currentPoint: map['current_point'] as int,
      pointTypesId: map['point_types_id'] as int,
      pointTypesName: map['point_types_name'] as String,
      achievementsId: map['achievements_id'] as int?,
      achievementsName: map['achievements_name'] as String?,
      achievementsType: map['achievements_type'] as int?,
      badge: map['badge'] as int,
      oldCompetition: map['old_competition'] == 1,
    );
  }
  
  Future<List<ActivityRecord>> _getExistingItemsForDates(
    Transaction txn, 
    String accountId,
    List<String> dates,
  ) async {
    if (dates.isEmpty) return [];
    
    final placeholders = List.filled(dates.length, '?').join(',');
    final maps = await txn.query(
      DatabaseConfig.tableActivityRecords,
      where: 'account_id = ? AND date IN ($placeholders)',
      whereArgs: [accountId, ...dates],
    );
    
    return maps.map(_fromMap).toList();
  }
  
  String _getUniqueKey(ActivityRecord activity) {
    return activity.date;
  }
  
  Future<void> _updateItem(Transaction txn, ActivityRecord activity, String accountId) async {
    await txn.update(
      DatabaseConfig.tableActivityRecords,
      {
        'action': activity.action,
        'current_point': activity.currentPoint,
        'point_types_id': activity.pointTypesId,
        'point_types_name': activity.pointTypesName,
        'achievements_id': activity.achievementsId,
        'achievements_name': activity.achievementsName,
        'achievements_type': activity.achievementsType,
        'badge': activity.badge,
        'old_competition': activity.oldCompetition ? 1 : 0,
      },
      where: 'account_id = ? AND date = ?',
      whereArgs: [accountId, activity.date],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Бэквард-совместимость: старый метод с replace стратегией
  Future<void> saveActivitiesLegacy(List<ActivityRecord> activities, String accountId) async {
    await saveActivities(activities, accountId, strategy: SyncStrategy.replace);
  }
  
  Future<void> cleanupDuplicates(String accountId) async {
    final db = await _dbService.database;
    await db.execute('''
      DELETE FROM ${DatabaseConfig.tableActivityRecords}
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM ${DatabaseConfig.tableActivityRecords}
        WHERE account_id = ?
        GROUP BY date
      ) AND account_id = ?
    ''', [accountId, accountId]);
    
    print('🧹 Очищены дубликаты активностей для аккаунта: $accountId');
  }
} // tableActivityRecords