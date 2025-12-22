import 'package:journal_mobile/models/days_element.dart';
import '../database_service.dart';
import '../database_config.dart';

class ScheduleRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveSchedule(List<ScheduleElement> schedule, String accountId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Удаляем старые данные расписания
      await txn.delete(
        DatabaseConfig.tableSchedule,
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      // Вставляем новые данные
      for (final element in schedule) {
        await txn.insert(DatabaseConfig.tableSchedule, {
          'account_id': accountId,
          'date': element.date,
          'started_at': element.startedAt,
          'finished_at': element.finishedAt,
          'lesson': element.lesson,
          'room_name': element.roomName,
          'subject_name': element.subjectName,
          'teacher_name': element.teacherName,
          'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    });
  }

  Future<List<ScheduleElement>> getSchedule(String accountId) async {
    final scheduleData = await _dbService.query(
      DatabaseConfig.tableSchedule,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date ASC, lesson ASC',
    );

    return scheduleData.map((data) => ScheduleElement.fromJson({
      'date': data['date'],
      'started_at': data['started_at'],
      'finished_at': data['finished_at'],
      'lesson': data['lesson'],
      'room_name': data['room_name'],
      'subject_name': data['subject_name'],
      'teacher_name': data['teacher_name'],
    })).toList();
  }

  Future<List<ScheduleElement>> getScheduleByDateRange(
    String accountId, 
    DateTime start, 
    DateTime end
  ) async {
    final startDate = start.toIso8601String().split('T').first;
    final endDate = end.toIso8601String().split('T').first;

    final scheduleData = await _dbService.query(
      DatabaseConfig.tableSchedule,
      where: 'account_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [accountId, startDate, endDate],
      orderBy: 'date ASC, lesson ASC',
    );

    return scheduleData.map((data) => ScheduleElement.fromJson({
      'date': data['date'],
      'started_at': data['started_at'],
      'finished_at': data['finished_at'],
      'lesson': data['lesson'],
      'room_name': data['room_name'],
      'subject_name': data['subject_name'],
      'teacher_name': data['teacher_name'],
    })).toList();
  }

  Future<DateTime?> getLastSyncTime(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT MAX(sync_timestamp) as last_sync FROM ${DatabaseConfig.tableSchedule} WHERE account_id = ?',
      [accountId],
    );
    
    if (result.isEmpty || result.first['last_sync'] == null) {
      return null;
    }
    
    final timestamp = result.first['last_sync'] as int;
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  Future<int> getScheduleCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableSchedule} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
} // tableSchedule