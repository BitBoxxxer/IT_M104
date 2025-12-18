import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../../models/mark.dart';
import '../../models/user_data.dart';
import '../../models/days_element.dart';
import '../../models/leaderboard_user.dart';
import '../../models/feedback_review.dart';
import '../../models/_widgets/exams/exam.dart';
import '../../models/activity_record.dart';
import '../../models/_widgets/homework/homework.dart';
import '../../models/_widgets/homework/homework_counter.dart';

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

  static const String _homeworksType0Key = 'offline_homeworks_type_0';
  static const String _homeworksType1Key = 'offline_homeworks_type_1';
  static const String _homeworkCountersType0Key = 'offline_homework_counters_type_0';
  static const String _homeworkCountersType1Key = 'offline_homework_counters_type_1';


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
      print('💾 Оценки сохранены offline: ${marksToSave.length} шт (лимит: $_maxMarks)');
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
      print('❌ Ошибка загрузки offline оценок: $e');
      return [];
    }
  }

  Future<void> saveUserData(UserData user) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      print('💾 Данные пользователя сохранены offline');
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
      print('❌ Ошибка загрузки offline пользователя: $e');
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
      print('💾 Расписание сохранено offline: ${scheduleToSave.length} шт (лимит: $_maxSchedule)');
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
      print('❌ Ошибка загрузки offline расписания: $e');
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
      print('💾 Активности сохранены offline: ${activitiesToSave.length} шт (лимит: $_maxActivities)');
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
      print('❌ Ошибка загрузки offline активностей: $e');
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
      print('💾 Экзамены сохранены offline: ${examsToSave.length} шт (лимит: $_maxExams)');
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
      print('❌ Ошибка загрузки offline экзаменов: $e');
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
      print('💾 Отзывы сохранены offline: ${feedbacksToSave.length} шт (лимит: $_maxFeedbacks)');
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
      print('❌ Ошибка загрузки offline отзывов: $e');
      return [];
    }
  }

  Future<void> saveHomeworks(List<Homework> homeworks, {int? type}) async {
    try {
      final key = type == 1 ? _homeworksType1Key : _homeworksType0Key;
      final description = type == 1 ? 'лабораторные' : 'домашние';
      final existingHomeworks = await getHomeworks(type: type);
      final existingIds = existingHomeworks.map((h) => h.id).toSet();
      final newHomeworks = homeworks.where((h) => !existingIds.contains(h.id)).toList();
      final allHomeworks = [...existingHomeworks, ...newHomeworks];
      
      final homeworksToSave = allHomeworks.length > _maxHomeworks 
          ? allHomeworks.sublist(allHomeworks.length - _maxHomeworks)
          : allHomeworks;
          
      final homeworksJson = homeworksToSave.map((homework) => homework.toJson()).toList();
      await _storage.write(key: key, value: jsonEncode(homeworksJson));
      
      print('💾 $description задания сохранены offline: ${homeworksToSave.length} шт (+${newHomeworks.length} новых)');
      
      final typeStats = <int, int>{};
      for (var hw in homeworksToSave) {
        final materialType = hw.materialType ?? 0;
        typeStats[materialType] = (typeStats[materialType] ?? 0) + 1;
      }
      print('📊 Статистика materialType:');
      typeStats.forEach((mt, count) {
        print('   - materialType=$mt: $count заданий');
      });
      
    } catch (e) {
      print('❌ Ошибка сохранения домашних заданий: $e');
    }
  }

  Future<List<Homework>> getHomeworks({int? type}) async {
    try {
      final key = type == 1 ? _homeworksType1Key : _homeworksType0Key;
      final jsonString = await _storage.read(key: key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> homeworksList = jsonDecode(jsonString);
      return homeworksList.map((json) => Homework.fromJson(json)).toList();
      
    } catch (e) {
      print('❌ Ошибка загрузки offline домашних заданий: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHomeworksStats() async {
  try {
    final homeworksType0 = await getHomeworks(type: 0);
    final homeworksType1 = await getHomeworks(type: 1);
    
    final statsType0 = <int, int>{};
    final statsType1 = <int, int>{};
    
    for (var hw in homeworksType0) {
      final status = hw.getDisplayStatus();
      statsType0[status] = (statsType0[status] ?? 0) + 1;
    }
    
    for (var hw in homeworksType1) {
      final status = hw.getDisplayStatus();
      statsType1[status] = (statsType1[status] ?? 0) + 1;
    }
    
    print('📊 Статистика оффлайн заданий:');
    print('   Домашние (type=0): ${homeworksType0.length} заданий');
    statsType0.forEach((status, count) {
      print('     - Статус $status: $count заданий');
    });
    print('   Лабораторные (type=1): ${homeworksType1.length} заданий');
    statsType1.forEach((status, count) {
      print('     - Статус $status: $count заданий');
    });
    
    return {
      'type0_count': homeworksType0.length,
      'type1_count': homeworksType1.length,
      'type0_stats': statsType0,
      'type1_stats': statsType1,
    };
  } catch (e) {
    print('❌ Ошибка получения статистики заданий: $e');
    return {};
    }
  }

  Future<void> saveGroupLeaders(List<LeaderboardUser> leaders) async {
    try {
      final leadersToSave = leaders.length > _maxLeaders 
          ? leaders.sublist(0, _maxLeaders)
          : leaders;
          
      final leadersJson = leadersToSave.map((leader) => leader.toJson()).toList();
      await _storage.write(key: _groupLeadersKey, value: jsonEncode(leadersJson));
      print('💾 Лидеры группы сохранены offline: ${leadersToSave.length} шт (лимит: $_maxLeaders)');
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
      print('❌ Ошибка загрузки offline лидеров группы: $e');
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
      print('💾 Лидеры потока сохранены offline: ${leadersToSave.length} шт (лимит: $_maxLeaders)');
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
      print('❌ Ошибка загрузки offline лидеров потока: $e');
      return [];
    }
  }

  Future<void> saveHomeworkCounters(List<HomeworkCounter> counters, {int? type}) async {
    try {
      final key = type == 1 ? _homeworkCountersType1Key : _homeworkCountersType0Key;
      final description = type == 1 ? 'лабораторные' : 'домашние';
      
      final countersJson = counters.map((counter) => counter.toJson()).toList();
      await _storage.write(key: key, value: jsonEncode(countersJson));
      print('💾 Счетчики $description заданий сохранены offline: ${counters.length} шт');
    } catch (e) {
      print('❌ Ошибка сохранения счетчиков ДЗ: $e');
    }
  }

  Future<List<HomeworkCounter>> getHomeworkCounters({int? type}) async {
    try {
      final key = type == 1 ? _homeworkCountersType1Key : _homeworkCountersType0Key;
      final jsonString = await _storage.read(key: key);
      
      if (jsonString == null || jsonString.isEmpty) {
        final oldJsonString = await _storage.read(key: _homeworkCountersKey);
        if (oldJsonString == null || oldJsonString.isEmpty) {
          return [];
        }
        
        final List<dynamic> countersList = jsonDecode(oldJsonString);
        return countersList.map((json) => HomeworkCounter.fromJson(json)).toList();
      }
      
      final List<dynamic> countersList = jsonDecode(jsonString);
      return countersList.map((json) => HomeworkCounter.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки offline счетчиков ДЗ: $e');
      return [];
    }
  }

  /// Метод для очистки всех offline данных
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
      await _storage.delete(key: _homeworkCountersType0Key);
      await _storage.delete(key: _homeworkCountersType1Key);
      
      print('🗑️ Все offline данные очищены');
    } catch (e) {
      print('❌ Ошибка очистки offline данных: $e');
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
      print('❌ Ошибка получения статистики offline данных: $e');
    }
    
    return stats;
  }

  // TODO Вынести позже в отдельную директиву по архитектуре проекта. - Ди 13.12.25
  /// Фильтрация по статусу HomeWork (Домашние / Лабораторные)
  Future<List<Homework>> getHomeworksByStatus(int? status, {int? type}) async {
    try {
      final homeworks = await getHomeworks(type: type);
      
      if (status != null) {
        return homeworks.where((hw) => hw.getDisplayStatus() == status).toList();
      }
      
      return homeworks;
    } catch (e) {
      print('❌ Ошибка загрузки offline домашних заданий: $e');
      return [];
    }
  }

  /// Получить статистику по статусам домашних заданий в оффлайн кэше
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
        final statusString = hw.statusString;
        
        print('📝 Задание ${hw.id} "${hw.theme}": realStatus=$status, statusString=$statusString');
        
        switch (status) {
          case 0: stats['expired'] = stats['expired']! + 1; break;
          case 1: stats['done'] = stats['done']! + 1; break;
          case 2: stats['inspection'] = stats['inspection']! + 1; break;
          case 3: stats['opened'] = stats['opened']! + 1; break;
          case 5: stats['deleted'] = stats['deleted']! + 1; break;
        }
      }
      
      print('📊 Статистика статусов в оффлайн кэше:');
      stats.forEach((status, count) {
        print('  - $status: $count заданий');
      });
      
      return stats;
    } catch (e) {
      print('❌ Ошибка получения статистики: $e');
      return {};
    }
  }

  Future<void> debugHomeworkTypes() async {
    try {
      print('🔍 Диагностика типов заданий в оффлайн хранилище:');
      
      // Получаем все задания
      final allHomeworks = await getHomeworks();
      print('Всего заданий: ${allHomeworks.length}');
      
      // Группируем по materialType
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
      
      final type0Homeworks = await getHomeworks(type: 0);
      final type1Homeworks = await getHomeworks(type: 1);
      
      print('Разделенное хранение:');
      print('   type=0: ${type0Homeworks.length} заданий');
      print('   type=1: ${type1Homeworks.length} заданий');
      
    } catch (e) {
      print('❌ Ошибка диагностики: $e');
    }
  }

  /// Исправление старых данных в хранилище
  Future<void> fixHomeworkStorageData() async {
    try {
      print('🛠️ Начинаем исправление данных в хранилище...');
      
      await _storage.delete(key: _homeworksKey);
      await _storage.delete(key: _homeworksType0Key);
      await _storage.delete(key: _homeworksType1Key);
      
      print('✅ Данные в хранилище очищены');
      
      await _storage.write(key: _homeworksType0Key, value: jsonEncode([]));
      await _storage.write(key: _homeworksType1Key, value: jsonEncode([]));
      
      print('✅ Хранилища инициализированы заново');
      
    } catch (e) {
      print('❌ Ошибка исправления данных: $e');
    }
  }

  /// Диагностика хранилища
  Future<void> diagnoseHomeworkStorage() async {
    try {
      print('🔍 Диагностика хранилища заданий:');
      
      final keys = [_homeworksKey, _homeworksType0Key, _homeworksType1Key];
      
      for (var key in keys) {
        final data = await _storage.read(key: key);
        final count = data != null && data.isNotEmpty 
            ? jsonDecode(data).length 
            : 0;
        print('   $key: $count записей');
      }
      
    } catch (e) {
      print('❌ Ошибка диагностики: $e');
    }
  }

  Future<void> fixHomeworkCounters() async {
    try {
      print('🛠️ Исправляем счетчики заданий...');
      
      await _storage.delete(key: _homeworkCountersKey);
      await _storage.delete(key: _homeworkCountersType0Key);
      await _storage.delete(key: _homeworkCountersType1Key);
      
      await _storage.write(key: _homeworkCountersType0Key, value: jsonEncode([]));
      await _storage.write(key: _homeworkCountersType1Key, value: jsonEncode([]));
      
      print('✅ Счетчики исправлены - готовы для новой синхронизации');
    } catch (e) {
      print('❌ Ошибка исправления счетчиков: $e');
    }
  }
}