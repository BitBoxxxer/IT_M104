import 'package:journal_mobile/models/activity_record.dart';
import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../database_config.dart';

class ActivityRepository {
  final DatabaseService _dbService = DatabaseService();

  /// Сохранить активности с выбором стратегии
  Future<void> saveActivities(
    List<ActivityRecord> activities, 
    String accountId, {
    SyncStrategy strategy = SyncStrategy.append, // По умолчанию append
  }) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      switch (strategy) {
        case SyncStrategy.replace:
          // Удаляем старые активности
          await txn.delete(
            DatabaseConfig.tableActivityRecords,
            where: 'account_id = ?',
            whereArgs: [accountId],
          );
          
          // Вставляем новые
          for (final activity in activities) {
            await txn.insert(DatabaseConfig.tableActivityRecords, {
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
            }, conflictAlgorithm: ConflictAlgorithm.replace,);
          }
          break;
          
        case SyncStrategy.merge:
          // Получаем существующие записи
          final existing = await _getExistingItems(txn, accountId);
          final existingKeys = existing.map((a) => _getUniqueKey(a)).toSet();
          
          // Разделяем на обновляемые и новые
          final toUpdate = <ActivityRecord>[];
          final toInsert = <ActivityRecord>[];
          
          for (final activity in activities) {
            if (existingKeys.contains(_getUniqueKey(activity))) {
              toUpdate.add(activity);
            } else {
              toInsert.add(activity);
            }
          }
          
          // Обновляем существующие
          for (final activity in toUpdate) {
            await _updateItem(txn, activity, accountId);
          }
          
          // Вставляем новые
          for (final activity in toInsert) {
            await txn.insert(DatabaseConfig.tableActivityRecords, {
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
            }, conflictAlgorithm: ConflictAlgorithm.replace,);
          }
          break;
          
        case SyncStrategy.append:
          // Только добавляем новые, не удаляем и не обновляем
          for (final activity in activities) {
            await txn.insert(DatabaseConfig.tableActivityRecords, {
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
            }, conflictAlgorithm: ConflictAlgorithm.ignore,); // Используем ignore, чтобы не перезаписывать
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

    return activitiesData.map((data) => ActivityRecord(
      date: data['date'] as String,
      action: data['action'] as int,
      currentPoint: data['current_point'] as int,
      pointTypesId: data['point_types_id'] as int,
      pointTypesName: data['point_types_name'] as String,
      achievementsId: data['achievements_id'] as int?,
      achievementsName: data['achievements_name'] as String?,
      achievementsType: data['achievements_type'] as int?,
      badge: data['badge'] as int,
      oldCompetition: data['old_competition'] == 1,
    )).toList();
  }

  Future<List<ActivityRecord>> getRecentActivities(String accountId, int limit) async {
    final activitiesData = await _dbService.query(
      DatabaseConfig.tableActivityRecords,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
      limit: limit,
    );

    return activitiesData.map((data) => ActivityRecord(
      date: data['date'] as String,
      action: data['action'] as int,
      currentPoint: data['current_point'] as int,
      pointTypesId: data['point_types_id'] as int,
      pointTypesName: data['point_types_name'] as String,
      achievementsId: data['achievements_id'] as int?,
      achievementsName: data['achievements_name'] as String?,
      achievementsType: data['achievements_type'] as int?,
      badge: data['badge'] as int,
      oldCompetition: data['old_competition'] == 1,
    )).toList();
  }

  Future<int> getActivitiesCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableActivityRecords} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
  
  // ====== Вспомогательные методы для merge стратегии ======
  
  Future<List<ActivityRecord>> _getExistingItems(Transaction txn, String accountId) async {
    final maps = await txn.query(
      DatabaseConfig.tableActivityRecords,
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    return maps.map((data) => ActivityRecord(
      date: data['date'] as String,
      action: data['action'] as int,
      currentPoint: data['current_point'] as int,
      pointTypesId: data['point_types_id'] as int,
      pointTypesName: data['point_types_name'] as String,
      achievementsId: data['achievements_id'] as int?,
      achievementsName: data['achievements_name'] as String?,
      achievementsType: data['achievements_type'] as int?,
      badge: data['badge'] as int,
      oldCompetition: data['old_competition'] == 1,
    )).toList();
  }
  
  String _getUniqueKey(ActivityRecord activity) {
    return '${activity.date}_${activity.pointTypesId}_${activity.achievementsId}_${activity.action}';
  }
  
  Future<void> _updateItem(Transaction txn, ActivityRecord activity, String accountId) async {
    await txn.update(
      DatabaseConfig.tableActivityRecords,
      {
        'current_point': activity.currentPoint,
        'point_types_name': activity.pointTypesName,
        'achievements_name': activity.achievementsName,
        'achievements_type': activity.achievementsType,
        'badge': activity.badge,
        'old_competition': activity.oldCompetition ? 1 : 0,
      },
      where: 'account_id = ? AND date = ? AND point_types_id = ? AND achievements_id = ? AND action = ?',
      whereArgs: [
        accountId, 
        activity.date, 
        activity.pointTypesId, 
        activity.achievementsId, 
        activity.action
      ],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Бэквард-совместимость: старый метод с replace стратегией
  Future<void> saveActivitiesLegacy(List<ActivityRecord> activities, String accountId) async {
    await saveActivities(activities, accountId, strategy: SyncStrategy.replace);
  }
} // tableActivityRecords