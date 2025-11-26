import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'secure_storage_service.dart';
import 'offline_storage_service.dart';
import 'download_service.dart';

import '../models/mark.dart';
import '../models/user_data.dart';
import '../models/days_element.dart';
import '../models/leaderboard_user.dart';
import '../models/leader_position_model.dart';
import '../models/feedback_review.dart';
import '../models/exam.dart';
import '../models/activity_record.dart';
import '../models/homework.dart';
import '../models/homework_counter.dart';

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

/// не трогать КОД - НИКОМУ кроме КЕЙСИ (Дианы) !!! НИЗАЧТО (сломаю пальцы и в жопу засуну). 
/// Исключение, если КЕЙСИ попросит помочь с доработкой этого кода и ВЫ точно знаете что делаете. 
/// Подумайте дважды прежде чем что-то менять здесь. Иначе - ломайте себе пальцы по одному.
class ApiService {
  final String _baseUrl = "https://msapi.top-academy.ru/api/v2"; 
  final SecureStorageService _secureStorage = SecureStorageService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  
  static int _activeRequests = 0;
  static const int _maxConcurrentRequests = 3;
  static const Duration _timeOut = Duration(seconds: 15);
  static const Duration _shortTimeOut = Duration(seconds: 10);
  
  bool _isDisposed = false;
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  final Map<String, dynamic> _memoryCache = {};

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

