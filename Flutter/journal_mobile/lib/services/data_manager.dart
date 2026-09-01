// file: data_manager.dart
import 'package:journal_mobile/services/_account/account_manager_service.dart';
import 'package:journal_mobile/services/api_service.dart';

import '../models/days_element.dart';
import '../models/mark.dart';
import '../models/user_data.dart';
import '_offline_service/offline_storage_service.dart';
import '../core/schedule_date_utils.dart';

/// Единый менеджер данных с приоритетом SQLite
class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  final ApiService _apiService = ApiService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final AccountManagerService _accountManager = AccountManagerService();

  /// Основной метод получения данных с автоматическим кэшированием
  Future<T> fetchData<T>({
    required String dataType,
    required Future<T> Function() onlineFetch,
    required Future<T?> Function() offlineFetch,
    required Future<void> Function(T) saveToStorage,
    Duration cacheDuration = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Проверяем, нужна ли принудительная синхронизация
      if (forceRefresh) {
        final data = await onlineFetch();
        await saveToStorage(data);
        return data;
      }

      // 2. Пробуем получить из SQLite
      final offlineData = await offlineFetch();
      if (offlineData != null) {
        print('📱 Используем данные из SQLite: $dataType');
        
        // 3. Фоновая синхронизация
        _backgroundSync(onlineFetch, saveToStorage);
        
        return offlineData;
      }

      // 4. Если данных нет в SQLite, загружаем из сети
      final onlineData = await onlineFetch();
      await saveToStorage(onlineData);
      print('🌐 Данные загружены из сети: $dataType');
      
      return onlineData;
    } catch (e) {
      print('❌ Ошибка получения данных $dataType: $e');
      
      // 5. Fallback: пробуем получить из SQLite
      final fallbackData = await offlineFetch();
      if (fallbackData != null) {
        print('🔄 Используем fallback данные из SQLite: $dataType');
        return fallbackData;
      }
      
      rethrow;
    }
  }

  /// Фоновая синхронизация
  void _backgroundSync<T>(
    Future<T> Function() onlineFetch,
    Future<void> Function(T) saveToStorage,
  ) async {
    try {
      final data = await onlineFetch();
      await saveToStorage(data);
      print('✅ Фоновая синхронизация завершена');
    } catch (e) {
      print('⚠️ Фоновая синхронизация не удалась: $e');
    }
  }

  /// Методы для конкретных типов данных
  Future<List<Mark>> getMarks({bool forceRefresh = false}) async {
    return await fetchData<List<Mark>>(
      dataType: 'marks',
      onlineFetch: () => _apiService.getMarksForCurrentAccount(),
      offlineFetch: () => _offlineStorage.getMarks(),
      saveToStorage: (marks) => _offlineStorage.saveMarks(marks),
      forceRefresh: forceRefresh,
    );
  }

  Future<UserData> getUserData({bool forceRefresh = false}) async {
    return await fetchData<UserData>(
      dataType: 'user_data',
      onlineFetch: () async {
        final token = await _apiService.getCurrentToken();
        return await _apiService.getUser(token);
      },
      offlineFetch: () => _offlineStorage.getUserData(),
      saveToStorage: (user) => _offlineStorage.saveUserData(user),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<ScheduleElement>> getSchedule({
    required String dateFrom,
    required String dateTo,
    bool forceRefresh = false,
  }) async {
    final rangeStart = DateTime.parse(dateFrom);
    final rangeEnd = DateTime.parse(dateTo);

    return await fetchData<List<ScheduleElement>>(
      dataType: 'schedule',
      onlineFetch: () async {
        final token = await _apiService.getCurrentToken();
        return await _apiService.getSchedule(token, dateFrom, dateTo);
      },
      // Раньше тут забиралось ВСЁ расписание аккаунта из SQLite (все недели
      // вперемешку), теперь — только запрошенный диапазон дат.
      offlineFetch: () => _offlineStorage.getScheduleByDateRange(rangeStart, rangeEnd),
      saveToStorage: (schedule) => _offlineStorage.saveSchedule(
        schedule,
        weekStart: rangeStart,
        weekEnd: rangeEnd,
      ),
      forceRefresh: forceRefresh,
    );
  }

  /// Пакетная синхронизация
  Future<void> syncAllData({bool background = false}) async {
    try {
      print('🔄 ${background ? 'Фоновая' : 'Полная'} синхронизация...');
      
      final token = await _apiService.getCurrentToken();

      // Критические данные
      final userData = await getUserData(forceRefresh: true);
      final marks = await getMarks(forceRefresh: true);

      if (!background) {
        // Второстепенные данные только при ручной синхронизации
        final now = DateTime.now();
        final monday = getMonday(now);
        final sunday = getSunday(now);
        
        await getSchedule(
          dateFrom: formatDate(monday),
          dateTo: formatDate(sunday),
          forceRefresh: true,
        );
        
        // Лидерборды
        await _fetchLeaders(token);
        
        // Экзамены и ДЗ
        await _fetchExamsAndHomeworks(token);
      }
      
      print('✅ Синхронизация завершена');
    } catch (e) {
      print('❌ Ошибка синхронизации: $e');
    }
  }

  /// Вспомогательные методы
  Future<void> _fetchLeaders(String token) async {
    try {
      final groupLeaders = await _apiService.getGroupLeaders(token);
      await _offlineStorage.saveGroupLeaders(groupLeaders);
      
      final streamLeaders = await _apiService.getStreamLeaders(token);
      await _offlineStorage.saveStreamLeaders(streamLeaders);
    } catch (e) {
      print('⚠️ Ошибка загрузки лидеров: $e');
    }
  }

  Future<void> _fetchExamsAndHomeworks(String token) async {
    try {
      final exams = await _apiService.getExams(token);
      await _offlineStorage.saveExams(exams);
      
      final homeworks = await _apiService.getHomeworks(token);
      await _offlineStorage.saveHomeworks(homeworks);
    } catch (e) {
      print('⚠️ Ошибка загрузки экзаменов и ДЗ: $e');
    }
  }

  /// Проверка наличия минимальных оффлайн данных
  Future<bool> hasOfflineData() async {
    try {
      final userData = await _offlineStorage.getUserData();
      final marks = await _offlineStorage.getMarks();
      
      return userData != null && marks.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Очистка всех данных
  Future<void> clearAllData() async {
    try {
      final account = await _accountManager.getCurrentAccount();
      if (account != null) {
        await _offlineStorage.clearAllOfflineData();
        print('✅ Все данные очищены');
      }
    } catch (e) {
      print('❌ Ошибка очистки данных: $e');
    }
  }
}