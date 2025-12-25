import 'package:journal_mobile/_database/database_config.dart';
import 'package:journal_mobile/models/_system/account_model.dart';
import 'package:journal_mobile/models/mark.dart';
import 'package:journal_mobile/models/user_data.dart';
import 'package:journal_mobile/models/days_element.dart';
import 'package:journal_mobile/models/leaderboard_user.dart';
import 'package:journal_mobile/models/feedback_review.dart';
import 'package:journal_mobile/models/_widgets/exams/exam.dart';
import 'package:journal_mobile/models/activity_record.dart';
import 'package:journal_mobile/models/_widgets/homework/homework.dart';
import 'package:journal_mobile/models/_widgets/homework/homework_counter.dart';
import 'package:journal_mobile/models/_widgets/notifications/notification_item.dart';
import 'package:journal_mobile/models/_system/schedule_note.dart';

import './repositories/account_repository.dart';
import './repositories/mark_repository.dart';
import './repositories/user_repository.dart';
import './repositories/schedule_repository.dart';
import './repositories/notification_repository.dart';
import './repositories/exam_repository.dart';
import './repositories/activity_repository.dart';
import './repositories/feedback_repository.dart';
import './repositories/homework_repository.dart';
import './repositories/leaderboard_repository.dart';
import './repositories/cache_repository.dart';
import './repositories/schedule_note_repository.dart';

import 'database_service.dart';

/// фасад для CRUD [DatabaseFacade]
class DatabaseFacade {
  final AccountRepository _accountRepository = AccountRepository();
  final MarkRepository _markRepository = MarkRepository();
  final UserRepository _userRepository = UserRepository();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();
  final ExamRepository _examRepository = ExamRepository();
  final ActivityRepository _activityRepository = ActivityRepository();
  final FeedbackRepository _feedbackRepository = FeedbackRepository();
  final HomeworkRepository _homeworkRepository = HomeworkRepository();
  final LeaderboardRepository _leaderboardRepository = LeaderboardRepository();
  final ScheduleNoteRepository _scheduleNoteRepository = ScheduleNoteRepository();
  final CacheRepository _cacheRepository = CacheRepository();

  Future<void> saveAccount(Account account) => _accountRepository.saveAccount(account);
  Future<List<Account>> getAllAccounts() => _accountRepository.getAllAccounts();
  Future<Account?> getAccountById(String accountId) => _accountRepository.getAccountById(accountId);
  Future<Account?> getCurrentAccount() => _accountRepository.getCurrentAccount();
  Future<void> setCurrentAccount(String accountId) => _accountRepository.setCurrentAccount(accountId);
  Future<void> deleteAccount(String accountId) => _accountRepository.deleteAccount(accountId);

  Future<void> saveMarks(List<Mark> marks, String accountId) => _markRepository.saveMarks(marks, accountId);
  Future<List<Mark>> getMarks(String accountId) => _markRepository.getMarks(accountId);
  Future<List<Mark>> getRecentMarks(String accountId, int limit) => _markRepository.getRecentMarks(accountId, limit);

  Future<void> saveUserData(UserData user, String accountId) => _userRepository.saveUserData(user, accountId);
  Future<UserData?> getUserData(String accountId) => _userRepository.getUserData(accountId);

  Future<void> saveSchedule(List<ScheduleElement> schedule, String accountId) => _scheduleRepository.saveSchedule(schedule, accountId);
  Future<List<ScheduleElement>> getSchedule(String accountId) => _scheduleRepository.getSchedule(accountId);
  Future<List<ScheduleElement>> getScheduleByDateRange(String accountId, DateTime start, DateTime end) => _scheduleRepository.getScheduleByDateRange(accountId, start, end);

  Future<void> saveNotification(NotificationItem notification, String accountId) => _notificationRepository.saveNotification(notification, accountId);
  Future<List<NotificationItem>> getNotifications(String accountId) => _notificationRepository.getNotifications(accountId);
  Future<void> markAsRead(int notificationId, String accountId) => _notificationRepository.markAsRead(notificationId, accountId);
  Future<void> deleteNotification(int notificationId, String accountId) => _notificationRepository.deleteNotification(notificationId, accountId);
  Future<void> clearNotifications(String accountId) => _notificationRepository.clearNotifications(accountId);

  Future<void> saveExams(List<Exam> exams, String accountId) => _examRepository.saveExams(exams, accountId);
  Future<List<Exam>> getExams(String accountId) => _examRepository.getExams(accountId);
  Future<List<Exam>> getFutureExams(String accountId) => _examRepository.getFutureExams(accountId);

  Future<void> saveActivities(List<ActivityRecord> activities, String accountId, {required SyncStrategy strategy}) => _activityRepository.saveActivities(activities, accountId);
  Future<List<ActivityRecord>> getActivities(String accountId) => _activityRepository.getActivities(accountId);

  Future<void> saveFeedbacks(List<FeedbackReview> feedbacks, String accountId) => _feedbackRepository.saveFeedbacks(feedbacks, accountId);
  Future<List<FeedbackReview>> getFeedbacks(String accountId) => _feedbackRepository.getFeedbacks(accountId);

