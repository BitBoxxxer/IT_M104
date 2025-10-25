import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/secure_storage_service.dart';
import '../models/mark.dart';
import '../models/user_data.dart';
import '../models/days_element.dart';
import '../models/leaderboard_user.dart';
import '../models/leader_position_model.dart';
import  '../models/feedback_review.dart';

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
      print("Raw feedback response: ${response.body}");
      
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


// Для тестов. Запросы чисто для проверок РАЗРАБОТЧИКАМ
/// замена токена на некорректный для тестирования обработки ошибки [api]
Future<void> simulateTokenError() async {
  final secureStorage = SecureStorageService();
  await secureStorage.saveToken('invalid_token_12345');
  print('Искусственная ошибка токена активирована!');
}

Future<void> clearTokenForTesting() async {
  final secureStorage = SecureStorageService();
  await secureStorage.clearAll();
  print('Все данные очищены для тестирования!');
}

}