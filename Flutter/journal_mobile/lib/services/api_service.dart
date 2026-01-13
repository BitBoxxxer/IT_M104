import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../_database/database_config.dart';
import '_account/account_manager_service.dart';

import '../_database/database_facade.dart';
import '../_database/repositories/cache_repository.dart';

import '../models/_system/account_model.dart';
import '../models/mark.dart';
import '../models/user_data.dart';
import '../models/days_element.dart';
import '../models/leaderboard_user.dart';
import '../models/leader_position_model.dart';
import '../models/feedback_review.dart';
import '../models/_widgets/exams/exam.dart';
import '../models/activity_record.dart';
import '../models/_widgets/homework/homework.dart';
import '../models/_widgets/homework/homework_counter.dart';
import 'download_service.dart';

class CacheKeys {
  static const String marks = 'marks_cache';
  static const String user = 'user_cache';
  static const String schedule = 'schedule_cache';
  static const String groupLeaders = 'group_leaders_cache';
  static const String streamLeaders = 'stream_leaders_cache';
  static const String feedback = 'feedback_cache';
  static const String exams = 'exams_cache';
  static const String futureExams = 'future_exams_cache';
  static const String activity = 'activity_cache';
  static const String homeworks = 'homeworks_cache';
  static const String homeworkCounters = 'homework_counters_cache';
  
  static String getMarksCacheKey(String accountId) => '${marks}_$accountId';
  static String getUserCacheKey(String accountId) => '${user}_$accountId';
  static String getScheduleCacheKey(String accountId, String dateFrom, String dateTo) => 
      '${schedule}_${accountId}_${dateFrom}_$dateTo';
}

/// не трогать КОД - НИКОМУ кроме КЕЙСИ (Дианы) !!! НИЗАЧТО (сломаю пальцы и в жопу засуну).
/// Подумайте дважды прежде чем что-то менять здесь. Иначе - ломайте себе пальцы по одному.
class ApiService {
  final String _baseUrl = "https://msapi.top-academy.ru/api/v2"; 
  final DatabaseFacade _databaseFacade = DatabaseFacade();
  final AccountManagerService _accountManager = AccountManagerService();
  final CacheRepository _cacheRepository = CacheRepository();
  
  static int _activeRequests = 0;
  static const int _maxConcurrentRequests = 3;
  static const Duration _timeOut = Duration(seconds: 15);
  static const Duration _shortTimeOut = Duration(seconds: 10);
  
  bool _isDisposed = false;
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  final Map<String, dynamic> _memoryCache = {};

  static const int _cacheTtlShort = 300;    // 5 минут
  static const int _cacheTtlMedium = 1800;  // 30 минут
  
  Future<T> _executeWithLimit<T>(String requestKey, Future<T> Function() request) async {
    if (_isDisposed) throw Exception('ApiService disposed');
    
    if (_pendingRequests.containsKey(requestKey)) {
      return await _pendingRequests[requestKey]!.future as T;
    }
    
    final completer = Completer<T>();
    _pendingRequests[requestKey] = completer;
    
    while (_activeRequests >= _maxConcurrentRequests && !_isDisposed) {
      await Future.delayed(Duration(milliseconds: 50));
    }
    
    if (_isDisposed) {
      completer.completeError(Exception('Service disposed'));
      throw Exception('Service disposed');
    }
    
    _activeRequests++;
    
    try {
      final result = await request().timeout(_timeOut);
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _activeRequests--;
      _pendingRequests.remove(requestKey);
    }
  }

  String _getRequestKey(String endpoint, [String? params]) {
    return '$endpoint${params ?? ''}';
  }

  /// Получить ID текущего аккаунта
  Future<String> _getCurrentAccountId() async {
    final account = await _accountManager.getCurrentAccount();
    if (account == null) {
      throw Exception('Нет активного аккаунта');
    }
    return account.id;
  }

  /// Получить токен текущего аккаунта
  Future<String> getCurrentToken() async {
    final account = await _accountManager.getCurrentAccount();
    if (account == null) {
      throw Exception('Нет активного аккаунта');
    }
    return account.token;
  }

  /// Основной метод запроса с обработкой 401
  Future<http.Response> _makeRequest(
  String url, {
  String? token,
  Map<String, String>? headers,
  dynamic body,
  String method = 'GET',
}) async {
  final currentToken = token ?? await getCurrentToken();
  final defaultHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $currentToken',
    'Referer': 'https://journal.top-academy.ru',
  };
  
  if (headers != null) {
    defaultHeaders.addAll(headers);
  }

