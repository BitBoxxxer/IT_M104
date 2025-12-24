import 'dart:convert';
import 'package:journal_mobile/models/_widgets/homework/homework.dart';
import 'package:journal_mobile/models/_widgets/homework/homework_counter.dart';
import 'package:sqflite/sqflite.dart';
import '_base_repository.dart';
import '../database_config.dart';

class HomeworkRepository extends BaseRepository<Homework> {
  @override
  String get tableName => DatabaseConfig.tableHomeworks;
  
  @override
  String getUniqueKey(Homework homework) {
    // ДЗ уникально по ID, типу материала и teacher_work_id
    return '${homework.id}_${homework.materialType ?? 0}_${homework.teacherWorkId}';
  }
  
  @override
  Map<String, dynamic> toMap(Homework homework, String accountId) {
    return {
      'account_id': accountId,
      'id': homework.id,
      'teacher_work_id': homework.teacherWorkId,
      'subject_name': homework.subjectName,
      'theme': homework.theme,
      'description': homework.description,
      'creation_time': homework.creationTime.millisecondsSinceEpoch,
      'completion_time': homework.completionTime.millisecondsSinceEpoch,
      'overdue_time': homework.overdueTime?.millisecondsSinceEpoch,
      'file_path': homework.filePath,
      'comment': homework.comment,
      'status': homework.status,
      'common_status': homework.commonStatus,
      'homework_stud': homework.homeworkStud != null ? jsonEncode(homework.homeworkStud!.toJson()) : null,
      'homework_comment': homework.homeworkComment != null ? jsonEncode(homework.homeworkComment!.toJson()) : null,
      'cover_image': homework.coverImage,
      'teacher_name': homework.teacherName,
      'material_type': homework.materialType ?? 0,
      'is_deleted': homework.isDeleted == true ? 1 : 0,
    };
  }
  
  @override
  Homework fromMap(Map<String, dynamic> map) {
    try {
      HomeworkStud? homeworkStud;
      if (map['homework_stud'] != null) {
        try {
          final studJson = jsonDecode(map['homework_stud'] as String);
          homeworkStud = HomeworkStud.fromJson(studJson);
        } catch (e) {
          print('Ошибка парсинга homework_stud: $e');
        }
      }

      HomeworkComment? homeworkComment;
      if (map['homework_comment'] != null) {
        try {
          final commentJson = jsonDecode(map['homework_comment'] as String);
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
        'id': map['id'],
        'teacher': map['teacher_work_id'],
        'name_spec': map['subject_name'],
        'theme': map['theme'],
        'comment': map['description'],
        'creation_time': parseTimestamp(map['creation_time'] as int?).toIso8601String(),
        'completion_time': parseTimestamp(map['completion_time'] as int?).toIso8601String(),
        'overdue_time': map['overdue_time'] != null 
            ? parseTimestamp(map['overdue_time'] as int).toIso8601String() 
            : null,
        'file_path': map['file_path'],
        'status': map['status'],
        'common_status': map['common_status'],
        'homework_stud': homeworkStud?.toJson(),
        'homework_comment': homeworkComment?.toJson(),
        'cover_image': map['cover_image'],
        'fio_teach': map['teacher_name'],
        'material_type': map['material_type'],
        'is_deleted': map['is_deleted'] == 1,
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
        'fio_teach': 'Препод',
      });
    }
  }
  
  @override
  Map<String, dynamic> getUniqueWhereClause(Homework homework) {
    return {
      'id': homework.id,
      'material_type': homework.materialType ?? 0,
      'teacher_work_id': homework.teacherWorkId,
    };
  }
  
  /// Сохранить домашние задания с выбором стратегии
  Future<void> saveHomeworks(
    List<Homework> homeworks, 
    String accountId, {
    int? materialType,
    SyncStrategy strategy = SyncStrategy.merge,
    bool cleanupMissing = false,
  }) async {
    await saveItems(
      homeworks, 
      accountId,
      strategy: strategy,
      extraWhere: materialType != null ? 'material_type = ?' : null,
      extraWhereArgs: materialType != null ? [materialType] : null,
      cleanupMissing: cleanupMissing,
    );
    
    final typeName = materialType == 1 ? 'лабораторных' : 'домашних';
    print('✅ $typeName заданий сохранено (стратегия: $strategy): ${homeworks.length} шт');
  }
  
