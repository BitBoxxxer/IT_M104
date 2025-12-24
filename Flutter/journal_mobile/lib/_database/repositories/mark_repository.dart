import 'package:journal_mobile/models/mark.dart';
import '_base_repository.dart';
import '../database_config.dart';

class MarkRepository extends BaseRepository<Mark> {
  @override
  String get tableName => DatabaseConfig.tableMarks;
  
  @override
  String getUniqueKey(Mark mark) {
    return '${mark.specName}_${mark.dateVisit}_${mark.lessonTheme}';
  }
  
  @override
  Map<String, dynamic> toMap(Mark mark, String accountId) {
    return {
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
    };
  }
  
  @override
  Mark fromMap(Map<String, dynamic> map) {
    return Mark.fromJson({
      'spec_name': map['spec_name'],
      'lesson_theme': map['lesson_theme'],
      'date_visit': map['date_visit'],
      'home_work_mark': map['home_work_mark'],
      'control_work_mark': map['control_work_mark'],
      'lab_work_mark': map['lab_work_mark'],
      'class_work_mark': map['class_work_mark'],
      'practical_work_mark': map['practical_work_mark'],
      'final_work_mark': map['final_work_mark'],
      'status_was': map['status_was'],
    });
  }
  
  @override
  Map<String, dynamic> getUniqueWhereClause(Mark mark) {
    return {
      'spec_name': mark.specName,
      'date_visit': mark.dateVisit,
      'lesson_theme': mark.lessonTheme,
    };
  }
  
  /// Сохранить оценки с выбором стратегии
  Future<void> saveMarks(
    List<Mark> marks, 
    String accountId, {
    SyncStrategy strategy = SyncStrategy.merge,
    bool cleanupMissing = false,
  }) async {
    await saveItems(
      marks, 
      accountId,
      strategy: strategy,
      cleanupMissing: cleanupMissing,
    );
    
    final stats = await _getSaveStats(marks, accountId);
    print('✅ Оценки сохранены: ${stats.inserted} новых, ${stats.updated} обновлено, '
          '${stats.deleted} удалено (стратегия: $strategy)');
  }
  
  /// Получить статистику сохранения
  Future<SaveStats> _getSaveStats(List<Mark> marks, String accountId) async {
    final db = await dbService.database;
    final existing = await getMarks(accountId);
    
    final existingKeys = existing.map(getUniqueKey).toSet();
    final newKeys = marks.map(getUniqueKey).toSet();
    
    final inserted = marks.where((m) => !existingKeys.contains(getUniqueKey(m))).length;
    final updated = marks.where((m) => existingKeys.contains(getUniqueKey(m))).length;
    final deleted = existing.where((m) => !newKeys.contains(getUniqueKey(m))).length;
    
    return SaveStats(
      inserted: inserted,
      updated: updated,
      deleted: deleted,
      total: marks.length,
    );
  }
  
  /// Получить все оценки (существующий метод)
  Future<List<Mark>> getMarks(String accountId) async {
    final marksData = await dbService.query(
      tableName,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date_visit DESC',
    );
    
    return marksData.map(fromMap).toList();
  }
  
  /// Получить последние оценки (существующий метод)
  Future<List<Mark>> getRecentMarks(String accountId, int limit) async {
    final marksData = await dbService.query(
      tableName,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date_visit DESC',
      limit: limit,
    );
    
    return marksData.map(fromMap).toList();
  }
  
  /// Получить количество оценок (существующий метод)
  Future<int> getMarksCount(String accountId) async {
    final result = await dbService.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
  
  /// Бэквард-совместимость: старый метод с заменой
  Future<void> saveMarksLegacy(List<Mark> marks, String accountId) async {
    await saveMarks(marks, accountId, strategy: SyncStrategy.replace);
  }
}

/// Статистика сохранения
class SaveStats {
  final int inserted;
  final int updated;
  final int deleted;
  final int total;
  
  SaveStats({
    required this.inserted,
    required this.updated,
    required this.deleted,
    required this.total,
  });
}