  Future<void> saveHomeworks(List<Homework> homeworks, String accountId, {int? materialType}) => 
    _homeworkRepository.saveHomeworks(homeworks, accountId, materialType: materialType);
  Future<List<Homework>> getHomeworks(String accountId, {int? materialType, int? status, int? page, int? limit}) => 
    _homeworkRepository.getHomeworks(accountId, materialType: materialType, status: status, page: page, limit: limit);
  Future<void> saveHomeworkCounters(List<HomeworkCounter> counters, String accountId, {int? type}) => _homeworkRepository.saveHomeworkCounters(counters, accountId, type: type);
  Future<List<HomeworkCounter>> getHomeworkCounters(String accountId, {int? type}) => _homeworkRepository.getHomeworkCounters(accountId, type: type);

  Future<void> saveGroupLeaders(List<LeaderboardUser> leaders, String accountId) => _leaderboardRepository.saveGroupLeaders(leaders, accountId);
  Future<List<LeaderboardUser>> getGroupLeaders(String accountId) => _leaderboardRepository.getGroupLeaders(accountId);
  Future<void> saveStreamLeaders(List<LeaderboardUser> leaders, String accountId) => _leaderboardRepository.saveStreamLeaders(leaders, accountId);
  Future<List<LeaderboardUser>> getStreamLeaders(String accountId) => _leaderboardRepository.getStreamLeaders(accountId);

  Future<void> saveToCache(String key, dynamic value, {String? accountId, Duration? expiry}) => _cacheRepository.save(key, value, accountId: accountId, expiry: expiry);
  Future<dynamic> getFromCache(String key, {String? accountId}) => _cacheRepository.get(key, accountId: accountId);
  Future<void> removeFromCache(String key, {String? accountId}) => _cacheRepository.remove(key, accountId: accountId);
  Future<void> clearCache({String? accountId}) => _cacheRepository.clear(accountId: accountId);

  Future<int> saveScheduleNote(ScheduleNote note) => _scheduleNoteRepository.saveNote(note); // Практика
  Future<List<ScheduleNote>> getScheduleNotesForDate(String accountId, DateTime date) => 
      _scheduleNoteRepository.getNotesForDate(accountId, date);
  Future<List<ScheduleNote>> getAllScheduleNotes(String accountId) => 
      _scheduleNoteRepository.getAllNotes(accountId);
  Future<ScheduleNote?> getScheduleNoteById(int noteId, String accountId) => 
      _scheduleNoteRepository.getNoteById(noteId, accountId);
  Future<List<ScheduleNote>> getNotesWithReminders(String accountId) => 
      _scheduleNoteRepository.getNotesWithReminders(accountId);
  Future<List<ScheduleNote>> getUpcomingReminders(String accountId, {int limit = 10}) => 
      _scheduleNoteRepository.getUpcomingReminders(accountId, limit: limit);
  Future<int> deleteScheduleNote(int noteId, String accountId) => 
      _scheduleNoteRepository.deleteNote(noteId, accountId);
  Future<int> deleteScheduleNotesForDate(String accountId, DateTime date) => 
      _scheduleNoteRepository.deleteNotesForDate(accountId, date);
  Future<int> clearAllScheduleNotes(String accountId) => 
      _scheduleNoteRepository.clearAllNotes(accountId);
  Stream<List<ScheduleNote>> watchScheduleNotesForDate(String accountId, DateTime date) => 
      _scheduleNoteRepository.watchNotesForDate(accountId, date);



  Future<List<Homework>> getExpiredHomeworks(String accountId, {int? materialType}) => 
      _homeworkRepository.getExpiredHomeworks(accountId, materialType: materialType);

  Future<List<Homework>> getPendingHomeworks(String accountId, {int? materialType}) => 
      _homeworkRepository.getPendingHomeworks(accountId, materialType: materialType);

  Future<List<Homework>> getHomeworksBySubject(String accountId, String subjectName, {int? materialType}) => 
      _homeworkRepository.getHomeworksBySubject(accountId, subjectName, materialType: materialType);

  Future<void> updateHomeworkStatus(int homeworkId, String accountId, int status) => 
      _homeworkRepository.updateHomeworkStatus(homeworkId, accountId, status);

  Future<void> markHomeworkAsDeleted(int homeworkId, String accountId) => 
      _homeworkRepository.markHomeworkAsDeleted(homeworkId, accountId);

  Future<Homework?> getHomeworkById(int homeworkId, String accountId) => 
      _homeworkRepository.getHomeworkById(homeworkId, accountId);

  Future<List<LeaderboardUser>> searchLeaders(String accountId, String searchQuery, bool isGroupLeaders) => 
      _leaderboardRepository.searchLeaders(accountId, searchQuery, isGroupLeaders);

  Future<LeaderboardUser?> getUserPosition(String accountId, int studentId, bool isGroupLeaders) => 
      _leaderboardRepository.getUserPosition(accountId, studentId, isGroupLeaders);

  Future<void> clearLeaders(String accountId, bool isGroupLeaders) => 
      _leaderboardRepository.clearLeaders(accountId, isGroupLeaders);

      
  /// Удалить все аккаунты
  Future<void> deleteAllAccounts() async {
    final accounts = await getAllAccounts();
    for (var account in accounts) {
      await deleteAccount(account.id);
    }
  }

  /// Очистить все данные для аккаунта
  Future<void> clearAllForAccount(String accountId) async {
    final dbService = DatabaseService();
    await dbService.clearAllForAccount(accountId);
  }
}