  // ====== Существующие методы (адаптированные) ======
  
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

    final homeworksData = await dbService.rawQuery('''
      SELECT * FROM $tableName
      WHERE $queryBuilder
      ORDER BY $orderBy
      $limitClause
    ''', whereArgs);

    return homeworksData.map(fromMap).toList();
  }

  /// Сохранить счетчики домашних заданий
  Future<void> saveHomeworkCounters(
    List<HomeworkCounter> counters, 
    String accountId, {
    int? type,
  }) async {
    final db = await dbService.database;
    await db.transaction((txn) async {
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

      for (final counter in counters) {
        await txn.insert(DatabaseConfig.tableHomeworkCounters, {
          'account_id': accountId,
          'counter_type': counter.counterType,
          'counter': counter.counter,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,);
      }
    });
    
    print('✅ Счетчики сохранены: ${counters.length} шт');
  }
  
  Future<List<HomeworkCounter>> getHomeworkCounters(String accountId, {int? type}) async {
    final whereArgs = <dynamic>[accountId];
    String whereClause = 'account_id = ?';
    
    if (type != null) {
      whereClause += ' AND counter_type = ?';
      whereArgs.add(type);
    }

    final countersData = await dbService.query(
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
  
  //TODO: ВЫНЕСТИ
  // ====== Дополнительные методы (без изменений) ======

  
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

    final result = await dbService.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE $whereClause',
      whereArgs,
    );
    
    if (result.isEmpty) return 0;
    return result.first['count'] as int;
  }

  Future<List<Homework>> getExpiredHomeworks(String accountId, {int? materialType}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final whereArgs = <dynamic>[accountId, now];
    String whereClause = 'account_id = ? AND completion_time < ? AND (is_deleted IS NULL OR is_deleted = 0)';
    
    if (materialType != null) {
      whereClause += ' AND material_type = ?';
      whereArgs.add(materialType);
    }

    final homeworksData = await dbService.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'completion_time ASC',
    );

    return homeworksData.map(fromMap).toList();
  }

  Future<List<Homework>> getPendingHomeworks(String accountId, {int? materialType}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final whereArgs = <dynamic>[accountId, now];
    String whereClause = 'account_id = ? AND completion_time >= ? AND (is_deleted IS NULL OR is_deleted = 0)';
    
    if (materialType != null) {
      whereClause += ' AND material_type = ?';
      whereArgs.add(materialType);
    }

    final homeworksData = await dbService.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'completion_time ASC',
    );

    return homeworksData.map(fromMap).toList();
  }

  Future<List<Homework>> getHomeworksBySubject(String accountId, String subjectName, {int? materialType}) async {
    final whereArgs = <dynamic>[accountId, subjectName];
    String whereClause = 'account_id = ? AND subject_name = ? AND (is_deleted IS NULL OR is_deleted = 0)';
    
    if (materialType != null) {
      whereClause += ' AND material_type = ?';
      whereArgs.add(materialType);
    }

    final homeworksData = await dbService.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'completion_time ASC',
    );

    return homeworksData.map(fromMap).toList();
  }

  Future<void> updateHomeworkStatus(int homeworkId, String accountId, int status) async {
    await dbService.update(
      tableName,
      {
        'status': status,
      },
      where: 'id = ? AND account_id = ?',
      whereArgs: [homeworkId, accountId],
    );
  }

  Future<void> markHomeworkAsDeleted(int homeworkId, String accountId) async {
    await dbService.update(
      tableName,
      {
        'is_deleted': 1,
      },
      where: 'id = ? AND account_id = ?',
      whereArgs: [homeworkId, accountId],
    );
  }

  Future<Homework?> getHomeworkById(int homeworkId, String accountId) async {
    final homeworksData = await dbService.query(
      tableName,
      where: 'id = ? AND account_id = ?',
      whereArgs: [homeworkId, accountId],
      limit: 1,
    );

    if (homeworksData.isEmpty) return null;

    return homeworksData.map(fromMap).first;
  }
  
  /// Бэквард-совместимость: старый метод с заменой
  Future<void> saveHomeworksLegacy(List<Homework> homeworks, String accountId, {int? materialType}) async {
    await saveHomeworks(
      homeworks, 
      accountId, 
      materialType: materialType,
      strategy: SyncStrategy.replace,
    );
  }
}