import 'package:journal_mobile/models/_widgets/exams/exam.dart';
import '_base_repository.dart';
import '../database_config.dart';

class ExamRepository extends BaseRepository<Exam> {
  @override
  String get tableName => DatabaseConfig.tableExams;
  
  @override
  String getUniqueKey(Exam exam) {
    return '${exam.subjectName}_${exam.date}_${exam.teacherName}';
  }
  
  @override
  Map<String, dynamic> toMap(Exam exam, String accountId) {
    return {
      'account_id': accountId,
      'spec': exam.subjectName,
      'mark': exam.grade,
      'date': exam.date,
      'teacher': exam.teacherName,
    };
  }
  
  @override
  Exam fromMap(Map<String, dynamic> map) {
    return Exam.fromJson({
      'spec': map['spec'],
      'mark': map['mark'],
      'date': map['date'],
      'teacher': map['teacher'],
    });
  }
  
  @override
  Map<String, dynamic> getUniqueWhereClause(Exam exam) {
    return {
      'spec': exam.subjectName,
      'date': exam.date,
      'teacher': exam.teacherName,
    };
  }
  
  /// Сохранить экзамены с выбором стратегии
  Future<void> saveExams(
    List<Exam> exams, 
    String accountId, {
    SyncStrategy strategy = SyncStrategy.merge,
    bool cleanupMissing = false,
  }) async {
    await saveItems(
      exams, 
      accountId,
      strategy: strategy,
      cleanupMissing: cleanupMissing,
    );
    
    print('✅ Экзамены сохранены (стратегия: $strategy): ${exams.length} шт');
  }
  
  /// Получить все экзамены
  Future<List<Exam>> getExams(String accountId) async {
    final examsData = await dbService.query(
      tableName,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date ASC',
    );
    
    return examsData.map(fromMap).toList();
  }
  
  /// Получить будущие экзамены
  Future<List<Exam>> getFutureExams(String accountId) async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T').first;
    
    final examsData = await dbService.query(
      tableName,
      where: 'account_id = ? AND date >= ?',
      whereArgs: [accountId, today],
      orderBy: 'date ASC',
    );
    
    return examsData.map(fromMap).toList();
  }
  
  /// Получить количество экзаменов
  Future<int> getExamsCount(String accountId) async {
    final result = await dbService.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
  
  /// Бэквард-совместимость: старый метод с заменой
  Future<void> saveExamsLegacy(List<Exam> exams, String accountId) async {
    await saveExams(exams, accountId, strategy: SyncStrategy.replace);
  }
}