import 'package:flutter/material.dart';
import '../models/user_data.dart';
import 'marks_and_profile_screen.dart';
import 'schedule_screen.dart';
import '../models/mark.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard_screen.dart';
import 'test_develop_area.dart';
import 'contacts_menu_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final String token;
  const MainMenuScreen({super.key, required this.token});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dataFuture; 

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final List<dynamic> results = await Future.wait([
      _apiService.getUser(widget.token),
      _apiService.getMarks(widget.token),
    ]);
    
    return {
      'user': results[0] as UserData,
      'marks': results[1] as List<Mark>,
    };
  }

  Map<String, double> _calculateAverages(List<Mark> marks) {
    double totalHomeWorkMarks = 0;
    int homeWorkCount = 0;
    double totalControlWorkMarks = 0;
    int controlWorkCount = 0;
    double totalLabWorkMarks = 0;
    int labWorkCount = 0;
    double totalAllMarks = 0;
    int allMarksCount = 0;

    for (var mark in marks) {
      if (mark.homeWorkMark != null) {
        totalHomeWorkMarks += mark.homeWorkMark!;
        homeWorkCount++;
        totalAllMarks += mark.homeWorkMark!;
        allMarksCount++;
      }
      if (mark.controlWorkMark != null) {
        totalControlWorkMarks += mark.controlWorkMark!;
        controlWorkCount++;
        totalAllMarks += mark.controlWorkMark!;
        allMarksCount++;
      }
      if (mark.labWorkMark != null) {
        totalLabWorkMarks += mark.labWorkMark!;
        labWorkCount++;
        totalAllMarks += mark.labWorkMark!;
        allMarksCount++;
      }
      if (mark.classWorkMark != null) {
        totalAllMarks += mark.classWorkMark!;
        allMarksCount++;
      }
    }

    return {
      'home': homeWorkCount > 0 ? totalHomeWorkMarks / homeWorkCount : 0.0,
      'control': controlWorkCount > 0 ? totalControlWorkMarks / controlWorkCount : 0.0,
      'lab': labWorkCount > 0 ? totalLabWorkMarks / labWorkCount : 0.0,
      'overall': allMarksCount > 0 ? totalAllMarks / allMarksCount : 0.0,
    };
  }
  
  Map<String, double> _calculateAttendance(List<Mark> marks) {
    if (marks.isEmpty) {
      return {'total': 0, 'attended': 0, 'late': 0, 'missed': 0, 'attended_percent': 0.0, 'late_percent': 0.0, 'missed_percent': 0.0};
    }

    final int totalLessons = marks.length;
    int attendedCount = 0;  
    int lateCount = 0;      
    int missedCount = 0;    

    for (var mark in marks) {
      if (mark.statusWas == 1) {
        attendedCount++;
      } else if (mark.statusWas == 2) {
        attendedCount++;
        lateCount++;
      } else if (mark.statusWas == 0) {
        missedCount++;
      }
    }
    
    return {
      'total': totalLessons.toDouble(),
      'attended': attendedCount.toDouble(),
      'attended_percent': (attendedCount / totalLessons) * 100,
      'late': lateCount.toDouble(),
      'late_percent': (lateCount / totalLessons) * 100,
      'missed': missedCount.toDouble(),
      'missed_percent': (missedCount / totalLessons) * 100,
    };
  }
  
  Widget _buildMarkAverageCard(String title, double average, Color color) {
    final averageString = average == 0.0 ? 'Н/Д' : average.toStringAsFixed(2);
    
    return Expanded(
      child: Card(
        color: color.withOpacity(0.8),
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                averageString,
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12, 
                  color: Colors.white70
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatCard(String title, double count, double percentage, Color color) {
    final countString = count.toInt().toString();
    final percentString = percentage.toStringAsFixed(2);
    
    String mainText;
    
    if (title == 'Всего пар') {
      mainText = countString;
    } else {
      mainText = '$countString (${percentString}%)';
    }

    return Expanded(
      child: Card(
        color: color.withOpacity(0.9),
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mainText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  int _getPointsByType(List<Map<String, dynamic>> pointsInfo, int typeId) {
  print("Searching for type: $typeId in $pointsInfo");
  
  try {
    final item = pointsInfo.firstWhere(
      (item) => item['new_gaming_point_types__id'] == typeId,
    );
    final points = item['points'];
    print("Found: $points for type $typeId");
    return points ?? 0;
  } catch (e) {
    print("Not found type $typeId, error: $e");
    return 0;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главное меню'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(child: Text("Ошибка загрузки данных: ${snapshot.error}"));
          }
          
          if (!snapshot.hasData) {
            return const Center(child: Text("Нет данных для отображения"));
          }

          final UserData userData = snapshot.data!['user'];
          final List<Mark> marks = snapshot.data!['marks'];
          
          final averages = _calculateAverages(marks);
          final attendance = _calculateAttendance(marks); 
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Padding(
                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: userData.photoPath.isNotEmpty
                              ? Image.network(
                                  '${userData.photoPath}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.account_circle, size: 100);
                                  },
                                )
                              : const Icon(Icons.account_circle, size: 100),
                        ),),
                        /* Text(userData.position == 1 ? 'Студент' : userData.position == 2 ? 'Преподаватель' : 'Гость',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),*/ // хз херня какая-то с позициями (position - место в списке ? Или роль ?) TODO: уточнить

                       Text(
                         userData.fullName,
                         style: const TextStyle(
                           fontSize: 22,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         'Группа: ${userData.groupName}',
                         style: TextStyle(
                           fontSize: 16,
                           color: Colors.grey[700],
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                        'ТопMoney: ${_getPointsByType(userData.pointsInfo, 1) + _getPointsByType(userData.pointsInfo, 2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                       const SizedBox(height: 4),
                       Text(
                        'ТопКоины: ${_getPointsByType(userData.pointsInfo, 1)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ТопГемы: ${_getPointsByType(userData.pointsInfo, 2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                       const SizedBox(height: 4),
                       /* Text(
                         'achieves_count: ${userData.groupName}',
                         style: TextStyle(
                           fontSize: 16,
                           color: Colors.grey[700],
                         ),
                       ), */
                     ],
                   ),
                 ),
                 const Divider(indent: 16, endIndent: 16),

                 const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 4.0, left: 12.0, right: 12.0),
                  child: Text(
                    'Средние оценки',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      _buildMarkAverageCard('Ср. Д/Р', averages['home'] ?? 0.0, Colors.red),
                      _buildMarkAverageCard('Ср. К/Р', averages['control'] ?? 0.0, Colors.green),
                      _buildMarkAverageCard('Ср. Л/Р', averages['lab'] ?? 0.0, Colors.purple),
                      _buildMarkAverageCard('Ср. Общая', averages['overall'] ?? 0.0, Colors.blue),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 4.0, left: 12.0, right: 12.0),
                  child: Text(
                    'Статистика посещаемости',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      _buildAttendanceStatCard('Всего пар', attendance['total'] ?? 0.0, 0.0, Colors.grey.shade700),
                      _buildAttendanceStatCard('Посещено Пар', attendance['attended'] ?? 0.0, attendance['attended_percent'] ?? 0.0, Colors.green.shade700),
                      _buildAttendanceStatCard('Опозданий', attendance['late'] ?? 0.0, attendance['late_percent'] ?? 0.0, Colors.orange.shade700),
                      _buildAttendanceStatCard('Пропусков', attendance['missed'] ?? 0.0, attendance['missed_percent'] ?? 0.0, Colors.red.shade700),
                    ],
                  ),
                ),

                // Основное меню
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        'Выберите раздел:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 250,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.school),
                          label: const Text('Оценки и Профиль'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MarksAndProfileScreen(token: widget.token),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: 250,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Расписание'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ScheduleScreen(token: widget.token),)
                            );
                          },
                        ),
                      ),
            
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 200,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Выйти из профиля'),
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), /*без него выглядит дерьмово*/
                      
                      SizedBox(
                        width: 250,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.leaderboard),
                          label: Text('Лидеры группы'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LeaderboardScreen(
                                  token: widget.token,
                                  isGroupLeaderboard: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: 250,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.leaderboard_outlined),
                          label: Text('Лидеры потока'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LeaderboardScreen(
                                  token: widget.token,
                                  isGroupLeaderboard: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: 250,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.question_answer),
                          label: Text('Меню для Связи'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ContactMenuScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: 250,
                        child: FloatingActionButton(
                          backgroundColor: Colors.red,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AreaDevelopScreen(
                                ),
                              ),
                            );
                          },
                          child: Icon(Icons.bug_report, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}