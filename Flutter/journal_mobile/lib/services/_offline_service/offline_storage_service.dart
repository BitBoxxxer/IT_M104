import 'package:journal_mobile/_database/database_config.dart';
import 'package:journal_mobile/_database/database_service.dart';
import 'package:journal_mobile/services/_account/account_manager_service.dart';

import '../../_database/database_facade.dart';
import '../../models/mark.dart';
import '../../models/user_data.dart';
import '../../models/days_element.dart';
import '../../models/leaderboard_user.dart';
import '../../models/feedback_review.dart';
import '../../models/_widgets/exams/exam.dart';
import '../../models/activity_record.dart';
import '../../models/_widgets/homework/homework.dart';
import '../../models/_widgets/homework/homework_counter.dart';
import '../api_service.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  final DatabaseFacade _databaseFacade = DatabaseFacade();
  final DatabaseService _databaseService = DatabaseService();
  final AccountManagerService _accountManager = AccountManagerService();
  
  String? _currentAccountId;

  static const int _maxMarks = 5000;
  static const int _maxSchedule = 500;
  static const int _maxActivities = 500;
  static const int _maxHomeworks = 500; //TODO: Допилить хранение заданий
  // с ограничениями действий на проверку состояния сети.

  Future<String> _getCurrentAccountId() async {
    if (_currentAccountId == null) {
      final account = await _accountManager.getCurrentAccount();
      if (account == null) {
        throw Exception('Нет активного аккаунта для работы с оффлайн данными');
      }
      _currentAccountId = account.id;
    }
    return _currentAccountId!;
  }

  Future<void> clearAccountData(String accountId) async {
    try {
      print('🧹 Явная очистка данных аккаунта $accountId из OfflineStorage');
      
      await _databaseFacade.clearAllForAccount(accountId);
      
      print('✅ Данные аккаунта очищены в OfflineStorage');
    } catch (e) {
      print('❌ Ошибка очистки данных в OfflineStorage: $e');
    }
  }

  Future<void> saveMarks(List<Mark> marks) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveMarks(marks, accountId);
    print('✅ Оценки сохранены в SQLite: ${marks.length} шт');
  }

  Future<List<Mark>> getMarks() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getMarks(accountId);
  }

  Future<void> saveUserData(UserData user) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveUserData(user, accountId);
    print('✅ Данные пользователя сохранены в SQLite');
  }

  Future<UserData?> getUserData() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getUserData(accountId);
  }

  Future<void> saveSchedule(List<ScheduleElement> schedule) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveSchedule(schedule, accountId);
    print('✅ Расписание сохранено в SQLite: ${schedule.length} шт');
  }

  Future<List<ScheduleElement>> getSchedule() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getSchedule(accountId);
  }

  Future<List<ScheduleElement>> getScheduleByDateRange(DateTime start, DateTime end) async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getScheduleByDateRange(accountId, start, end);
  }

  Future<void> saveActivityRecords(List<ActivityRecord> activities) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveActivities(activities, accountId, strategy: SyncStrategy.append);
    print('✅ Активности сохранены в SQLite: ${activities.length} шт');
  }

  Future<List<ActivityRecord>> getActivityRecords() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getActivities(accountId);
  }

  Future<void> saveExams(List<Exam> exams) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveExams(exams, accountId);
    print('✅ Экзамены сохранены в SQLite: ${exams.length} шт');
  }

  Future<List<Exam>> getExams() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getExams(accountId);
  }

  Future<List<Exam>> getFutureExams() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getFutureExams(accountId);
  }

  Future<List<Exam>> getPastExams() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getPastExams(accountId);
  }

  Future<List<Exam>> getExamsWithGrades() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getExamsWithGrades(accountId);
  }

  Future<void> saveFeedbackReviews(List<FeedbackReview> feedbacks) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveFeedbacks(feedbacks, accountId);
    print('✅ Отзывы сохранены в SQLite: ${feedbacks.length} шт');
  }

  Future<List<FeedbackReview>> getFeedbackReviews() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getFeedbacks(accountId);
  }

  Future<void> saveHomeworks(List<Homework> homeworks, {int? type}) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveHomeworks(homeworks, accountId, materialType: type);
    print('✅ ${type == 1 ? 'Лабораторные' : 'Домашние'} задания сохранены в SQLite: ${homeworks.length} шт');
  }

  Future<List<Homework>> getHomeworks({int? type, int? status, int? page, int? limit}) async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getHomeworks(
      accountId, 
      materialType: type, 
      status: status, 
      page: page, 
      limit: limit
    );
  }

  Future<void> saveHomeworkCounters(List<HomeworkCounter> counters, {int? type}) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveHomeworkCounters(counters, accountId, type: type);
    print('✅ Счетчики ${type == 1 ? 'лабораторных' : 'домашних'} заданий сохранены в SQLite: ${counters.length} шт');
  }

  Future<List<HomeworkCounter>> getHomeworkCounters({int? type}) async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getHomeworkCounters(accountId, type: type);
  }

  Future<void> saveGroupLeaders(List<LeaderboardUser> leaders) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveGroupLeaders(leaders, accountId);
    print('✅ Лидеры группы сохранены в SQLite: ${leaders.length} шт');
  }

  Future<List<LeaderboardUser>> getGroupLeaders() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getGroupLeaders(accountId);
  }

  Future<void> saveStreamLeaders(List<LeaderboardUser> leaders) async {
    final accountId = await _getCurrentAccountId();
    await _databaseFacade.saveStreamLeaders(leaders, accountId);
    print('✅ Лидеры потока сохранены в SQLite: ${leaders.length} шт');
  }

  Future<List<LeaderboardUser>> getStreamLeaders() async {
    final accountId = await _getCurrentAccountId();
    return await _databaseFacade.getStreamLeaders(accountId);
  }


  //TODO: Доп. методы (утилиты rabbits перенести под архитектуру.)
  Future<void> cleanupOldData() async {
    try {
      print('🧹 Начинаем очистку устаревших данных...');
      
      final allMarks = await getMarks();
      if (allMarks.length > _maxMarks) {
        final marksToKeep = allMarks.sublist(allMarks.length - _maxMarks);
        await saveMarks(marksToKeep);
        print('🗑️ Очищены оценки: ${allMarks.length} -> ${marksToKeep.length}');
      }
      
      final allSchedule = await getSchedule();
      if (allSchedule.length > _maxSchedule) {
        final scheduleToKeep = allSchedule.sublist(allSchedule.length - _maxSchedule);
        await saveSchedule(scheduleToKeep);
        print('🗑️ Очищено расписание: ${allSchedule.length} -> ${scheduleToKeep.length}');
      }
      
      final allActivities = await getActivityRecords();
      if (allActivities.length > _maxActivities) {
        final activitiesToKeep = allActivities.sublist(allActivities.length - _maxActivities);
        await saveActivityRecords(activitiesToKeep);
        print('🗑️ Очищены активности: ${allActivities.length} -> ${activitiesToKeep.length}');
      }
      
      print('✅ Очистка данных завершена');
    } catch (e) {
      print('❌ Ошибка очистки данных: $e');
    }
  }

  Future<void> clearAllOfflineData() async {
    try {
      final accountId = await _getCurrentAccountId();
      await _databaseService.clearAllForAccount(accountId);
      print('🗑️ Все offline данные очищены для аккаунта: $accountId');
    } catch (e) {
      print('❌ Ошибка очистки offline данных: $e');
    }
  }

  Future<Map<String, int>> getOfflineDataStats() async {
    final stats = <String, int>{};
    
    try {
      final accountId = await _getCurrentAccountId();
      
      final marks = await getMarks();
      stats['marks'] = marks.length;
      
      final user = await getUserData();
      stats['user'] = user != null ? 1 : 0;
      
      final schedule = await getSchedule();
      stats['schedule'] = schedule.length;
      
      final activities = await getActivityRecords();
      stats['activities'] = activities.length;
      
      final exams = await getExams();
      stats['exams'] = exams.length;
      
      final feedbacks = await getFeedbackReviews();
      stats['feedbacks'] = feedbacks.length;
      
      final homeworks = await getHomeworks();
      stats['homeworks'] = homeworks.length;
      
      final groupLeaders = await getGroupLeaders();
      stats['groupLeaders'] = groupLeaders.length;
      
      final streamLeaders = await getStreamLeaders();
      stats['streamLeaders'] = streamLeaders.length;
      
      final homeworkCounters = await getHomeworkCounters();
      stats['homeworkCounters'] = homeworkCounters.length;
      
      print('📊 Статистика оффлайн данных для аккаунта $accountId:');
      stats.forEach((key, value) {
        print('   - $key: $value');
      });
      
    } catch (e) {
      print('❌ Ошибка получения статистики offline данных: $e');
    }
    
    return stats;
  }

  Future<List<Homework>> getHomeworksByStatus(int? status, {int? type}) async {
    return await getHomeworks(type: type, status: status);
  }

  Future<Map<String, int>> getHomeworkStatusStats() async {
    try {
      final homeworks = await getHomeworks();
      final stats = <String, int>{
        'expired': 0,
        'done': 0,
        'inspection': 0,
        'opened': 0,
        'deleted': 0,
      };
      
      for (var hw in homeworks) {
        final status = hw.getRealStatus();
        
        switch (status) {
          case 0: stats['expired'] = stats['expired']! + 1; break;
          case 1: stats['done'] = stats['done']! + 1; break;
          case 2: stats['inspection'] = stats['inspection']! + 1; break;
          case 3: stats['opened'] = stats['opened']! + 1; break;
          case 5: stats['deleted'] = stats['deleted']! + 1; break;
        }
      }
      
      print('📊 Статистика статусов домашних заданий:');
      stats.forEach((status, count) {
        print('  - $status: $count заданий');
      });
      
      return stats;
    } catch (e) {
      print('❌ Ошибка получения статистики: $e');
      return {};
    }
  }

  /// Диагностика типов заданий
  Future<void> debugHomeworkTypes() async {
    try {
      print('🔍 Диагностика типов заданий в SQLite:');
      
      final allHomeworks = await getHomeworks();
      print('Всего заданий: ${allHomeworks.length}');
      
      final byType = <int, List<Homework>>{};
      for (var hw in allHomeworks) {
        final type = hw.materialType ?? 0;
        if (!byType.containsKey(type)) {
          byType[type] = [];
        }
        byType[type]!.add(hw);
      }
      
      byType.forEach((type, homeworks) {
        print('Тип $type (${type == 1 ? 'Лабораторные' : 'Домашние'}): ${homeworks.length} заданий');
        
        final examples = homeworks.take(3).map((hw) => 'ID ${hw.id}: "${hw.theme}"').toList();
        print('   Примеры: ${examples.join(", ")}');
      });
      
    } catch (e) {
      print('❌ Ошибка диагностики: $e');
    }
  }

  /// Синхронизация лабораторных работ
  Future<void> syncLabWorks(String token) async {
  try {
    print('🔄 Принудительная синхронизация лабораторных работ...');
    
    // Используем ApiService через ServiceLocator или внедрение зависимостей
    final apiService = ApiService();
    final labWorks = await apiService.getHomeworks(token, type: 1);
    
    await saveHomeworks(labWorks, type: 1);
    
    print('✅ Лабораторные работы синхронизированы: ${labWorks.length} шт');
  } catch (e) {
    print('❌ Ошибка синхронизации лабораторных работ: $e');
  }
}

  /// Получить домашние задания с пагинацией
  Future<List<Homework>> getHomeworksPaginated({
    int? type,
    int? status,
    int page = 1,
    int limit = 6,
  }) async {
    return await getHomeworks(
      type: type,
      status: status,
      page: page,
      limit: limit,
    );
  }

  /// Проверить наличие минимальных оффлайн данных
  Future<bool> hasMinimumOfflineData() async {
    try {
      final stats = await getOfflineDataStats();
      
      final hasUserData = stats['user'] != null && stats['user']! > 0;
      final hasMarks = stats['marks'] != null && stats['marks']! > 0;
      final hasSchedule = stats['schedule'] != null && stats['schedule']! > 0;
      
      final hasMinimumData = hasUserData && hasMarks;
      
      print('📱 Проверка оффлайн данных:');
      print('   - Есть данные пользователя: $hasUserData');
      print('   - Есть оценки: $hasMarks');
      print('   - Есть расписание: $hasSchedule');
      print('   - Достаточно данных для оффлайн режима: $hasMinimumData');
      
      return hasMinimumData;
    } catch (e) {
      print('❌ Ошибка проверки оффлайн данных: $e');
      return false;
    }
  }

  /// Миграция старых данных из SecureStorage в SQLite
  Future<void> migrateFromSecureStorage() async {
    try {
      print('🔄 Начинаем миграцию данных из SecureStorage в SQLite...');
      
      // Здесь можно добавить логику миграции старых данных
      // Но в новой архитектуре мы начинаем с чистого SQLite
      
      print('✅ Миграция данных завершена (или не требуется)');
    } catch (e) {
      print('❌ Ошибка миграции данных: $e');
    }
  }

  /// Установить текущий аккаунт (например, при переключении)
  Future<void> setCurrentAccount(String accountId) async {
    _currentAccountId = accountId;
    print('🔄 Установлен текущий аккаунт для оффлайн данных: $accountId');
  }

  /// Очистить кэш (в памяти)
  void clearCache() {
    _currentAccountId = null;
    print('🧹 Кэш OfflineStorageService очищен');
  }
}