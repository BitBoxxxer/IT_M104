// lib/services/_database/repositories/mark_repository.dart
import 'package:journal_mobile/models/mark.dart';
import '../database_service.dart';
import '../database_config.dart';

class MarkRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveMarks(List<Mark> marks, String accountId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Удаляем старые оценки для этого аккаунта
      await txn.delete(
        DatabaseConfig.tableMarks,
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      // Вставляем новые
      for (final mark in marks) {
        await txn.insert(DatabaseConfig.tableMarks, {
          'account_id': accountId,
          'spec_name': mark.specName,
          'lesson_theme': mark.lessonTheme,
          'date_visit': mark.dateVisit,
          'home_work_mark': mark.homeWorkMark,
          'control_work_mark': mark.controlWorkMark,
          'lab_work_mark': mark.labWorkMark,
          'class_work_mark': mark.classWorkMark,
          'practical_work_mark': mark.practicalWorkMark,
          'final_work_mark': mark.finalWorkMark,
          'status_was': mark.statusWas,
          'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    });
  }

  Future<List<Mark>> getMarks(String accountId) async {
    final marksData = await _dbService.query(
      DatabaseConfig.tableMarks,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date_visit DESC',
    );

    return marksData.map((data) => Mark.fromJson({
      'spec_name': data['spec_name'],
      'lesson_theme': data['lesson_theme'],
      'date_visit': data['date_visit'],
      'home_work_mark': data['home_work_mark'],
      'control_work_mark': data['control_work_mark'],
      'lab_work_mark': data['lab_work_mark'],
      'class_work_mark': data['class_work_mark'],
      'practical_work_mark': data['practical_work_mark'],
      'final_work_mark': data['final_work_mark'],
      'status_was': data['status_was'],
    })).toList();
  }

  Future<List<Mark>> getRecentMarks(String accountId, int limit) async {
    final marksData = await _dbService.query(
      DatabaseConfig.tableMarks,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'sync_timestamp DESC',
      limit: limit,
    );

    return marksData.map((data) => Mark.fromJson({
      'spec_name': data['spec_name'],
      'lesson_theme': data['lesson_theme'],
      'date_visit': data['date_visit'],
      'home_work_mark': data['home_work_mark'],
      'control_work_mark': data['control_work_mark'],
      'lab_work_mark': data['lab_work_mark'],
      'class_work_mark': data['class_work_mark'],
      'practical_work_mark': data['practical_work_mark'],
      'final_work_mark': data['final_work_mark'],
      'status_was': data['status_was'],
    })).toList();
  }

  Future<DateTime?> getLastSyncTime(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT MAX(sync_timestamp) as last_sync FROM ${DatabaseConfig.tableMarks} WHERE account_id = ?',
      [accountId],
    );
    
    if (result.isEmpty || result.first['last_sync'] == null) {
      return null;
    }
    
    final timestamp = result.first['last_sync'] as int;
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  Future<int> getMarksCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableMarks} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
} // tableMarks