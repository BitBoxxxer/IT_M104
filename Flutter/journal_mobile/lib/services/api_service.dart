import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../services/secure_storage_service.dart';
import '../services/download_service.dart';

import '../models/mark.dart';
import '../models/user_data.dart';
import '../models/days_element.dart';
import '../models/leaderboard_user.dart';
import '../models/leader_position_model.dart';
import  '../models/feedback_review.dart';
import '../models/exam.dart';
import '../models/activity_record.dart';
import '../models/homework.dart';
import '../models/homework_counter.dart';

/// не трогать КОД - НИКОМУ кроме КЕЙСИ (Дианы) !!! НИЗАЧТО (сломаю пальцы и в жопу засуну). 
/// Исключение, если КЕЙСИ попросит помочь с доработкой этого кода и ВЫ точно знаете что делаете. 
/// Подумайте дважды прежде чем что-то менять здесь. Иначе - ломайте себе пальцы по одному.
class ApiService {
  final String _baseUrl = "https://msapi.top-academy.ru/api/v2"; 
  final SecureStorageService _secureStorage = SecureStorageService();

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
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Referer': 'https://journal.top-academy.ru', 
      },
      body: jsonEncode({
        'username': username, 
        'password': password,
        'application_key': 
          '6a56a5df2667e65aab73ce76d1dd737f7d1faef9c52e8b8c55ac75f565d8e8a6',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      
      await _secureStorage.saveToken(token);
      await _secureStorage.saveCredentials(username, password);
      
      return token; 
    } else {
      print("Login failed: ${response.statusCode}");
      print("Response body: ${response.body}"); 
      return null;
    }
  }

  /// получение оценок студента [api]
  Future<List<Mark>> getMarks(String token) async {
    var response = await http.get(
      Uri.parse('$_baseUrl/progress/operations/student-visits'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Referer': 'https://journal.top-academy.ru', 
      },
    );

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
        );
      }
    }
    if (response.statusCode == 200) {
      final List<dynamic> marksData = jsonDecode(response.body);
      return marksData.map((json) => Mark.fromJson(json)).toList();
    } else {
      print("Failed to load marks: ${response.statusCode}");
      throw Exception('Failed to load marks');
    }
  }
  
    Future<UserData> getUser(String token) async {
    var response = await http.get(
      Uri.parse('$_baseUrl/settings/user-info'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Referer': 'https://journal.top-academy.ru', 
      },
    );

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
        );
      }
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserData.fromJson(data);
    } else {
      print("Failed to load user data: ${response.statusCode}");
      throw Exception('Failed to load user data');
    }
  }

  /// получение расписания за указанный период [api]
  /// Универсально принимает значения даты от и до
  Future <List<ScheduleElement>> getSchedule(String token, String dateFrom, String dateTo) async { 
    final String _baseUrl = "https://msapi.top-academy.ru/api/v2";
    
    var response = await http.get(
      Uri.parse('$_baseUrl/schedule/operations/get-by-date-range?date_start=$dateFrom&date_end=$dateTo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Referer': 'https://journal.top-academy.ru',
      },
    );

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
        );
      }
    }

    if (response.statusCode == 200) {
      final List<dynamic> scheduleData = jsonDecode(response.body); 
      
      return scheduleData
          .map((json) => ScheduleElement.fromJson(json as Map<String, dynamic>))
          .toList();
          
    } else {
      print("Failed to load schedule: ${response.statusCode}");
      print("Response body: ${response.body}");
      throw Exception('Failed to load schedule');
    }
  }

  /// получение лидеров группы [api]
  Future<List<LeaderboardUser>> getGroupLeaders(String token) async {
  var response = await http.get(
    Uri.parse('$_baseUrl/dashboard/progress/leader-group'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
  );

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
      );
    }
  }

  if (response.statusCode == 200) {
    try {
      final List<dynamic> leadersData = jsonDecode(response.body);
      return leadersData.map((json) => LeaderboardUser.fromJson(json)).toList();
    } catch (e) {
      print("Error parsing group leaders: $e");
      try {
        final groupModel = GroupPositionModel.fromJson(jsonDecode(response.body));
        return groupModel.groupLeaders;
      } catch (e2) {
        print("Alternative parsing also failed: $e2");
        throw Exception('Failed to parse group leaders data');
      }
    }
  } else {
    print("Failed to load group leaders: ${response.statusCode}");
    print("Response body: ${response.body}");
    throw Exception('Failed to load group leaders: ${response.statusCode}');
  }
}

/// получение лидеров потока [api]
Future<List<LeaderboardUser>> getStreamLeaders(String token) async {
  var response = await http.get(
    Uri.parse('$_baseUrl/dashboard/progress/leader-stream'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
  );

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
      );
    }
  }

  if (response.statusCode == 200) {
    try {
      final List<dynamic> leadersData = jsonDecode(response.body);
      return leadersData.map((json) => LeaderboardUser.fromJson(json)).toList();
    } catch (e) {
      print("Error parsing stream leaders: $e");
      try {
        final streamModel = StreamPositionModel.fromJson(jsonDecode(response.body));
        return streamModel.streamLeaders;
      } catch (e2) {
        print("Alternative parsing also failed: $e2");
        throw Exception('Failed to parse stream leaders data');
      }
    }
  } else {
    print("Failed to load stream leaders: ${response.statusCode}");
    print("Response body: ${response.body}");
    throw Exception('Failed to load stream leaders: ${response.statusCode}');
  }
}

