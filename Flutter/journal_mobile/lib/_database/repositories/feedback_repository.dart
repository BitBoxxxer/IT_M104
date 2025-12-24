import 'package:journal_mobile/models/feedback_review.dart';
import '_base_repository.dart';
import '../database_config.dart';

class FeedbackRepository extends BaseRepository<FeedbackReview> {
  @override
  String get tableName => DatabaseConfig.tableFeedbackReviews;
  
  @override
  String getUniqueKey(FeedbackReview feedback) {
    // Отзывы уникальны по учителю, предмету и дате
    return '${feedback.teacherName}_${feedback.subject}_${feedback.date}_${feedback.feedbackText.substring(0, min(50, feedback.feedbackText.length))}';
  }
  
  @override
  Map<String, dynamic> toMap(FeedbackReview feedback, String accountId) {
    return {
      'account_id': accountId,
      'teacher': feedback.teacherName,
      'spec': feedback.subject,
      'message': feedback.feedbackText,
      'date': feedback.date,
    };
  }
  
  @override
  FeedbackReview fromMap(Map<String, dynamic> map) {
    return FeedbackReview.fromJson({
      'teacher': map['teacher'],
      'spec': map['spec'],
      'message': map['message'],
      'date': map['date'],
    });
  }
  
  @override
  Map<String, dynamic> getUniqueWhereClause(FeedbackReview feedback) {
    return {
      'teacher': feedback.teacherName,
      'spec': feedback.subject,
      'date': feedback.date,
      'message': feedback.feedbackText,
    };
  }
  
  /// Сохранить отзывы с выбором стратегии
  Future<void> saveFeedbacks(
    List<FeedbackReview> feedbacks, 
    String accountId, {
    SyncStrategy strategy = SyncStrategy.append,
    bool cleanupMissing = false,
  }) async {
    await saveItems(
      feedbacks, 
      accountId,
      strategy: strategy,
      cleanupMissing: cleanupMissing,
    );
    
    print('✅ Отзывы сохранены (стратегия: $strategy): ${feedbacks.length} шт');
  }
  
  /// Получить все отзывы
  Future<List<FeedbackReview>> getFeedbacks(String accountId) async {
    final feedbacksData = await dbService.query(
      tableName,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    
    return feedbacksData.map(fromMap).toList();
  }
  
  /// Получить последние отзывы
  Future<List<FeedbackReview>> getRecentFeedbacks(String accountId, int limit) async {
    final feedbacksData = await dbService.query(
      tableName,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
      limit: limit,
    );
    
    return feedbacksData.map(fromMap).toList();
  }
  
  /// Получить количество отзывов
  Future<int> getFeedbacksCount(String accountId) async {
    final result = await dbService.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
  
  /// Бэквард-совместимость: старый метод с заменой
  Future<void> saveFeedbacksLegacy(List<FeedbackReview> feedbacks, String accountId) async {
    await saveFeedbacks(feedbacks, accountId, strategy: SyncStrategy.replace);
  }
  
  /// Утилитарный метод для получения минимума
  int min(int a, int b) => a < b ? a : b;
}