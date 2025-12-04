import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../models/mark.dart';
import '../models/user_data.dart';
import '../models/days_element.dart';
import '../models/leaderboard_user.dart';
import '../models/feedback_review.dart';
import '../models/_widgets/exams/exam.dart';
import '../models/activity_record.dart';
import '../models/_widgets/homework/homework.dart';
import '../models/_widgets/homework/homework_counter.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Ключи для Secure Storage
  static const String _marksKey = 'offline_marks';
  static const String _userKey = 'offline_user';
  static const String _scheduleKey = 'offline_schedule';
  static const String _activityKey = 'offline_activity';
  static const String _examsKey = 'offline_exams';
  static const String _feedbackKey = 'offline_feedback';
  static const String _homeworksKey = 'offline_homeworks';
  static const String _groupLeadersKey = 'offline_group_leaders';
  static const String _streamLeadersKey = 'offline_stream_leaders';
  static const String _homeworkCountersKey = 'offline_homework_counters';

  // Ограничения кэша
  static const int _maxMarks = 2000;
  static const int _maxSchedule = 500;
  static const int _maxActivities = 500;
  static const int _maxExams = 200;
  static const int _maxFeedbacks = 200;
  static const int _maxHomeworks = 500;
  static const int _maxLeaders = 100;

Future<void> cleanupOldData() async {
  try {
    await getOfflineDataStats();
    print('🧹 Начинаем очистку устаревших данных...');
    
    await _cleanupIfExceedsLimit(_marksKey, _maxMarks, getMarks, saveMarks);
    await _cleanupIfExceedsLimit(_scheduleKey, _maxSchedule, getSchedule, saveSchedule);
    await _cleanupIfExceedsLimit(_activityKey, _maxActivities, getActivityRecords, saveActivityRecords);
    
    print('✅ Очистка данных завершена');
  } catch (e) {
    print('❌ Ошибка очистки данных: $e');
  }
}

