import 'package:flutter/material.dart';

import '../services/_offline_service/offline_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../services/api_service.dart';
import '../services/_notification/notification_service.dart';
import '../services/_network/network_service.dart';

import '../models/user_data.dart';
import '../models/mark.dart';
import '../models/_widgets/notifications/notification_item.dart';
import '../models/_widgets/navigation/custom_bottom_nav_bar.dart';

import '_account/account_selection_screen.dart';
import 'marks_and_profile_screen.dart';
import 'schedule_screen.dart';
import 'login_screen.dart';
import 'leaderboard_screen.dart';
import 'feedback_review.dart';
import 'test_develop_area.dart';
import 'settings_screen.dart';
import 'user_notification_screen.dart';
import 'exam_screen.dart';
import 'history_of_awards.dart';
import 'homework_list_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final String token;
  final String currentTheme;
  final Function(String) onThemeChanged;
  final bool isOfflineMode;
  
  const MainMenuScreen(
    {super.key, required this.token,
    required this.currentTheme,required this.onThemeChanged,
    this.isOfflineMode = false,}
  );

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final NetworkService _networkService = NetworkService();

  late Future<Map<String, dynamic>> _dataFuture;
  late Stream<List<NotificationItem>> _notificationsStream;
  bool _isOffline = false;
  
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    
    final cleanToken = widget.token.replaceAll('?offline=true', '');
    
    _dataFuture = _loadData(cleanToken);
    _notificationsStream = _notificationService.notificationsStream;
    _initializeNetworkService();

    _selectedIndex = 2;
    
  }

  void _initializeScreens() {
    _screens.clear();
    _screens.addAll([
      _buildMarksAndScheduleScreen(),
      _buildHomeworkScreen(),
      _buildMainMenuScreen(),
      _buildExamScreen(),
      _buildLeaderboardScreen(),
    ]);
  }

  Widget _buildMainMenuScreen() {
    return SingleChildScrollView(
      child: _buildMainContent(),
    );
  }

  Widget _buildLeaderboardScreen() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Ошибка загрузки данных'));
        }
        
        final UserData userData = snapshot.data!['user'];
        
        return Column(
          children: [
            AppBar(
              title: Text('Рейтинги'),
              centerTitle: true,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.leaderboard),
                      label: Text('Лидеры группы'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LeaderboardScreen(
                              token: widget.token,
                              isGroupLeaderboard: true,
                              currentUserId: userData.studentId,
                              currentUserName: userData.fullName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.leaderboard_outlined),
                      label: Text('Лидеры потока'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LeaderboardScreen(
                              token: widget.token,
                              isGroupLeaderboard: false,
                              currentUserId: userData.studentId,
                              currentUserName: userData.fullName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeworkScreen() {
    return Column(
      children: [
        AppBar(
          title: Text('Задания'),
          centerTitle: true,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.book),
                  label: Text('Домашние задания'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HomeworkListScreen(
                          token: widget.token,
                          isLabWork: false,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.computer),
                  label: Text('Лабораторные задания'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HomeworkListScreen(
                          token: widget.token,
                          isLabWork: true,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarksAndScheduleScreen() {
    return Column(
      children: [
        AppBar(
          title: Text('Оценки и Расписание'),
          centerTitle: true,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.school),
                    label: Text('Оценки и Пары'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MarksAndProfileScreen(token: widget.token),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text('Расписание'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ScheduleScreen(token: widget.token),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamScreen() {
    return Column(
      children: [
        AppBar(
          title: Text('Экзамены'),
          centerTitle: true,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.library_books),
                    label: Text('Экзамены'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExamScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _initializeNetworkService() async {
    try {
      await _networkService.initialize();
    } catch (e) {
      print('❌ Ошибка инициализации NetworkService: $e');
    }
  }

  @override
  void dispose() {
    _networkService.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData(String token) async {
    try {
      final List<dynamic> results = await Future.wait([
        _apiService.getUser(token),
        _apiService.getMarks(token),
      ]);
      
      if (mounted) {
        setState(() {
          _isOffline = false;
        });
      }
      
      return {
        'user': results[0] as UserData,
        'marks': results[1] as List<Mark>,
      };
    } catch (e) {
      print('❌ Ошибка загрузки данных: $e');
      
      if (e.toString().contains('Нет подключения') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Network') ||
          e.toString().contains('офлайн')) {
        
        if (mounted) {
          setState(() {
            _isOffline = true;
          });
        }
        
        return {
          'user': UserData(
            studentId: 0,
            fullName: 'Офлайн режим',
            groupName: 'Нет данных',
            photoPath: '',
            pointsInfo: [],
            position: 0,
          ),
          'marks': [],
        };
      }
      rethrow;
    }
  }
  
  Future<void> _syncAllData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Синхронизация'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Синхронизация данных...'),
            ],
          ),
        ),
      );

      await _apiService.syncAllData(widget.token);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Все данные синхронизированы для офлайн использования! ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      
      _refreshData();
      
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка синхронизации: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _refreshData() async {
      final cleanToken = widget.token.replaceAll('?offline=true', '');
      setState(() {
        _dataFuture = _loadData(cleanToken);
      });
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
    final secureStorage = SecureStorageService();
    await secureStorage.clearAll();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
            LoginScreen(
              currentTheme: widget.currentTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
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

  Widget _buildNotificationIcon() {
    return StreamBuilder<List<NotificationItem>>(
      stream: _notificationsStream,
      initialData: const [],
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;
        
        return Stack(
          children: [
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: unreadCount > 0
                    ? const Icon(Icons.notifications_active, key: ValueKey('active'))
                    : const Icon(Icons.notifications, key: ValueKey('normal')),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserNotificationScreen()
                  )
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      key: ValueKey(unreadCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent() {
    final coverHeight = MediaQuery.of(context).size.height * 0.25;
    final profileHeight = 100.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: coverHeight,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/menu_user_background.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
            
            Positioned(
              left: 0,
              right: 0,
              bottom: -profileHeight / 2,
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, -profileHeight / 4),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: profileHeight,
                          height: profileHeight,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      
                      if (snapshot.hasData) {
                        final UserData userData = snapshot.data!['user'];
                        
                        return Container(
                          width: profileHeight,
                          height: profileHeight,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(profileHeight / 2),
                            child: userData.photoPath.isNotEmpty
                                ? Image.network(
                                    '${userData.photoPath}',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.white,
                                        child: Icon(
                                          Icons.account_circle, 
                                          size: profileHeight,
                                          color: Colors.grey[700],
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.white,
                                    child: Icon(
                                      Icons.account_circle, 
                                      size: profileHeight,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                          ),
                        );
                      }
                      
                      return Container(
                        width: profileHeight,
                        height: profileHeight,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          color: Colors.white,
                          child: Icon(
                            Icons.account_circle, 
                            size: profileHeight,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      
      SizedBox(height: profileHeight / 2),
      
      StreamBuilder<bool>(
        stream: _networkService.connectionStream,
        initialData: _networkService.isConnected,
        builder: (context, snapshot) {
          final isConnected = snapshot.data ?? true;
          
          return !isConnected
              ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  color: Colors.orange,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Офлайн режим', style: TextStyle(color: Colors.white)),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: _refreshData,
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Обновить', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox.shrink();
        },
      ),
      
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final UserData userData = snapshot.data!['user'];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      userData.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Группа: ${userData.groupName}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                    'ТопMoney: ${_getPointsByType(userData.pointsInfo, 1) + _getPointsByType(userData.pointsInfo, 2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ТопКоины: ${_getPointsByType(userData.pointsInfo, 1)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ТопГемы: ${_getPointsByType(userData.pointsInfo, 2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
            
            return SizedBox.shrink();
          },
        ),
      ),
      const Divider(indent: 16, endIndent: 16),

      FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              margin: EdgeInsets.only(top: 50),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasError) {
            return Container(
              margin: EdgeInsets.only(top: 50),
              child: Center(child: Text("Ошибка загрузки данных: ${snapshot.error}")),
            );
          }
          
          if (!snapshot.hasData) {
            return Container(
              margin: EdgeInsets.only(top: 50),
              child: const Center(child: Text("Нет данных для отображения")),
            );
          }

          final List<Mark> marks = snapshot.data!['marks'];
          
          final averages = _calculateAverages(marks);
          final attendance = _calculateAttendance(marks); 
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      'DEBUG:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    
                    StreamBuilder<bool>(
                      stream: _networkService.connectionStream,
                      initialData: _networkService.isConnected,
                      builder: (context, snapshot) {
                        final isConnected = snapshot.data ?? true;
                        
                        return SizedBox(
                          width: 250,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.sync),
                            label: Text('Синхронизировать все'),
                            onPressed: !isConnected || _isOffline ? null : () {
                              _syncAllData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    // TODO: Перенести в экран настроек - ДИ
                    ElevatedButton(
                      onPressed: () async {
                        final offlineStorage = OfflineStorageService();
                        await offlineStorage.fixHomeworkStorageData();
                        
                        await _refreshData();
                        
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Хранилище очищено, загружаем заново...'))
                          );
                        }
                      },
                      child: Text('Исправить кэш заданий (DEBUG)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 250,
                      child: FloatingActionButton(
                        backgroundColor: Colors.red,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AreaDevelopScreen(),
                            ),
                          );
                        },
                        child: Icon(Icons.bug_report, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_screens.isEmpty) {
      _initializeScreens();
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Главное меню'),
        backgroundColor: _selectedIndex == 2 ? Colors.transparent : Theme.of(context).appBarTheme.backgroundColor,
        elevation: _selectedIndex == 2 ? 0 : 4,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          if (_isOffline && _selectedIndex == 2)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.wifi_off,
                color: Colors.orange,
                size: 20,
              ),
            ),
          if (_selectedIndex == 2)
            _buildNotificationIcon(),
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Обновить данные',
            ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: _dataFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final UserData userData = snapshot.data!['user'];
                          return UserAccountsDrawerHeader(
                            accountName: Text(userData.fullName),
                            accountEmail: Text('Группа: ${userData.groupName}'),
                            currentAccountPicture: CircleAvatar(
                              backgroundImage: userData.photoPath.isNotEmpty
                                  ? NetworkImage(userData.photoPath)
                                  : null,
                              child: userData.photoPath.isEmpty
                                  ? Icon(Icons.account_circle, size: 48)
                                  : null,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              image: DecorationImage(
                                image: AssetImage('assets/images/menu_user_background.jpg'),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.6),
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                          );
                        }
                        return UserAccountsDrawerHeader(
                          accountName: Text('Загрузка...'),
                          accountEmail: Text(''),
                          currentAccountPicture: CircleAvatar(
                            child: CircularProgressIndicator(),
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                          ),
                        );
                      },
                    ),
                    
                    ListTile(
                      leading: Icon(Icons.feedback),
                      title: Text('Отзывы студента'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FeedbackReviewScreen(token: widget.token),
                          ),
                        );
                      },
                    ),
                    
                    ListTile(
                      leading: Icon(Icons.emoji_events),
                      title: Text('Список наград'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HistoryOfAwardsScreen(),
                          ),
                        );
                      },
                    ),
                    
                    Divider(),
                    
                    StreamBuilder<bool>(
                      stream: _networkService.connectionStream,
                      initialData: _networkService.isConnected,
                      builder: (context, snapshot) {
                        final isConnected = snapshot.data ?? true;
                        
                        if (!isConnected) {
                          return Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            color: Colors.orange.withOpacity(0.1),
                            child: Row(
                              children: [
                                Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Офлайн режим',
                                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: Colors.blue.withOpacity(0.1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Онлайн режим',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                     if (!_isOffline) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: Colors.orange.withOpacity(0.1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'В Offline режиме невозможно переключение между аккаунтами',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color.fromARGB(255, 255, 129, 26),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                     ],
                    
                    ListTile(
                      leading: Icon(Icons.switch_account),
                      title: Text('Сменить аккаунт'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AccountSelectionScreen(
                              currentTheme: widget.currentTheme,
                              onThemeChanged: widget.onThemeChanged,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Настройки'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              currentTheme: widget.currentTheme,
                              onThemeChanged: widget.onThemeChanged,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(Icons.logout),
                  label: Text('Выйти'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _logout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: Container(
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onIndexChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}