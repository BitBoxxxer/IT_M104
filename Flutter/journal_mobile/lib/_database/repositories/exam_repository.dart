import 'package:journal_mobile/models/_widgets/exams/exam.dart';
import '../database_service.dart';
import '../database_config.dart';

class ExamRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveExams(List<Exam> exams, String accountId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseConfig.tableExams,
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      for (final exam in exams) {
        await txn.insert(DatabaseConfig.tableExams, {
          'account_id': accountId,
          'spec': exam.subjectName,
          'mark': exam.grade,
          'date': exam.date,
          'teacher': exam.teacherName,
          'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    });
  }

  Future<List<Exam>> getExams(String accountId) async {
    final examsData = await _dbService.query(
      DatabaseConfig.tableExams,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date ASC',
    );

    return examsData.map((data) => Exam.fromJson({
      'spec': data['spec'],
      'mark': data['mark'],
      'date': data['date'],
      'teacher': data['teacher'],
    })).toList();
  }

  Future<List<Exam>> getFutureExams(String accountId) async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T').first;

    final examsData = await _dbService.query(
      DatabaseConfig.tableExams,
      where: 'account_id = ? AND date >= ?',
      whereArgs: [accountId, today],
      orderBy: 'date ASC',
    );

    return examsData.map((data) => Exam.fromJson({
      'spec': data['spec'],
      'mark': data['mark'],
      'date': data['date'],
      'teacher': data['teacher'],
    })).toList();
  }

  Future<DateTime?> getLastSyncTime(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT MAX(sync_timestamp) as last_sync FROM ${DatabaseConfig.tableExams} WHERE account_id = ?',
      [accountId],
    );
    
    if (result.isEmpty || result.first['last_sync'] == null) {
      return null;
    }
    
    final timestamp = result.first['last_sync'] as int;
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  Future<int> getExamsCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableExams} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
}