Future<void> _cleanupIfExceedsLimit<T>(
  String key, 
  int maxLimit, 
  Future<List<T>> Function() getData,
  Future<void> Function(List<T>) saveData,
) async {
  try {
    final data = await getData();
    if (data.length > maxLimit) {
      final cleanedData = data.sublist(data.length - maxLimit);
      await saveData(cleanedData);
      print('🗑️ Очищены данные $key: ${data.length} -> ${cleanedData.length}');
    }
  } catch (e) {
    print('❌ Ошибка очистки $key: $e');
  }
}

  Future<void> saveMarks(List<Mark> marks) async {
    try {
      final marksToSave = marks.length > _maxMarks 
          ? marks.sublist(0, _maxMarks)
          : marks;
          
      final marksJson = marksToSave.map((mark) => mark.toJson()).toList();
      await _storage.write(key: _marksKey, value: jsonEncode(marksJson));
      print('💾 Оценки сохранены офлайн: ${marksToSave.length} шт (лимит: $_maxMarks)');
    } catch (e) {
      print('❌ Ошибка сохранения оценок: $e');
    }
  }

  Future<List<Mark>> getMarks() async {
    try {
      final jsonString = await _storage.read(key: _marksKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> marksList = jsonDecode(jsonString);
      return marksList.map((json) => Mark.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн оценок: $e');
      return [];
    }
  }

  Future<void> saveUserData(UserData user) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      print('💾 Данные пользователя сохранены офлайн');
    } catch (e) {
      print('❌ Ошибка сохранения пользователя: $e');
    }
  }

  Future<UserData?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: _userKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      
      final userJson = jsonDecode(jsonString);
      return UserData.fromJson(userJson);
    } catch (e) {
      print('❌ Ошибка загрузки офлайн пользователя: $e');
      return null;
    }
  }

  Future<void> saveSchedule(List<ScheduleElement> schedule) async {
    try {
      final scheduleToSave = schedule.length > _maxSchedule 
          ? schedule.sublist(0, _maxSchedule)
          : schedule;
          
      final scheduleJson = scheduleToSave.map((element) => element.toJson()).toList();
      await _storage.write(key: _scheduleKey, value: jsonEncode(scheduleJson));
      print('💾 Расписание сохранено офлайн: ${scheduleToSave.length} шт (лимит: $_maxSchedule)');
    } catch (e) {
      print('❌ Ошибка сохранения расписания: $e');
    }
  }

  Future<List<ScheduleElement>> getSchedule() async {
    try {
      final jsonString = await _storage.read(key: _scheduleKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> scheduleList = jsonDecode(jsonString);
      return scheduleList.map((json) => ScheduleElement.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн расписания: $e');
      return [];
    }
  }

  Future<void> saveActivityRecords(List<ActivityRecord> activities) async {
    try {
      final activitiesToSave = activities.length > _maxActivities 
          ? activities.sublist(0, _maxActivities)
          : activities;
          
      final activitiesJson = activitiesToSave.map((activity) => activity.toJson()).toList();
      await _storage.write(key: _activityKey, value: jsonEncode(activitiesJson));
      print('💾 Активности сохранены офлайн: ${activitiesToSave.length} шт (лимит: $_maxActivities)');
    } catch (e) {
      print('❌ Ошибка сохранения активностей: $e');
    }
  }

  Future<List<ActivityRecord>> getActivityRecords() async {
    try {
      final jsonString = await _storage.read(key: _activityKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> activitiesList = jsonDecode(jsonString);
      return activitiesList.map((json) => ActivityRecord.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн активностей: $e');
      return [];
    }
  }

  Future<void> saveExams(List<Exam> exams) async {
    try {
      final examsToSave = exams.length > _maxExams 
          ? exams.sublist(0, _maxExams)
          : exams;
          
      final examsJson = examsToSave.map((exam) => exam.toJson()).toList();
      await _storage.write(key: _examsKey, value: jsonEncode(examsJson));
      print('💾 Экзамены сохранены офлайн: ${examsToSave.length} шт (лимит: $_maxExams)');
    } catch (e) {
      print('❌ Ошибка сохранения экзаменов: $e');
    }
  }

  Future<List<Exam>> getExams() async {
    try {
      final jsonString = await _storage.read(key: _examsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> examsList = jsonDecode(jsonString);
      return examsList.map((json) => Exam.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн экзаменов: $e');
      return [];
    }
  }

  Future<void> saveFeedbackReviews(List<FeedbackReview> feedbacks) async {
    try {
      final feedbacksToSave = feedbacks.length > _maxFeedbacks 
          ? feedbacks.sublist(0, _maxFeedbacks)
          : feedbacks;
          
      final feedbacksJson = feedbacksToSave.map((feedback) => feedback.toJson()).toList();
      await _storage.write(key: _feedbackKey, value: jsonEncode(feedbacksJson));
      print('💾 Отзывы сохранены офлайн: ${feedbacksToSave.length} шт (лимит: $_maxFeedbacks)');
    } catch (e) {
      print('❌ Ошибка сохранения отзывов: $e');
    }
  }

  Future<List<FeedbackReview>> getFeedbackReviews() async {
    try {
      final jsonString = await _storage.read(key: _feedbackKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> feedbacksList = jsonDecode(jsonString);
      return feedbacksList.map((json) => FeedbackReview.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн отзывов: $e');
      return [];
    }
  }

  Future<void> saveHomeworks(List<Homework> homeworks) async {
    try {
      final homeworksToSave = homeworks.length > _maxHomeworks 
          ? homeworks.sublist(0, _maxHomeworks)
          : homeworks;
          
      final homeworksJson = homeworksToSave.map((homework) => homework.toJson()).toList();
      await _storage.write(key: _homeworksKey, value: jsonEncode(homeworksJson));
      print('💾 Домашние задания сохранены офлайн: ${homeworksToSave.length} шт (лимит: $_maxHomeworks)');
    } catch (e) {
      print('❌ Ошибка сохранения домашних заданий: $e');
    }
  }

  Future<List<Homework>> getHomeworks() async {
    try {
      final jsonString = await _storage.read(key: _homeworksKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> homeworksList = jsonDecode(jsonString);
      return homeworksList.map((json) => Homework.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн домашних заданий: $e');
      return [];
    }
  }

  Future<void> saveGroupLeaders(List<LeaderboardUser> leaders) async {
    try {
      final leadersToSave = leaders.length > _maxLeaders 
          ? leaders.sublist(0, _maxLeaders)
          : leaders;
          
      final leadersJson = leadersToSave.map((leader) => leader.toJson()).toList();
      await _storage.write(key: _groupLeadersKey, value: jsonEncode(leadersJson));
      print('💾 Лидеры группы сохранены офлайн: ${leadersToSave.length} шт (лимит: $_maxLeaders)');
    } catch (e) {
      print('❌ Ошибка сохранения лидеров группы: $e');
    }
  }

  Future<List<LeaderboardUser>> getGroupLeaders() async {
    try {
      final jsonString = await _storage.read(key: _groupLeadersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> leadersList = jsonDecode(jsonString);
      return leadersList.map((json) => LeaderboardUser.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн лидеров группы: $e');
      return [];
    }
  }

  Future<void> saveStreamLeaders(List<LeaderboardUser> leaders) async {
    try {
      final leadersToSave = leaders.length > _maxLeaders 
          ? leaders.sublist(0, _maxLeaders)
          : leaders;
          
      final leadersJson = leadersToSave.map((leader) => leader.toJson()).toList();
      await _storage.write(key: _streamLeadersKey, value: jsonEncode(leadersJson));
      print('💾 Лидеры потока сохранены офлайн: ${leadersToSave.length} шт (лимит: $_maxLeaders)');
    } catch (e) {
      print('❌ Ошибка сохранения лидеров потока: $e');
    }
  }

  Future<List<LeaderboardUser>> getStreamLeaders() async {
    try {
      final jsonString = await _storage.read(key: _streamLeadersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> leadersList = jsonDecode(jsonString);
      return leadersList.map((json) => LeaderboardUser.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн лидеров потока: $e');
      return [];
    }
  }

  Future<void> saveHomeworkCounters(List<HomeworkCounter> counters) async {
    try {
      final countersJson = counters.map((counter) => counter.toJson()).toList();
      await _storage.write(key: _homeworkCountersKey, value: jsonEncode(countersJson));
      print('💾 Счетчики ДЗ сохранены офлайн: ${counters.length} шт');
    } catch (e) {
      print('❌ Ошибка сохранения счетчиков ДЗ: $e');
    }
  }

  Future<List<HomeworkCounter>> getHomeworkCounters() async {
    try {
      final jsonString = await _storage.read(key: _homeworkCountersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> countersList = jsonDecode(jsonString);
      return countersList.map((json) => HomeworkCounter.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки офлайн счетчиков ДЗ: $e');
      return [];
    }
  }

  /// Метод для очистки всех офлайн данных
  Future<void> clearAllOfflineData() async {
    try {
      await _storage.delete(key: _marksKey);
      await _storage.delete(key: _userKey);
      await _storage.delete(key: _scheduleKey);
      await _storage.delete(key: _activityKey);
      await _storage.delete(key: _examsKey);
      await _storage.delete(key: _feedbackKey);
      await _storage.delete(key: _homeworksKey);
      await _storage.delete(key: _groupLeadersKey);
      await _storage.delete(key: _streamLeadersKey);
      await _storage.delete(key: _homeworkCountersKey);
      
      print('🗑️ Все офлайн данные очищены');
    } catch (e) {
      print('❌ Ошибка очистки офлайн данных: $e');
    }
  }

  Future<Map<String, int>> getOfflineDataStats() async {
    final stats = <String, int>{};
    
    try {
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
      
    } catch (e) {
      print('❌ Ошибка получения статистики офлайн данных: $e');
    }
    
    return stats;
  }
}