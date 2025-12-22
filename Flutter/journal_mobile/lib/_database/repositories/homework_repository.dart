// lib/services/_database/repositories/homework_repository.dart
import 'dart:convert';
import 'package:journal_mobile/models/_widgets/homework/homework.dart';
import 'package:journal_mobile/models/_widgets/homework/homework_counter.dart';
import '../database_service.dart';
import '../database_config.dart';

class HomeworkRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveHomeworks(List<Homework> homeworks, String accountId, {int? materialType}) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Удаляем старые задания (с учетом типа материала, если указан)
      if (materialType != null) {
        await txn.delete(
          DatabaseConfig.tableHomeworks,
          where: 'account_id = ? AND material_type = ?',
          whereArgs: [accountId, materialType],
        );
      } else {
        await txn.delete(
          DatabaseConfig.tableHomeworks,
          where: 'account_id = ?',
          whereArgs: [accountId],
        );
      }

      // Вставляем новые задания
      for (final homework in homeworks) {
        await txn.insert(DatabaseConfig.tableHomeworks, {
          'account_id': accountId,
          'id': homework.id,
          'teacher_work_id': homework.teacherWorkId,
          'subject_name': homework.subjectName,
          'theme': homework.theme,
          'description': homework.description,
          'creation_time': homework.creationTime.millisecondsSinceEpoch,
          'completion_time': homework.completionTime.millisecondsSinceEpoch,
          'overdue_time': homework.overdueTime?.millisecondsSinceEpoch,
          'filename': homework.filename,
          'file_path': homework.filePath,
          'comment': homework.comment,
          'status': homework.status,
          'common_status': homework.commonStatus,
          'homework_stud': homework.homeworkStud != null ? jsonEncode(homework.homeworkStud!.toJson()) : null,
          'homework_comment': homework.homeworkComment != null ? jsonEncode(homework.homeworkComment!.toJson()) : null,
          'cover_image': homework.coverImage,
          'teacher_name': homework.teacherName,
          'material_type': homework.materialType ?? materialType ?? 0,
          'is_deleted': homework.isDeleted == true ? 1 : 0,
          'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    });
  }

  Future<List<Homework>> getHomeworks(
    String accountId, {
    int? materialType,
    int? status,
    int? page,
    int? limit,
  }) async {
    final queryBuilder = StringBuffer();
    final whereArgs = <dynamic>[accountId];
    
    queryBuilder.write('account_id = ?');
    
    if (materialType != null) {
      queryBuilder.write(' AND material_type = ?');
      whereArgs.add(materialType);
    }
    
    if (status != null) {
      queryBuilder.write(' AND status = ?');
      whereArgs.add(status);
    }

    queryBuilder.write(' AND (is_deleted IS NULL OR is_deleted = 0)');

    String orderBy = 'completion_time ASC';
    String limitClause = '';
    
    if (page != null && limit != null) {
      final offset = (page - 1) * limit;
      limitClause = 'LIMIT $limit OFFSET $offset';
    }

    final homeworksData = await _dbService.rawQuery('''
      SELECT * FROM ${DatabaseConfig.tableHomeworks}
      WHERE $queryBuilder
      ORDER BY $orderBy
      $limitClause
    ''', whereArgs);

    return homeworksData.map((data) {
      try {
        // Парсим вложенные объекты
        HomeworkStud? homeworkStud;
        if (data['homework_stud'] != null) {
          try {
            final studJson = jsonDecode(data['homework_stud'] as String);
            homeworkStud = HomeworkStud.fromJson(studJson);
          } catch (e) {
            print('Ошибка парсинга homework_stud: $e');
          }
        }

        HomeworkComment? homeworkComment;
        if (data['homework_comment'] != null) {
          try {
            final commentJson = jsonDecode(data['homework_comment'] as String);
            homeworkComment = HomeworkComment.fromJson(commentJson);
          } catch (e) {
            print('Ошибка парсинга homework_comment: $e');
          }
        }

        DateTime parseTimestamp(int? timestamp) {
          if (timestamp == null) return DateTime.now();
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }

        return Homework.fromJson({
          'id': data['id'],
          'teacher': data['teacher_work_id'],
          'name_spec': data['subject_name'],
          'theme': data['theme'],
          'comment': data['description'],
          'creation_time': parseTimestamp(data['creation_time'] as int?).toIso8601String(),
          'completion_time': parseTimestamp(data['completion_time'] as int?).toIso8601String(),
          'overdue_time': data['overdue_time'] != null 
              ? parseTimestamp(data['overdue_time'] as int).toIso8601String() 
              : null,
          'filename': data['filename'],
          'file_path': data['file_path'],
          'status': data['status'],
          'common_status': data['common_status'],
          'homework_stud': homeworkStud?.toJson(),
          'homework_comment': homeworkComment?.toJson(),
          'cover_image': data['cover_image'],
          'fio_teach': data['teacher_name'],
          'material_type': data['material_type'],
          'is_deleted': data['is_deleted'] == 1,
        });
      } catch (e) {
        print('Ошибка парсинга домашнего задания: $e');
        // Возвращаем заглушку в случае ошибки
        return Homework.fromJson({
          'id': 0,
          'teacher': 0,
          'name_spec': 'Ошибка загрузки',
          'theme': 'Ошибка парсинга данных',
          'creation_time': DateTime.now().toIso8601String(),
          'completion_time': DateTime.now().toIso8601String(),
          'fio_teach': 'Система',
        });
      }
    }).toList();
  }

  Future<void> saveHomeworkCounters(List<HomeworkCounter> counters, String accountId, {int? type}) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Удаляем старые счетчики
      if (type != null) {
        await txn.delete(
          DatabaseConfig.tableHomeworkCounters,
          where: 'account_id = ? AND counter_type = ?',
          whereArgs: [accountId, type],
        );
      } else {
        await txn.delete(
          DatabaseConfig.tableHomeworkCounters,
          where: 'account_id = ?',
          whereArgs: [accountId],
        );
      }

      // Вставляем новые счетчики
      for (final counter in counters) {
        await txn.insert(DatabaseConfig.tableHomeworkCounters, {
          'account_id': accountId,
          'counter_type': counter.counterType,
          'counter': counter.counter,
          'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    });
  }

  Future<List<HomeworkCounter>> getHomeworkCounters(String accountId, {int? type}) async {
    final whereArgs = <dynamic>[accountId];
    String whereClause = 'account_id = ?';
    
    if (type != null) {
      whereClause += ' AND counter_type = ?';
      whereArgs.add(type);
    }

    final countersData = await _dbService.query(
      DatabaseConfig.tableHomeworkCounters,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'counter_type ASC',
    );

    return countersData.map((data) => HomeworkCounter.fromJson({
      'counter_type': data['counter_type'],
      'counter': data['counter'],
    })).toList();
  }

  Future<DateTime?> getLastSyncTime(String accountId, {int? materialType}) async {
    final whereArgs = <dynamic>[accountId];
    String whereClause = 'account_id = ?';
    
    if (materialType != null) {
      whereClause += ' AND material_type = ?';
      whereArgs.add(materialType);
    }

    final result = await _dbService.rawQuery(
      'SELECT MAX(sync_timestamp) as last_sync FROM ${DatabaseConfig.tableHomeworks} WHERE $whereClause',
      whereArgs,
    );

    if (result.isEmpty || result.first['last_sync'] == null) {
      return null;
    }

    final timestamp = result.first['last_sync'] as int;
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  Future<int> getHomeworksCount(String accountId, {int? materialType, int? status}) async {
    final whereArgs = <dynamic>[accountId];
    String whereClause = 'account_id = ?';
    
    if (materialType != null) {
      whereClause += ' AND material_type = ?';
      whereArgs.add(materialType);
    }
    
    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    whereClause += ' AND (is_deleted IS NULL OR is_deleted = 0)';

    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableHomeworks} WHERE $whereClause',
      whereArgs,
    );
    
    if (result.isEmpty) return 0;
    return result.first['count'] as int;
  }

  //TODO: ВЫНЕСТИ Дополнительные методы для работы с домашними заданиями
  Future<List<Homework>> getExpiredHomeworks(String accountId, {int? materialType}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final whereArgs = <dynamic>[accountId, now];
    String whereClause = 'account_id = ? AND completion_time < ? AND (is_deleted IS NULL OR is_deleted = 0)';
    
    if (materialType != null) {
      whereClause += ' AND material_type = ?';
      whereArgs.add(materialType);
    }

    final homeworksData = await _dbService.query(
      DatabaseConfig.tableHomeworks,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'completion_time ASC',
    );

    return _parseHomeworkList(homeworksData);
  }

  Future<List<Homework>> getPendingHomeworks(String accountId, {int? materialType}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final whereArgs = <dynamic>[accountId, now];
    String whereClause = 'account_id = ? AND completion_time >= ? AND (is_deleted IS NULL OR is_deleted = 0)';
    
    if (materialType != null) {
      whereClause += ' AND material_type = ?';
      whereArgs.add(materialType);
    }

    final homeworksData = await _dbService.query(
      DatabaseConfig.tableHomeworks,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'completion_time ASC',
    );

    return _parseHomeworkList(homeworksData);
  }

  Future<List<Homework>> getHomeworksBySubject(String accountId, String subjectName, {int? materialType}) async {
    final whereArgs = <dynamic>[accountId, subjectName];
    String whereClause = 'account_id = ? AND subject_name = ? AND (is_deleted IS NULL OR is_deleted = 0)';
    
    if (materialType != null) {
      whereClause += ' AND material_type = ?';
      whereArgs.add(materialType);
    }

    final homeworksData = await _dbService.query(
      DatabaseConfig.tableHomeworks,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'completion_time ASC',
    );

    return _parseHomeworkList(homeworksData);
  }

  // Вспомогательный метод для парсинга списка домашних заданий
  List<Homework> _parseHomeworkList(List<Map<String, dynamic>> homeworksData) {
    return homeworksData.map((data) {
      try {
        HomeworkStud? homeworkStud;
        if (data['homework_stud'] != null) {
          try {
            final studJson = jsonDecode(data['homework_stud'] as String);
            homeworkStud = HomeworkStud.fromJson(studJson);
          } catch (e) {
            print('Ошибка парсинга homework_stud: $e');
          }
        }

        HomeworkComment? homeworkComment;
        if (data['homework_comment'] != null) {
          try {
            final commentJson = jsonDecode(data['homework_comment'] as String);
            homeworkComment = HomeworkComment.fromJson(commentJson);
          } catch (e) {
            print('Ошибка парсинга homework_comment: $e');
          }
        }

        DateTime parseTimestamp(int? timestamp) {
          if (timestamp == null) return DateTime.now();
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }

        return Homework.fromJson({
          'id': data['id'],
          'teacher': data['teacher_work_id'],
          'name_spec': data['subject_name'],
          'theme': data['theme'],
          'comment': data['description'],
          'creation_time': parseTimestamp(data['creation_time'] as int?).toIso8601String(),
          'completion_time': parseTimestamp(data['completion_time'] as int?).toIso8601String(),
          'overdue_time': data['overdue_time'] != null 
              ? parseTimestamp(data['overdue_time'] as int).toIso8601String() 
              : null,
          'filename': data['filename'],
          'file_path': data['file_path'],
          'status': data['status'],
          'common_status': data['common_status'],
          'homework_stud': homeworkStud?.toJson(),
          'homework_comment': homeworkComment?.toJson(),
          'cover_image': data['cover_image'],
          'fio_teach': data['teacher_name'],
          'material_type': data['material_type'],
          'is_deleted': data['is_deleted'] == 1,
        });
      } catch (e) {
        print('Ошибка парсинга домашнего задания: $e');
        return Homework.fromJson({
          'id': 0,
          'teacher': 0,
          'name_spec': 'Ошибка загрузки',
          'theme': 'Ошибка парсинга данных',
          'creation_time': DateTime.now().toIso8601String(),
          'completion_time': DateTime.now().toIso8601String(),
          'fio_teach': 'Система',
        });
      }
    }).toList();
  }

  Future<void> updateHomeworkStatus(int homeworkId, String accountId, int status) async {
    await _dbService.update(
      DatabaseConfig.tableHomeworks,
      {
        'status': status,
        'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ? AND account_id = ?',
      whereArgs: [homeworkId, accountId],
    );
  }

  Future<void> markHomeworkAsDeleted(int homeworkId, String accountId) async {
    await _dbService.update(
      DatabaseConfig.tableHomeworks,
      {
        'is_deleted': 1,
        'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ? AND account_id = ?',
      whereArgs: [homeworkId, accountId],
    );
  }

  Future<Homework?> getHomeworkById(int homeworkId, String accountId) async {
    final homeworksData = await _dbService.query(
      DatabaseConfig.tableHomeworks,
      where: 'id = ? AND account_id = ?',
      whereArgs: [homeworkId, accountId],
      limit: 1,
    );

    if (homeworksData.isEmpty) return null;

    return _parseHomeworkList(homeworksData).first;
  }
}