/// получение отзывов о студенте [api]
Future<List<FeedbackReview>> getFeedbackReview(String token) async {
  var response = await http.get(
    Uri.parse('$_baseUrl/reviews/index/list'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
  );

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
      );
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
      
      print("Parsed feedback data: $feedbackData");
      
      return feedbackData.map((json) => FeedbackReview.fromJson(json)).toList();
    } catch (e) {
      print("Error parsing feedback: $e");
      throw Exception('Failed to parse feedback data: $e');
    }
  } else {
    print("Failed to load feedback: ${response.statusCode}");
    print("Response body: ${response.body}");
    throw Exception('Failed to load feedback: ${response.statusCode}');
  }
}

/// получение экзаменов студента [api]
Future<List<Exam>> getExams(String token) async {
  var response = await http.get(
    Uri.parse('$_baseUrl/progress/operations/student-exams'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
  );

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
      );
    }
  }

  if (response.statusCode == 200) {
    try {
      final responseData = jsonDecode(response.body);
      List<dynamic> examsData = [];
      
      // Обработка разных форматов ответа API
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
      
      print("Parsed exams data: ${examsData.length} items");
      
      return examsData.map((json) => Exam.fromJson(json)).toList();
    } catch (e) {
      print("Error parsing exams: $e");
      throw Exception('Failed to parse exams data: $e');
    }
  } else {
    print("Failed to load exams: ${response.statusCode}");
    print("Response body: ${response.body}");
    throw Exception('Failed to load exams: ${response.statusCode}');
  }
}

/// получение предстоящих экзаменов [api]
Future<List<Exam>> getFutureExams(String token) async {
  var response = await http.get(
    Uri.parse('$_baseUrl/dashboard/info/future-exams'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
  );

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
      );
    }
  }

  if (response.statusCode == 200) {
    try {
      final List<dynamic> futureExamsData = jsonDecode(response.body);
      return futureExamsData.map((json) => Exam.fromJson(json)).toList();
    } catch (e) {
      print("Error parsing future exams: $e");
      throw Exception('Failed to parse future exams data: $e');
    }
  } else {
    print("Failed to load future exams: ${response.statusCode}");
    throw Exception('Failed to load future exams: ${response.statusCode}');
  }
}

Future<bool> validateToken(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/settings/user-info'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Referer': 'https://journal.top-academy.ru',
      },
    );
    
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

/// получение истории активности и наград студента [api]
Future<List<ActivityRecord>> getProgressActivity(String token) async {
  var response = await http.get(
    Uri.parse('$_baseUrl/dashboard/progress/activity'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
  );

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
      );
    }
  }

  if (response.statusCode == 200) {
    try {
      final List<dynamic> activityData = jsonDecode(response.body);
      return activityData.map((json) => ActivityRecord.fromJson(json)).toList();
    } catch (e) {
      print("Error parsing activity data: $e");
      throw Exception('Failed to parse activity data: $e');
    }
  } else {
    print("Failed to load activity data: ${response.statusCode}");
    print("Response body: ${response.body}");
    throw Exception('Failed to load activity data: ${response.statusCode}');
  }
}

/// получение списка домашних заданий [api]
Future<List<Homework>> getHomeworks(
  String token, {
  int? page, 
  int? status, 
  int? groupId, 
  int? specId,
  int? type, // 0 - домашние, 1 - лабораторные
}) async {

  final uri = Uri.parse('$_baseUrl/homework/operations/list');
  final params = <String, String>{};
  
  if (type != null) params['type'] = type.toString();
  if (page != null) params['page'] = page.toString();
  if (status != null) params['status'] = status.toString();
  if (groupId != null) params['group_id'] = groupId.toString();
  if (specId != null) params['spec_id'] = specId.toString();
  
  params['limit'] = '6';
  if (page != null) {
    params['offset'] = ((page - 1) * 6).toString();
  }

  final url = uri.replace(queryParameters: params.isNotEmpty ? params : null);
  
  var response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
  );

  if (response.statusCode == 401) {
    final newToken = await _reauthenticate();
    if (newToken != null) {
      response = await http.get(
        Uri.parse('$_baseUrl/homework/operations/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken',
          'Referer': 'https://journal.top-academy.ru',
        },
      );
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
      
      print("Parsed homework data: ${homeworkData.length} items");
      
      return homeworkData.map((json) => Homework.fromJson(json)).toList();
    } catch (e) {
      print("Error parsing homeworks: $e");
      print("Raw response that failed to parse: ${response.body}");
      throw Exception('Failed to parse homeworks data: $e');
    }
  } else {
    print("Failed to load homeworks: ${response.statusCode}");
    print("Response body: ${response.body}");
    throw Exception('Failed to load homeworks: ${response.statusCode}');
  }
}

/// получение счетчиков домашних заданий [api]
Future<List<HomeworkCounter>> getHomeworkCounters(
  String token, {
  int? type, // 0 - домашние, 1 - лабораторные
  int? groupId, 
  int? specId,
}) async {
  final uri = Uri.parse('$_baseUrl/count/homework');
  final params = <String, String>{};
  
  if (type != null) params['type'] = type.toString();
  if (groupId != null) params['group_id'] = groupId.toString();
  if (specId != null) params['spec_id'] = specId.toString();
  
  final url = uri.replace(queryParameters: params.isNotEmpty ? params : null);
  
  var response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Referer': 'https://journal.top-academy.ru',
    },
  );

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
      );
    }
  }

  if (response.statusCode == 200) {
    try {
      final List<dynamic> counterData = jsonDecode(response.body);
      return counterData.map((json) => HomeworkCounter.fromJson(json)).toList();
    } catch (e) {
      print("Error parsing homework counters: $e");
      throw Exception('Failed to parse homework counters: $e');
    }
  } else {
    print("Failed to load homework counters: ${response.statusCode}");
    throw Exception('Failed to load homework counters: ${response.statusCode}');
  }
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

}