  Future<String?> _reauthenticate() async {
    final credentials = await _secureStorage.getCredentials();
    final username = credentials['username'];
    final password = credentials['password'];

    if (username == null || password == null) {
      return null; 
    }

    final newToken = await login(username, password); 
    
    if (newToken != null) {
      await _secureStorage.saveToken(newToken);
    }
    return newToken;
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
          
          await _secureStorage.saveToken(token);
          await _secureStorage.saveCredentials(username, password);
          
          return token; 
        } else {
          print("Login failed: ${response.statusCode}");
          return null;
        }
      },
    );
  }

  /// получение оценок студента [api] - с автоматическим оффлайн сохранением
  Future<List<Mark>> getMarks(String token) async {
    return await _executeWithLimit(
      _getRequestKey('marks'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/progress/operations/student-visits'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru', 
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) { 
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/progress/operations/student-visits'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }
          
          if (response.statusCode == 200) {
            final List<dynamic> marksData = jsonDecode(response.body);
            final marks = marksData.map((json) => Mark.fromJson(json)).toList();
            
            // Автоматически сохраняем в оффлайн хранилище
            await _offlineStorage.saveMarks(marks);
            print('✅ Оценки загружены и сохранены оффлайн: ${marks.length} шт');
            
            return marks;
          } else {
            print("Failed to load marks: ${response.statusCode}");
            throw Exception('Failed to load marks');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки оценок онлайн, пробуем оффлайн: $e');
          final offlineMarks = await _offlineStorage.getMarks();
          if (offlineMarks.isNotEmpty) {
            print('📱 Используем оффлайн оценки: ${offlineMarks.length} шт');
            return offlineMarks;
          }
          rethrow;
        }
      },
    );
  }
  
  /// получение данных пользователя [api] - с автоматическим оффлайн сохранением
  Future<UserData> getUser(String token) async {
    return await _executeWithLimit(
      _getRequestKey('user'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/settings/user-info'), 
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru', 
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/settings/user-info'), 
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru', 
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final user = UserData.fromJson(data);
            
            await _offlineStorage.saveUserData(user);
            print('✅ Данные пользователя загружены и сохранены оффлайн');
            
            return user;
          } else {
            print("Failed to load user data: ${response.statusCode}");
            throw Exception('Failed to load user data');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки пользователя онлайн, пробуем оффлайн: $e');
          final offlineUser = await _offlineStorage.getUserData();
          if (offlineUser != null) {
            print('📱 Используем оффлайн данные пользователя');
            return offlineUser;
          }
          rethrow;
        }
      },
    );
  }

  /// получение расписания за указанный период [api] - с автоматическим оффлайн сохранением
  Future<List<ScheduleElement>> getSchedule(String token, String dateFrom, String dateTo) async { 
    return await _executeWithLimit(
      _getRequestKey('schedule', '$dateFrom-$dateTo'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/schedule/operations/get-by-date-range?date_start=$dateFrom&date_end=$dateTo'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/schedule/operations/get-by-date-range?date_start=$dateFrom&date_end=$dateTo'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            final List<dynamic> scheduleData = jsonDecode(response.body); 
            final schedule = scheduleData
                .map((json) => ScheduleElement.fromJson(json as Map<String, dynamic>))
                .toList();
            
            await _offlineStorage.saveSchedule(schedule);
            print('✅ Расписание загружено и сохранено оффлайн: ${schedule.length} шт');
            
            return schedule;
          } else {
            print("Failed to load schedule: ${response.statusCode}");
            throw Exception('Failed to load schedule');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки расписания онлайн, пробуем оффлайн: $e');
          final offlineSchedule = await _offlineStorage.getSchedule();
          if (offlineSchedule.isNotEmpty) {
            print('📱 Используем оффлайн расписание: ${offlineSchedule.length} шт');
            return offlineSchedule;
          }
          rethrow;
        }
      },
    );
  }

  /// получение лидеров группы [api] - с автоматическим оффлайн сохранением
  Future<List<LeaderboardUser>> getGroupLeaders(String token) async {
    return await _executeWithLimit(
      _getRequestKey('group_leaders'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/dashboard/progress/leader-group'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/dashboard/progress/leader-group'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            try {
              final List<dynamic> leadersData = jsonDecode(response.body);
              final leaders = leadersData.map((json) => LeaderboardUser.fromJson(json)).toList();
              
              await _offlineStorage.saveGroupLeaders(leaders);
              print('✅ Лидеры группы загружены и сохранены оффлайн: ${leaders.length} шт');
              
              return leaders;
            } catch (e) {
              print("Error parsing group leaders: $e");
              try {
                final groupModel = GroupPositionModel.fromJson(jsonDecode(response.body));
                final leaders = groupModel.groupLeaders;
                
                await _offlineStorage.saveGroupLeaders(leaders);
                print('✅ Лидеры группы загружены (альтернативный парсинг) и сохранены оффлайн: ${leaders.length} шт');
                
                return leaders;
              } catch (e2) {
                print("Alternative parsing also failed: $e2");
                throw Exception('Failed to parse group leaders data');
              }
            }
          } else {
            print("Failed to load group leaders: ${response.statusCode}");
            throw Exception('Failed to load group leaders: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки лидеров группы онлайн, пробуем оффлайн: $e');
          final offlineLeaders = await _offlineStorage.getGroupLeaders();
          if (offlineLeaders.isNotEmpty) {
            print('📱 Используем оффлайн лидеров группы: ${offlineLeaders.length} шт');
            return offlineLeaders;
          }
          rethrow;
        }
      },
    );
  }

  /// получение лидеров потока [api] - с автоматическим оффлайн сохранением
  Future<List<LeaderboardUser>> getStreamLeaders(String token) async {
    return await _executeWithLimit(
      _getRequestKey('stream_leaders'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/dashboard/progress/leader-stream'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/dashboard/progress/leader-stream'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            try {
              final List<dynamic> leadersData = jsonDecode(response.body);
              final leaders = leadersData.map((json) => LeaderboardUser.fromJson(json)).toList();
              
              await _offlineStorage.saveStreamLeaders(leaders);
              print('✅ Лидеры потока загружены и сохранены оффлайн: ${leaders.length} шт');
              
              return leaders;
            } catch (e) {
              print("Error parsing stream leaders: $e");
              try {
                final streamModel = StreamPositionModel.fromJson(jsonDecode(response.body));
                final leaders = streamModel.streamLeaders;
                
                await _offlineStorage.saveStreamLeaders(leaders);
                print('✅ Лидеры потока загружены (альтернативный парсинг) и сохранены оффлайн: ${leaders.length} шт');
                
                return leaders;
              } catch (e2) {
                print("Alternative parsing also failed: $e2");
                throw Exception('Failed to parse stream leaders data');
              }
            }
          } else {
            print("Failed to load stream leaders: ${response.statusCode}");
            throw Exception('Failed to load stream leaders: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки лидеров потока онлайн, пробуем оффлайн: $e');
          final offlineLeaders = await _offlineStorage.getStreamLeaders();
          if (offlineLeaders.isNotEmpty) {
            print('📱 Используем оффлайн лидеров потока: ${offlineLeaders.length} шт');
            return offlineLeaders;
          }
          rethrow;
        }
      },
    );
  }

  /// получение отзывов о студенте [api] - с автоматическим оффлайн сохранением
  Future<List<FeedbackReview>> getFeedbackReview(String token) async {
    return await _executeWithLimit(
      _getRequestKey('feedback'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/reviews/index/list'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/reviews/index/list'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            try {
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
              
              await _offlineStorage.saveFeedbackReviews(feedbacks);
              print('✅ Отзывы загружены и сохранены оффлайн: ${feedbacks.length} шт');
              
              return feedbacks;
            } catch (e) {
              print("Error parsing feedback: $e");
              throw Exception('Failed to parse feedback data: $e');
            }
          } else {
            print("Failed to load feedback: ${response.statusCode}");
            throw Exception('Failed to load feedback: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки отзывов онлайн, пробуем оффлайн: $e');
          final offlineFeedbacks = await _offlineStorage.getFeedbackReviews();
          if (offlineFeedbacks.isNotEmpty) {
            print('📱 Используем оффлайн отзывы: ${offlineFeedbacks.length} шт');
            return offlineFeedbacks;
          }
          rethrow;
        }
      },
    );
  }

  /// получение экзаменов студента [api] - с автоматическим оффлайн сохранением
  Future<List<Exam>> getExams(String token) async {
    return await _executeWithLimit(
      _getRequestKey('exams'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/progress/operations/student-exams'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/progress/operations/student-exams'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            try {
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
              
              await _offlineStorage.saveExams(exams);
              print('✅ Экзамены загружены и сохранены оффлайн: ${exams.length} шт');
              
              return exams;
            } catch (e) {
              print("Error parsing exams: $e");
              throw Exception('Failed to parse exams data: $e');
            }
          } else {
            print("Failed to load exams: ${response.statusCode}");
            throw Exception('Failed to load exams: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки экзаменов онлайн, пробуем оффлайн: $e');
          final offlineExams = await _offlineStorage.getExams();
          if (offlineExams.isNotEmpty) {
            print('📱 Используем оффлайн экзамены: ${offlineExams.length} шт');
            return offlineExams;
          }
          rethrow;
        }
      },
    );
  }

  /// получение предстоящих экзаменов [api] - с автоматическим оффлайн сохранением
  Future<List<Exam>> getFutureExams(String token) async {
    return await _executeWithLimit(
      _getRequestKey('future_exams'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/dashboard/info/future-exams'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/dashboard/info/future-exams'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            try {
              final List<dynamic> futureExamsData = jsonDecode(response.body);
              final exams = futureExamsData.map((json) => Exam.fromJson(json)).toList();
              
              await _offlineStorage.saveExams(exams);
              print('✅ Предстоящие экзамены загружены и сохранены оффлайн: ${exams.length} шт');
              
              return exams;
            } catch (e) {
              print("Error parsing future exams: $e");
              throw Exception('Failed to parse future exams data: $e');
            }
          } else {
            print("Failed to load future exams: ${response.statusCode}");
            throw Exception('Failed to load future exams: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки предстоящих экзаменов онлайн, пробуем оффлайн: $e');
          final offlineExams = await _offlineStorage.getExams();
          if (offlineExams.isNotEmpty) {
            print('📱 Используем оффлайн экзамены: ${offlineExams.length} шт');
            return offlineExams;
          }
          rethrow;
        }
      },
    );
  }

  Future<bool> validateToken(String token) async {
    return await _executeWithLimit(
      _getRequestKey('validate_token'),
      () async {
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl/settings/user-info'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_shortTimeOut);
          
          return response.statusCode == 200;
        } catch (e) {
          return false;
        }
      },
    );
  }

  /// получение истории активности и наград студента [api] - с автоматическим оффлайн сохранением
  Future<List<ActivityRecord>> getProgressActivity(String token) async {
    return await _executeWithLimit(
      _getRequestKey('activity'),
      () async {
        try {
          var response = await http.get(
            Uri.parse('$_baseUrl/dashboard/progress/activity'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/dashboard/progress/activity'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            try {
              final List<dynamic> activityData = jsonDecode(response.body);
              final activities = activityData.map((json) => ActivityRecord.fromJson(json)).toList();
              
              await _offlineStorage.saveActivityRecords(activities);
              print('✅ Активности загружены и сохранены оффлайн: ${activities.length} шт');
              
              return activities;
            } catch (e) {
              print("Error parsing activity data: $e");
              throw Exception('Failed to parse activity data: $e');
            }
          } else {
            print("Failed to load activity data: ${response.statusCode}");
            throw Exception('Failed to load activity data: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки активностей онлайн, пробуем оффлайн: $e');
          final offlineActivities = await _offlineStorage.getActivityRecords();
          if (offlineActivities.isNotEmpty) {
            print('📱 Используем оффлайн активности: ${offlineActivities.length} шт');
            return offlineActivities;
          }
          rethrow;
        }
      },
    );
  }

  /// получение списка домашних заданий [api] - с автоматическим оффлайн сохранением
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
          
          var response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            try {
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
              
              await _offlineStorage.saveHomeworks(homeworks);
              print('✅ Домашние задания загружены и сохранены оффлайн: ${homeworks.length} шт');
              
              return homeworks;
            } catch (e) {
              print("Error parsing homeworks: $e");
              throw Exception('Failed to parse homeworks data: $e');
            }
          } else {
            print("Failed to load homeworks: ${response.statusCode}");
            throw Exception('Failed to load homeworks: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки домашних заданий онлайн, пробуем оффлайн: $e');
          final offlineHomeworks = await _offlineStorage.getHomeworks();
          if (offlineHomeworks.isNotEmpty) {
            print('📱 Используем оффлайн домашние задания: ${offlineHomeworks.length} шт');
            return offlineHomeworks;
          }
          rethrow;
        }
      },
    );
  }

  /// получение счетчиков домашних заданий [api] - с автоматическим оффлайн сохранением
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
        try {
          final uri = Uri.parse('$_baseUrl/count/homework');
          final queryParams = <String, String>{};
          
          if (type != null) queryParams['type'] = type.toString();
          if (groupId != null) queryParams['group_id'] = groupId.toString();
          if (specId != null) queryParams['spec_id'] = specId.toString();
          
          final url = uri.replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
          
          var response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Referer': 'https://journal.top-academy.ru',
            },
          ).timeout(_timeOut);

          if (response.statusCode == 401) {
            final newToken = await _reauthenticate();
            if (newToken != null) {
              response = await http.get(
                Uri.parse('$_baseUrl/count/homework'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                  'Referer': 'https://journal.top-academy.ru',
                },
              ).timeout(_timeOut);
            }
          }

          if (response.statusCode == 200) {
            try {
              final List<dynamic> counterData = jsonDecode(response.body);
              final counters = counterData.map((json) => HomeworkCounter.fromJson(json)).toList();
              
              await _offlineStorage.saveHomeworkCounters(counters);
              print('✅ Счетчики ДЗ загружены и сохранены оффлайн: ${counters.length} шт');
              
              return counters;
            } catch (e) {
              print("Error parsing homework counters: $e");
              throw Exception('Failed to parse homework counters: $e');
            }
          } else {
            print("Failed to load homework counters: ${response.statusCode}");
            throw Exception('Failed to load homework counters: ${response.statusCode}');
          }
        } catch (e) {
          print('🌐 Ошибка загрузки счетчиков ДЗ онлайн, пробуем оффлайн: $e');
          final offlineCounters = await _offlineStorage.getHomeworkCounters();
          if (offlineCounters.isNotEmpty) {
            print('📱 Используем оффлайн счетчики ДЗ: ${offlineCounters.length} шт');
            return offlineCounters;
          }
          rethrow;
        }
      },
    );
  }

  /// удаление домашнего задания [api] // TODO: Допилить - Ди (Будущий func)
