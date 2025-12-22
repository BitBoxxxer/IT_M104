// lib/services/_database/repositories/feedback_repository.dart
import 'package:journal_mobile/models/feedback_review.dart';
import '../database_service.dart';
import '../database_config.dart';

class FeedbackRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveFeedbacks(List<FeedbackReview> feedbacks, String accountId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Удаляем старые отзывы
      await txn.delete(
        DatabaseConfig.tableFeedbackReviews,
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      // Вставляем новые
      for (final feedback in feedbacks) {
        await txn.insert(DatabaseConfig.tableFeedbackReviews, {
          'account_id': accountId,
          'teacher': feedback.teacherName,
          'spec': feedback.subject,
          'message': feedback.feedbackText,
          'date': feedback.date,
          'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    });
  }

  Future<List<FeedbackReview>> getFeedbacks(String accountId) async {
    final feedbacksData = await _dbService.query(
      DatabaseConfig.tableFeedbackReviews,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );

    return feedbacksData.map((data) => FeedbackReview.fromJson({
      'teacher': data['teacher'],
      'spec': data['spec'],
      'message': data['message'],
      'date': data['date'],
    })).toList();
  }

  Future<List<FeedbackReview>> getRecentFeedbacks(String accountId, int limit) async {
    final feedbacksData = await _dbService.query(
      DatabaseConfig.tableFeedbackReviews,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
      limit: limit,
    );

    return feedbacksData.map((data) => FeedbackReview.fromJson({
      'teacher': data['teacher'],
      'spec': data['spec'],
      'message': data['message'],
      'date': data['date'],
    })).toList();
  }

  Future<DateTime?> getLastSyncTime(String accountId) async {
  final result = await _dbService.rawQuery(
    'SELECT MAX(sync_timestamp) as last_sync FROM ${DatabaseConfig.tableFeedbackReviews} WHERE account_id = ?',
    [accountId],
  );
  
  if (result.isEmpty || result.first['last_sync'] == null) {
    return null;
  }
  
  final timestamp = result.first['last_sync'] as int;
  return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

  Future<int> getFeedbacksCount(String accountId) async {
    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableFeedbackReviews} WHERE account_id = ?',
      [accountId],
    );
    return result.first['count'] as int;
  }
} // tableFeedbackReviews