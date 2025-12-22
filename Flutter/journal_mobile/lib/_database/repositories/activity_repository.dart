import 'package:journal_mobile/models/activity_record.dart';
import '../database_service.dart';
import '../database_config.dart';

class ActivityRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveActivities(List<ActivityRecord> activities, String accountId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
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
          'lesson_subject': activity.lessonSubject,
          'lesson_theme': activity.lessonTheme,
          'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    });
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
      lessonSubject: data['lesson_subject'] as String?,
      lessonTheme: data['lesson_theme'] as String?,
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
      lessonSubject: data['lesson_subject'] as String?,
      lessonTheme: data['lesson_theme'] as String?,
    )).toList();
  }

  Future<DateTime?> getLastSyncTime(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT MAX(sync_timestamp) as last_sync FROM ${DatabaseConfig.tableActivityRecords} WHERE account_id = ?',
      [accountId],
    );
    
    if (result.isEmpty || result.first['last_sync'] == null) {
      return null;
    }
    
    final timestamp = result.first['last_sync'] as int;
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  Future<int> getActivitiesCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableActivityRecords} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
} // tableActivityRecords