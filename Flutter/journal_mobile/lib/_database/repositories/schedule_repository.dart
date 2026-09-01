import 'package:journal_mobile/models/days_element.dart';
import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../database_config.dart';

class ScheduleRepository {
  final DatabaseService _dbService = DatabaseService();

  /// Сохранить расписание.
  ///
  /// ВАЖНО: раньше этот метод удалял ВСЁ расписание аккаунта (`WHERE account_id = ?`)
  /// перед вставкой новых данных. Из-за этого при сохранении, например, следующей
  /// недели — текущая неделя стиралась (и наоборот), потому что каждый вызов
  /// перетирал весь стол целиком, а не только те дни, которые реально пришли
  /// с сервера.
  ///
  /// Теперь можно (и нужно) передавать [weekStart]/[weekEnd] — диапазон дат,
  /// за который реально запрашивались данные. Тогда чистятся только записи
  /// внутри этого диапазона (это заодно правильно убирает пары, которые
  /// пропали/перенеслись на сервере), а все остальные недели остаются нетронутыми.
  ///
  /// Если диапазон не передан — он определяется по минимальной/максимальной
  /// дате в самом списке [schedule] (на случай старых вызовов без диапазона).
  /// Если список пустой и диапазон не передан — ничего не удаляем и не трогаем БД,
  /// чтобы случайно не стереть всё расписание пустым ответом с сервера.
  Future<void> saveSchedule(
    List<ScheduleElement> schedule,
    String accountId, {
    DateTime? weekStart,
    DateTime? weekEnd,
  }) async {
    final db = await _dbService.database;

    String? startDate;
    String? endDate;

    if (weekStart != null && weekEnd != null) {
      startDate = _formatDate(weekStart);
      endDate = _formatDate(weekEnd);
    } else if (schedule.isNotEmpty) {
      final dates = schedule.map((e) => e.date).toList()..sort();
      startDate = dates.first;
      endDate = dates.last;
    }

    await db.transaction((txn) async {
      if (startDate != null && endDate != null) {
        await txn.delete(
          DatabaseConfig.tableSchedule,
          where: 'account_id = ? AND date BETWEEN ? AND ?',
          whereArgs: [accountId, startDate, endDate],
        );
      }

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
        }, conflictAlgorithm: ConflictAlgorithm.replace,);
      }
    });
  }

  /// Удалить записи расписания старше [before] (используется для чистки старых
  /// данных). В отличие от saveSchedule, это explicit удаление по дате, а не
  /// побочный эффект сохранения новой недели.
  Future<int> deleteScheduleBefore(String accountId, DateTime before) async {
    final db = await _dbService.database;
    return await db.delete(
      DatabaseConfig.tableSchedule,
      where: 'account_id = ? AND date < ?',
      whereArgs: [accountId, _formatDate(before)],
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

  Future<int> getScheduleCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableSchedule} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
} // tableSchedule