  switch (method.toUpperCase()) {
    case 'POST':
      return await http.post(
        Uri.parse(url),
        headers: defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeOut);
      
    case 'PUT':
      return await http.put(
        Uri.parse(url),
        headers: defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeOut);
      
    case 'DELETE':
      return await http.delete(
        Uri.parse(url),
        headers: defaultHeaders,
      ).timeout(_timeOut);
      
    default: // GET
      return await http.get(
        Uri.parse(url),
        headers: defaultHeaders,
      ).timeout(_timeOut);
  }
}


  Future<String?> login(String username, String password) async {
    return await _executeWithLimit(
      _getRequestKey('login'),
      () async {
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Referer': 'https://journal.top-academy.ru',
          },
          body: jsonEncode({
            'username': username,
            'password': password,
            'application_key': '6a56a5df2667e65aab73ce76d1dd737f7d1faef9c52e8b8c55ac75f565d8e8a6',
          }),
        ).timeout(_shortTimeOut);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final token = data['access_token'];
        final accountManager = AccountManagerService();
        
        UserData? userData;
        try {
          final userResponse = await _makeRequest('$_baseUrl/settings/user-info', token: token);
          if (userResponse.statusCode == 200) {
            userData = UserData.fromJson(jsonDecode(userResponse.body));
          }
          } catch (e) {
            print('⚠️ Ошибка загрузки данных пользователя: $e');
          }
          /// временная глушилка для создания пустой оболочки
        await accountManager.addAccountWithCredentials(
          username: username,
          password: password,
          token: token,
          fullName: userData?.fullName ?? '',
          groupName: userData?.groupName ?? '',
          photoPath: userData?.photoPath ?? '',
          studentId: userData?.studentId ?? 0,
        );
          
          return token;
        } else {
          print("Login failed: ${response.statusCode}");
          return null;
        }
      },
    );
  }

  Future<Account> loginAndCreateAccount(String username, String password) async {
    final token = await login(username, password);
    
    if (token == null) {
      throw Exception('Ошибка авторизации');
    }
    
    // Аккаунт уже создан в методе login
    final account = await _accountManager.getCurrentAccount();
    if (account == null) {
      throw Exception('Ошибка создания аккаунта');
    }
    
    return account;
  }

  /// ==================== DATA METHODS WITH SQLite ====================

  /// Получение оценок с сохранением в SQLite
  Future<List<Mark>> getMarks(String token) async {
    return await _executeWithLimit(
      _getRequestKey('marks'),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final response = await _makeRequest('$_baseUrl/progress/operations/student-visits');
          
          if (response.statusCode == 200) {
            final List<dynamic> marksData = jsonDecode(response.body);
            final marks = marksData.map((json) => Mark.fromJson(json)).toList();
            
            // Сохраняем в SQLite
            await _databaseFacade.saveMarks(marks, accountId);
            
            // Кэшируем в памяти на короткое время
            await _cacheRepository.save(
              CacheKeys.getMarksCacheKey(accountId),
              marks,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlShort),
            );
            
            print('✅ Оценки загружены и сохранены в SQLite: ${marks.length} шт');
            
            return marks;
          } else {
            print("Failed to load marks: ${response.statusCode}");
            
            // Пробуем загрузить из SQLite
            final offlineMarks = await _databaseFacade.getMarks(accountId);
            if (offlineMarks.isNotEmpty) {
              print('📱 Используем оценки из SQLite: ${offlineMarks.length} шт');
              return offlineMarks;
            }
            
            throw Exception('Failed to load marks: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки оценок: $e');
          
          // Пробуем загрузить из кэша
          final cachedData = await _cacheRepository.get(CacheKeys.getMarksCacheKey(accountId), accountId: accountId);
          if (cachedData is List) {
            final cachedMarks = cachedData.map((item) => Mark.fromJson(item)).toList();
            return cachedMarks;
          }
          
          if (cachedData != null && cachedData.isNotEmpty) {
            print('💾 Используем оценки из кэша: ${cachedData.length} шт');
            return cachedData;
          }
          
          // Пробуем из SQLite
          final offlineMarks = await _databaseFacade.getMarks(accountId);
          if (offlineMarks.isNotEmpty) {
            print('🗄️ Используем оценки из SQLite: ${offlineMarks.length} шт');
            return offlineMarks;
          }
          
          rethrow;
        }
      },
    );
  }

  Future<List<Mark>> getMarksForCurrentAccount() async {
    final account = await _accountManager.getCurrentAccount();
    if (account == null) {
      throw Exception('Нет активного аккаунта');
    }
    return await getMarks(account.token);
  }

  /// Получение данных пользователя с сохранением в SQLite
  Future<UserData> getUser(String token) async {
    return await _executeWithLimit(
      _getRequestKey('user'),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final response = await _makeRequest('$_baseUrl/settings/user-info');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final user = UserData.fromJson(data);
            
            // Сохраняем в SQLite
            await _databaseFacade.saveUserData(user, accountId);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.getUserCacheKey(accountId),
              user,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlMedium),
            );
            
            print('✅ Данные пользователя загружены и сохранены в SQLite');
            
            return user;
          } else {
            print("Failed to load user data: ${response.statusCode}");
            
            // Пробуем из SQLite
            final offlineUser = await _databaseFacade.getUserData(accountId);
            if (offlineUser != null) {
              print('📱 Используем данные пользователя из SQLite');
              return offlineUser;
            }
            
            throw Exception('Failed to load user data: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки пользователя: $e');
          
          // Пробуем из кэша
          final cachedUser = await _cacheRepository.get<UserData>(
            CacheKeys.getUserCacheKey(accountId),
            accountId: accountId,
          );
          
          if (cachedUser != null) {
            print('💾 Используем данные пользователя из кэша');
            return cachedUser;
          }
          
          // Пробуем из SQLite
          final offlineUser = await _databaseFacade.getUserData(accountId);
          if (offlineUser != null) {
            print('🗄️ Используем данные пользователя из SQLite');
            return offlineUser;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение расписания с сохранением в SQLite
  Future<List<ScheduleElement>> getSchedule(String token, String dateFrom, String dateTo) async {
    return await _executeWithLimit(
      _getRequestKey('schedule', '$dateFrom-$dateTo'),
      () async {
        final accountId = await _getCurrentAccountId();
        final cacheKey = CacheKeys.getScheduleCacheKey(accountId, dateFrom, dateTo);
        
        try {
          final response = await _makeRequest(
            '$_baseUrl/schedule/operations/get-by-date-range?date_start=$dateFrom&date_end=$dateTo',
          );
          
          if (response.statusCode == 200) {
            final List<dynamic> scheduleData = jsonDecode(response.body);
            final schedule = scheduleData
                .map((json) => ScheduleElement.fromJson(json as Map<String, dynamic>))
                .toList();
            
            // Сохраняем в SQLite
            await _databaseFacade.saveSchedule(schedule, accountId);
            
            // Кэшируем
            await _cacheRepository.save(
              cacheKey,
              schedule,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlMedium),
            );
            
            print('✅ Расписание загружено и сохранено в SQLite: ${schedule.length} шт');
            
            return schedule;
          } else {
            print("Failed to load schedule: ${response.statusCode}");
            
            // Пробуем из SQLite (все расписание)
            final offlineSchedule = await _databaseFacade.getSchedule(accountId);
            if (offlineSchedule.isNotEmpty) {
              print('📱 Используем расписание из SQLite: ${offlineSchedule.length} шт');
              return offlineSchedule;
            }
            
            throw Exception('Failed to load schedule: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки расписания: $e');
          
          // Пробуем из кэша
          final cachedSchedule = await _cacheRepository.get<List<ScheduleElement>>(
            cacheKey,
            accountId: accountId,
          );
          
          if (cachedSchedule != null && cachedSchedule.isNotEmpty) {
            print('💾 Используем расписание из кэша: ${cachedSchedule.length} шт');
            return cachedSchedule;
          }
          
          // Пробуем из SQLite
          final offlineSchedule = await _databaseFacade.getSchedule(accountId);
          if (offlineSchedule.isNotEmpty) {
            print('🗄️ Используем расписание из SQLite: ${offlineSchedule.length} шт');
            return offlineSchedule;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение лидеров группы с сохранением в SQLite
  Future<List<LeaderboardUser>> getGroupLeaders(String token) async {
    return await _executeWithLimit(
      _getRequestKey('group_leaders'),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final response = await _makeRequest('$_baseUrl/dashboard/progress/leader-group');
          
          if (response.statusCode == 200) {
            List<LeaderboardUser> leaders;
            
            try {
              final List<dynamic> leadersData = jsonDecode(response.body);
              leaders = leadersData.map((json) => LeaderboardUser.fromJson(json)).toList();
            } catch (e) {
              print("Error parsing group leaders: $e");
              try {
                final groupModel = GroupPositionModel.fromJson(jsonDecode(response.body));
                leaders = groupModel.groupLeaders;
              } catch (e2) {
                print("Alternative parsing also failed: $e2");
                throw Exception('Failed to parse group leaders data');
              }
            }
            
            // Сохраняем в SQLite
            await _databaseFacade.saveGroupLeaders(leaders, accountId);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.groupLeaders,
              leaders,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlShort),
            );
            
            print('✅ Лидеры группы загружены и сохранены в SQLite: ${leaders.length} шт');
            
            return leaders;
          } else {
            print("Failed to load group leaders: ${response.statusCode}");
            
            // Пробуем из SQLite
            final offlineLeaders = await _databaseFacade.getGroupLeaders(accountId);
            if (offlineLeaders.isNotEmpty) {
              print('📱 Используем лидеров группы из SQLite: ${offlineLeaders.length} шт');
              return offlineLeaders;
            }
            
            throw Exception('Failed to load group leaders: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки лидеров группы: $e');
          
          // Пробуем из кэша
          final cachedLeaders = await _cacheRepository.get<List<LeaderboardUser>>(
            CacheKeys.groupLeaders,
            accountId: accountId,
          );
          
          if (cachedLeaders != null && cachedLeaders.isNotEmpty) {
            print('💾 Используем лидеров группы из кэша: ${cachedLeaders.length} шт');
            return cachedLeaders;
          }
          
          // Пробуем из SQLite
          final offlineLeaders = await _databaseFacade.getGroupLeaders(accountId);
          if (offlineLeaders.isNotEmpty) {
            print('🗄️ Используем лидеров группы из SQLite: ${offlineLeaders.length} шт');
            return offlineLeaders;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение лидеров потока с сохранением в SQLite
  Future<List<LeaderboardUser>> getStreamLeaders(String token) async {
    return await _executeWithLimit(
      _getRequestKey('stream_leaders'),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final response = await _makeRequest('$_baseUrl/dashboard/progress/leader-stream');
          
          if (response.statusCode == 200) {
            List<LeaderboardUser> leaders;
            
            try {
              final List<dynamic> leadersData = jsonDecode(response.body);
              leaders = leadersData.map((json) => LeaderboardUser.fromJson(json)).toList();
            } catch (e) {
              print("Error parsing stream leaders: $e");
              try {
                final streamModel = StreamPositionModel.fromJson(jsonDecode(response.body));
                leaders = streamModel.streamLeaders;
              } catch (e2) {
                print("Alternative parsing also failed: $e2");
                throw Exception('Failed to parse stream leaders data');
              }
            }
            
            // Сохраняем в SQLite
            await _databaseFacade.saveStreamLeaders(leaders, accountId);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.streamLeaders,
              leaders,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlShort),
            );
            
            print('✅ Лидеры потока загружены и сохранены в SQLite: ${leaders.length} шт');
            
            return leaders;
          } else {
            print("Failed to load stream leaders: ${response.statusCode}");
            
            // Пробуем из SQLite
            final offlineLeaders = await _databaseFacade.getStreamLeaders(accountId);
            if (offlineLeaders.isNotEmpty) {
              print('📱 Используем лидеров потока из SQLite: ${offlineLeaders.length} шт');
              return offlineLeaders;
            }
            
            throw Exception('Failed to load stream leaders: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки лидеров потока: $e');
          
          // Пробуем из кэша
          final cachedLeaders = await _cacheRepository.get<List<LeaderboardUser>>(
            CacheKeys.streamLeaders,
            accountId: accountId,
          );
          
          if (cachedLeaders != null && cachedLeaders.isNotEmpty) {
            print('💾 Используем лидеров потока из кэша: ${cachedLeaders.length} шт');
            return cachedLeaders;
          }
          
          // Пробуем из SQLite
          final offlineLeaders = await _databaseFacade.getStreamLeaders(accountId);
          if (offlineLeaders.isNotEmpty) {
            print('🗄️ Используем лидеров потока из SQLite: ${offlineLeaders.length} шт');
            return offlineLeaders;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение отзывов с сохранением в SQLite
  Future<List<FeedbackReview>> getFeedbackReview(String token) async {
    return await _executeWithLimit(
      _getRequestKey('feedback'),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final response = await _makeRequest('$_baseUrl/reviews/index/list');
          
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            List<dynamic> feedbackData = [];
            
            if (responseData is List) {
              feedbackData = responseData;
            } else if (responseData['data'] is List) {
              feedbackData = responseData['data'];
            } else if (responseData['reviews'] is List) {
              feedbackData = responseData['reviews'];
            } else if (responseData['items'] is List) {
              feedbackData = responseData['items'];
            }
            
            final feedbacks = feedbackData.map((json) => FeedbackReview.fromJson(json)).toList();
            
            // Сохраняем в SQLite
            await _databaseFacade.saveFeedbacks(feedbacks, accountId);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.feedback,
              feedbacks,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlMedium),
            );
            
            print('✅ Отзывы загружены и сохранены в SQLite: ${feedbacks.length} шт');
            
            return feedbacks;
          } else {
            print("Failed to load feedback: ${response.statusCode}");
            
            // Пробуем из SQLite
            final offlineFeedbacks = await _databaseFacade.getFeedbacks(accountId);
            if (offlineFeedbacks.isNotEmpty) {
              print('📱 Используем отзывы из SQLite: ${offlineFeedbacks.length} шт');
              return offlineFeedbacks;
            }
            
            throw Exception('Failed to load feedback: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки отзывов: $e');
          
          // Пробуем из кэша
          final cachedFeedbacks = await _cacheRepository.get<List<FeedbackReview>>(
            CacheKeys.feedback,
            accountId: accountId,
          );
          
          if (cachedFeedbacks != null && cachedFeedbacks.isNotEmpty) {
            print('💾 Используем отзывы из кэша: ${cachedFeedbacks.length} шт');
            return cachedFeedbacks;
          }
          
          // Пробуем из SQLite
          final offlineFeedbacks = await _databaseFacade.getFeedbacks(accountId);
          if (offlineFeedbacks.isNotEmpty) {
            print('🗄️ Используем отзывы из SQLite: ${offlineFeedbacks.length} шт');
            return offlineFeedbacks;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение экзаменов с сохранением в SQLite
  Future<List<Exam>> getExams(String token) async {
    return await _executeWithLimit(
      _getRequestKey('exams'),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final response = await _makeRequest('$_baseUrl/progress/operations/student-exams');
          
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            List<dynamic> examsData = [];
            
            if (responseData is List) {
              examsData = responseData;
            } else if (responseData['data'] is List) {
              examsData = responseData['data'];
            } else if (responseData['exams'] is List) {
              examsData = responseData['exams'];
            } else if (responseData['grades'] is List) {
              examsData = responseData['grades'];
            } else if (responseData['items'] is List) {
              examsData = responseData['items'];
            }
            
            final exams = examsData.map((json) => Exam.fromJson(json)).toList();
            
            // Сохраняем в SQLite
            await _databaseFacade.saveExams(exams, accountId);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.exams,
              exams,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlMedium),
            );
            
            print('✅ Экзамены загружены и сохранены в SQLite: ${exams.length} шт');
            
            return exams;
          } else {
            print("Failed to load exams: ${response.statusCode}");
            
            // Пробуем из SQLite
            final offlineExams = await _databaseFacade.getExams(accountId);
            if (offlineExams.isNotEmpty) {
              print('📱 Используем экзамены из SQLite: ${offlineExams.length} шт');
              return offlineExams;
            }
            
            throw Exception('Failed to load exams: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки экзаменов: $e');
          
          // Пробуем из кэша
          final cachedExams = await _cacheRepository.get<List<Exam>>(
            CacheKeys.exams,
            accountId: accountId,
          );
          
          if (cachedExams != null && cachedExams.isNotEmpty) {
            print('💾 Используем экзамены из кэша: ${cachedExams.length} шт');
            return cachedExams;
          }
          
          // Пробуем из SQLite
          final offlineExams = await _databaseFacade.getExams(accountId);
          if (offlineExams.isNotEmpty) {
            print('🗄️ Используем экзамены из SQLite: ${offlineExams.length} шт');
            return offlineExams;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение предстоящих экзаменов с сохранением в SQLite
  Future<List<Exam>> getFutureExams(String token) async {
    return await _executeWithLimit(
      _getRequestKey('future_exams'),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final response = await _makeRequest('$_baseUrl/dashboard/info/future-exams');
          
          if (response.statusCode == 200) {
            final List<dynamic> futureExamsData = jsonDecode(response.body);
            final exams = futureExamsData.map((json) => Exam.fromJson(json)).toList();
            
            // Сохраняем в SQLite
            await _databaseFacade.saveExams(exams, accountId);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.futureExams,
              exams,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlShort),
            );
            
            print('✅ Предстоящие экзамены загружены и сохранены в SQLite: ${exams.length} шт');
            
            return exams;
          } else {
            print("Failed to load future exams: ${response.statusCode}");
            
            // Пробуем из SQLite (все экзамены)
            final offlineExams = await _databaseFacade.getExams(accountId);
            if (offlineExams.isNotEmpty) {
              print('📱 Используем экзамены из SQLite: ${offlineExams.length} шт');
              return offlineExams;
            }
            
            throw Exception('Failed to load future exams: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки предстоящих экзаменов: $e');
          
          // Пробуем из кэша
          final cachedExams = await _cacheRepository.get<List<Exam>>(
            CacheKeys.futureExams,
            accountId: accountId,
          );
          
          if (cachedExams != null && cachedExams.isNotEmpty) {
            print('💾 Используем экзамены из кэша: ${cachedExams.length} шт');
            return cachedExams;
          }
          
          // Пробуем из SQLite
          final offlineExams = await _databaseFacade.getExams(accountId);
          if (offlineExams.isNotEmpty) {
            print('🗄️ Используем экзамены из SQLite: ${offlineExams.length} шт');
            return offlineExams;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение активности с сохранением в SQLite
  Future<List<ActivityRecord>> getProgressActivity(String token) async {
    return await _executeWithLimit(
      _getRequestKey('activity'),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final response = await _makeRequest('$_baseUrl/dashboard/progress/activity');
          
          if (response.statusCode == 200) {
            final List<dynamic> activityData = jsonDecode(response.body);
            final activities = activityData.map((json) => ActivityRecord.fromJson(json)).toList();
            
            // Сохраняем в SQLite
            await _databaseFacade.saveActivities(activities, accountId, strategy: SyncStrategy.append);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.activity,
              activities,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlShort),
            );
            
            print('✅ Активности загружены и сохранены в SQLite: ${activities.length} шт');
            
            return activities;
          } else {
            print("Failed to load activity data: ${response.statusCode}");
            
            // Пробуем из SQLite
            final offlineActivities = await _databaseFacade.getActivities(accountId);
            if (offlineActivities.isNotEmpty) {
              print('📱 Используем активности из SQLite: ${offlineActivities.length} шт');
              return offlineActivities;
            }
            
            throw Exception('Failed to load activity data: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки активностей: $e');
          
          // Пробуем из кэша
          final cachedActivities = await _cacheRepository.get<List<ActivityRecord>>(
            CacheKeys.activity,
            accountId: accountId,
          );
          
          if (cachedActivities != null && cachedActivities.isNotEmpty) {
            print('💾 Используем активности из кэша: ${cachedActivities.length} шт');
            return cachedActivities;
          }
          
          // Пробуем из SQLite
          final offlineActivities = await _databaseFacade.getActivities(accountId);
          if (offlineActivities.isNotEmpty) {
            print('🗄️ Используем активности из SQLite: ${offlineActivities.length} шт');
            return offlineActivities;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение домашних заданий с сохранением в SQLite
  Future<List<Homework>> getHomeworks(
    String token, {
    int? page,
    int? status,
    int? groupId,
    int? specId,
    int? type,
  }) async {
    final params = '${page ?? ''}_${status ?? ''}_${groupId ?? ''}_${specId ?? ''}_${type ?? ''}';
    
    return await _executeWithLimit(
      _getRequestKey('homeworks', params),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final uri = Uri.parse('$_baseUrl/homework/operations/list');
          final queryParams = <String, String>{};
          
          if (type != null) queryParams['type'] = type.toString();
          if (page != null) queryParams['page'] = page.toString();
          if (status != null) queryParams['status'] = status.toString();
          if (groupId != null) queryParams['group_id'] = groupId.toString();
          if (specId != null) queryParams['spec_id'] = specId.toString();
          
          queryParams['limit'] = '6';
          if (page != null) {
            queryParams['offset'] = ((page - 1) * 6).toString();
          }

          final url = uri.replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
          
          final response = await _makeRequest(url.toString());
          
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            List<dynamic> homeworkData = [];
            
            if (responseData is List) {
              homeworkData = responseData;
            } else if (responseData['data'] is List) {
              homeworkData = responseData['data'];
            } else if (responseData['homeworks'] is List) {
              homeworkData = responseData['homeworks'];
            } else if (responseData['items'] is List) {
              homeworkData = responseData['items'];
            } else if (responseData['models_list'] is List) {
              homeworkData = responseData['models_list'];
            }
            
            final homeworks = homeworkData.map((json) => Homework.fromJson(json)).toList();
            
            // Сохраняем в SQLite
            await _databaseFacade.saveHomeworks(homeworks, accountId, materialType: type);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.homeworks,
              homeworks,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlShort),
            );
            
            print('✅ ${type == 1 ? 'Лабораторные' : 'Домашние'} задания загружены и сохранены в SQLite: ${homeworks.length} шт');
            
            return homeworks;
          } else {
            print("Failed to load homeworks: ${response.statusCode}");
            
            // Пробуем из SQLite с фильтрацией
            final offlineHomeworks = await _databaseFacade.getHomeworks(
              accountId,
              materialType: type,
              status: status,
              page: page,
              limit: 6,
            );
            
            if (offlineHomeworks.isNotEmpty) {
              print('📱 Используем ${type == 1 ? 'лабораторные' : 'домашние'} задания из SQLite: ${offlineHomeworks.length} шт');
              return offlineHomeworks;
            }
            
            throw Exception('Failed to load homeworks: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки домашних заданий: $e');
          
          // Пробуем из кэша
          final cachedHomeworks = await _cacheRepository.get<List<Homework>>(
            CacheKeys.homeworks,
            accountId: accountId,
          );
          
          if (cachedHomeworks != null && cachedHomeworks.isNotEmpty) {
            print('💾 Используем домашние задания из кэша: ${cachedHomeworks.length} шт');
            
            // Применяем фильтрацию к кэшированным данным
            List<Homework> filtered = cachedHomeworks;
            if (type != null) {
              filtered = filtered.where((hw) => hw.materialType == type).toList();
            }
            if (status != null) {
              filtered = filtered.where((hw) => hw.getDisplayStatus() == status).toList();
            }
            
            return filtered;
          }
          
          // Пробуем из SQLite
          final offlineHomeworks = await _databaseFacade.getHomeworks(
            accountId,
            materialType: type,
            status: status,
            page: page,
            limit: 6,
          );
          
          if (offlineHomeworks.isNotEmpty) {
            print('🗄️ Используем домашние задания из SQLite: ${offlineHomeworks.length} шт');
            return offlineHomeworks;
          }
          
          rethrow;
        }
      },
    );
  }

  /// Получение счетчиков ДЗ с сохранением в SQLite
  Future<List<HomeworkCounter>> getHomeworkCounters(
    String token, {
    int? type,
    int? groupId,
    int? specId,
  }) async {
    final params = '${type ?? ''}_${groupId ?? ''}_${specId ?? ''}';
    
    return await _executeWithLimit(
      _getRequestKey('homework_counters', params),
      () async {
        final accountId = await _getCurrentAccountId();
        
        try {
          final uri = Uri.parse('$_baseUrl/count/homework');
          final queryParams = <String, String>{};
          
          if (type != null) queryParams['type'] = type.toString();
          if (groupId != null) queryParams['group_id'] = groupId.toString();
          if (specId != null) queryParams['spec_id'] = specId.toString();
          
          final url = uri.replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
          
          final response = await _makeRequest(url.toString());
          
          if (response.statusCode == 200) {
            final List<dynamic> counterData = jsonDecode(response.body);
            final counters = counterData.map((json) => HomeworkCounter.fromJson(json)).toList();
            
            // Сохраняем в SQLite
            await _databaseFacade.saveHomeworkCounters(counters, accountId, type: type);
            
            // Кэшируем
            await _cacheRepository.save(
              CacheKeys.homeworkCounters,
              counters,
              accountId: accountId,
              expiry: Duration(seconds: _cacheTtlShort),
            );
            
            print('✅ Счетчики ${type == 1 ? 'лабораторных' : 'домашних'} заданий загружены и сохранены в SQLite: ${counters.length} шт');
            
            return counters;
          } else {
            print("Failed to load homework counters: ${response.statusCode}");
            
            // Пробуем из SQLite
            final offlineCounters = await _databaseFacade.getHomeworkCounters(accountId, type: type);
            if (offlineCounters.isNotEmpty) {
              print('📱 Используем счетчики из SQLite: ${offlineCounters.length} шт');
              return offlineCounters;
            }
            
            throw Exception('Failed to load homework counters: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки счетчиков ДЗ: $e');
          
          // Пробуем из кэша
          final cachedCounters = await _cacheRepository.get<List<HomeworkCounter>>(
            CacheKeys.homeworkCounters,
            accountId: accountId,
          );
          
          if (cachedCounters != null && cachedCounters.isNotEmpty) {
            print('💾 Используем счетчики из кэша: ${cachedCounters.length} шт');
            return cachedCounters;
          }
          
          // Пробуем из SQLite
          final offlineCounters = await _databaseFacade.getHomeworkCounters(accountId, type: type);
          if (offlineCounters.isNotEmpty) {
            print('🗄️ Используем счетчики из SQLite: ${offlineCounters.length} шт');
            return offlineCounters;
          }
          
          rethrow;
        }
      },
    );
  }

  /// ==================== SYNC METHODS ====================

  Future<void> syncCriticalDataOnly(String token) async {
    if (_isDisposed) return;
    
    print('🔄 Синхронизация критических данных...');
    
    try {
      final accountId = await _getCurrentAccountId();
      
      await Future.wait([
        getUser(token).then((user) async {
          await _databaseFacade.saveUserData(user, accountId);
        }),
        getMarks(token).then((marks) async {
          await _databaseFacade.saveMarks(marks, accountId);
        }),
      ], eagerError: false);
      
      print('✅ Критические данные синхронизированы в SQLite');
    } catch (e) {
      print('⚠️ Ошибка синхронизации критических данных: $e');
    }
  }

  Future<void> syncAllData(String token) async {
    if (_isDisposed) return;
    
    print('🔄 Полная синхронизация всех данных в SQLite...');
    
    try {
      final accountId = await _getCurrentAccountId();
      
      //(критические -> второстепенные)
      
      // Критические данные
      await Future.wait([
        getUser(token).then((user) async {
          await _databaseFacade.saveUserData(user, accountId);
          print('✅ Пользователь синхронизирован');
        }),
        getMarks(token).then((marks) async {
          await _databaseFacade.saveMarks(marks, accountId);
          print('✅ Оценки синхронизированы: ${marks.length} шт');
        }),
      ], eagerError: true);
      
      await Future.delayed(Duration(milliseconds: 100));
      
      final now = DateTime.now();
      final monday = getMonday(now);
      final sunday = getSunday(now);
      
      await getSchedule(token, formatDate(monday), formatDate(sunday)).then((schedule) async {
        await _databaseFacade.saveSchedule(schedule, accountId);
        print('✅ Расписание синхронизировано: ${schedule.length} шт');
      });
      
      await Future.delayed(Duration(milliseconds: 100));
      
      // остальные параллельно
      await Future.wait([
        getGroupLeaders(token).then((leaders) async {
          await _databaseFacade.saveGroupLeaders(leaders, accountId);
          print('✅ Лидеры группы синхронизированы: ${leaders.length} шт');
        }),
        getStreamLeaders(token).then((leaders) async {
          await _databaseFacade.saveStreamLeaders(leaders, accountId);
          print('✅ Лидеры потока синхронизированы: ${leaders.length} шт');
        }),
        
        getExams(token).then((exams) async {
          await _databaseFacade.saveExams(exams, accountId);
          print('✅ Экзамены синхронизированы: ${exams.length} шт');
        }),
        
        getHomeworks(token, type: 0).then((homeworks) async {
          await _databaseFacade.saveHomeworks(homeworks, accountId, materialType: 0);
          print('✅ Домашние задания синхронизированы: ${homeworks.length} шт');
        }),
        
        getHomeworks(token, type: 1).then((homeworks) async {
          await _databaseFacade.saveHomeworks(homeworks, accountId, materialType: 1);
          print('✅ Лабораторные работы синхронизированы: ${homeworks.length} шт');
        }),
        
        getHomeworkCounters(token, type: 0).then((counters) async {
          await _databaseFacade.saveHomeworkCounters(counters, accountId, type: 0);
          print('✅ Счетчики ДЗ синхронизированы: ${counters.length} шт');
        }),
        
        getProgressActivity(token).then((activities) async {
          await _databaseFacade.saveActivities(activities, accountId, strategy: SyncStrategy.append);
          print('✅ Активности синхронизированы: ${activities.length} шт');
        }),
        
        getFeedbackReview(token).then((feedbacks) async {
          await _databaseFacade.saveFeedbacks(feedbacks, accountId);
          print('✅ Отзывы синхронизированы: ${feedbacks.length} шт');
        }),
      ], eagerError: false); // false - чтобы ошибка в одном не останавливала остальные
      
      print('✅ ВСЕ данные синхронизированы в SQLite');
      
    } catch (e) {
      print('❌ Ошибка полной синхронизации: $e');
    }
  }

  /// ==================== UTILITY METHODS ====================

  Future<bool> validateToken(String token) async {
    return await _executeWithLimit(
      _getRequestKey('validate_token'),
      () async {
        try {
          final response = await _makeRequest('$_baseUrl/settings/user-info');
          return response.statusCode == 200;
        } catch (e) {
          return false;
        }
      },
    );
  }

  /// ==================== DISPOSE ====================

  void dispose() {
    _isDisposed = true;
    _pendingRequests.forEach((key, completer) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Service disposed'));
      }
    });
    _pendingRequests.clear();
    _memoryCache.clear();
    print('🔴 ApiService disposed');
  }
/// загрузка файла задания [api]
Future<File?> downloadHomeworkFile(String token, Homework homework) async {
  try {
    if (homework.downloadUrl == null || homework.downloadUrl!.isEmpty) {
      throw Exception('URL файла недоступен');
    }

    final String fileName = homework.safeFilename ?? 
        'homework_${homework.id}_${DateTime.now().millisecondsSinceEpoch}';

    print('Downloading homework file: $fileName');

    final file = await DownloadService.downloadFile(
      url: homework.downloadUrl!,
      fileName: fileName,
      token: token,
      onProgress: (received, total) {
        if (total != -1) {
          double progress = (received / total * 100);
          print('Download progress: ${progress.toStringAsFixed(2)}%'); // TODO: допилить прогресс в UX - Ди.
          print('Download progress: ${progress.toStringAsFixed(2)}%');
        }
      },
    );

    return file;
  } catch (e) {
    print('Ошибка при скачивании файла задания: $e');
    rethrow;
  }
}

/// загрузка файла сданного задания студента [api]
Future<File?> downloadStudentHomeworkFile(String token, Homework homework) async {
  try {
    if (homework.studentDownloadUrl == null || homework.studentDownloadUrl!.isEmpty) {
      throw Exception('URL файла студенческой работы недоступен');
    }

    final String fileName = homework.safeStudentFilename ?? 
        'student_homework_${homework.id}_${DateTime.now().millisecondsSinceEpoch}';

    print('Downloading student homework file: $fileName');

    final file = await DownloadService.downloadFile(
      url: homework.studentDownloadUrl!,
      fileName: fileName,
      token: token,
      onProgress: (received, total) {
        if (total != -1) {
          double progress = (received / total * 100);
          print('Download progress: ${progress.toStringAsFixed(2)}%');
        }
      },
    );

    return file;
  } catch (e) {
    print('Ошибка при скачивании файла студенческой работы: $e');
    rethrow;
  }
}
}

// Вспомогательные функции (оставить как есть)
DateTime getMonday(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final day = d.weekday;
  final diff = day - 1; 
  return d.subtract(Duration(days: diff));
}

DateTime getSunday(DateTime date) {
  final d = getMonday(date);
  return d.add(const Duration(days: 6));
}

String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}