Future<bool> deleteHomework(String token, int homeworkId) async {
  var response = await http.post(
    Uri.parse('$_baseUrl/homework/operations/delete'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
    body: jsonEncode({'id': homeworkId}),
  );

  if (response.statusCode == 401) {
    final newToken = await _reauthenticate();
    if (newToken != null) {
      response = await http.post(
        Uri.parse('$_baseUrl/homework/operations/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken',
          'Referer': 'https://journal.top-academy.ru',
        },
        body: jsonEncode({'id': homeworkId}),
      );
    }
  }

  return response.statusCode == 200;
}

/// загрузка файла задания [api]
Future<File?> downloadHomeworkFile(String token, Homework homework) async {
  try {
    if (homework.downloadUrl == null || homework.downloadUrl!.isEmpty) {
      throw Exception('URL файла недоступен');
    }

    final String fileName = homework.filename ?? 
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

    final String fileName = homework.studentFilename ?? 
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

  /// Упрощенная синхронизация только критических данных
  Future<void> syncCriticalDataOnly(String token) async {
    if (_isDisposed) return;
    
    print('🔄 Синхронизация критических данных...');
    
    try {
      await Future.wait([
        _syncUserData(token),
        _syncMarks(token),
      ], eagerError: false);
      
      print('✅ Критические данные синхронизированы');
    } catch (e) {
      print('⚠️ Ошибка синхронизации критических данных: $e');
    }
  }

  /// Полная синхронизация (только при ручном вызове)
  Future<void> syncAllData(String token) async {
    if (_isDisposed) return;
    
    print('🔄 Полная синхронизация данных...');
    
    try {
      // Критические данные
      await syncCriticalDataOnly(token);
      await Future.delayed(Duration(milliseconds: 200));
      
      // Второстепенные данные
      await _syncSchedule(token);
      await Future.delayed(Duration(milliseconds: 200));
      
      await _syncAdditionalData(token);
      
      print('✅ Все данные синхронизированы');
    } catch (e) {
      print('❌ Ошибка полной синхронизации: $e');
    }
  }

  Future<void> _syncUserData(String token) async {
    try {
      final user = await getUser(token);
      await _offlineStorage.saveUserData(user);
    } catch (e) {
      print('⚠️ Ошибка синхронизации пользователя: $e');
    }
  }

  Future<void> _syncMarks(String token) async {
    try {
      final marks = await getMarks(token);
      await _offlineStorage.saveMarks(marks);
    } catch (e) {
      print('⚠️ Ошибка синхронизации оценок: $e');
    }
  }

  Future<void> _syncSchedule(String token) async {
    try {
      final now = DateTime.now();
      final monday = getMonday(now);
      final sunday = getSunday(now);
      final schedule = await getSchedule(token, formatDate(monday), formatDate(sunday));
      await _offlineStorage.saveSchedule(schedule);
    } catch (e) {
      print('⚠️ Ошибка синхронизации расписания: $e');
    }
  }

  Future<void> _syncAdditionalData(String token) async {
    try {
      await Future.wait([
        getExams(token).then(_offlineStorage.saveExams).catchError((e) => print('⚠️ Экзамены: $e')),
        getHomeworks(token, type: 0).then(_offlineStorage.saveHomeworks).catchError((e) => print('⚠️ ДЗ: $e')),
        getGroupLeaders(token).then(_offlineStorage.saveGroupLeaders).catchError((e) => print('⚠️ Лидеры группы: $e')),
      ], eagerError: false);
    } catch (e) {
      print('⚠️ Ошибка синхронизации дополнительных данных: $e');
    }
  }

  /// Метод для быстрой загрузки критических данных с приоритетом оффлайн
  Future<Map<String, dynamic>> loadCriticalData(String token) async {
    try {
      print('🚀 Быстрая загрузка критических данных...');
      
      final results = await Future.wait([
        getUser(token),
        getMarks(token),
      ], eagerError: false);
      
      return {
        'user': results[0] as UserData,
        'marks': results[1] as List<Mark>,
      };
    } catch (e) {
      print('❌ Ошибка загрузки критических данных: $e');
      rethrow;
    }
  }

// Для тестов. Запросы чисто для проверок РАЗРАБОТЧИКАМ
/// замена токена на некорректный для тестирования обработки ошибки [api]
Future<void> simulateTokenError() async {
  final secureStorage = SecureStorageService();
  await secureStorage.saveToken('invalid_token_12345');
  print('Искусственная ошибка токена активирована!');
}

/// очищение токена для тестирования обработки ошибки [api]
Future<void> clearTokenForTesting() async {
  final secureStorage = SecureStorageService();
  await secureStorage.clearAll();
  print('Все данные очищены для тестирования!');
}

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
}