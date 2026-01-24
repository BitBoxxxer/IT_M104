import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../_database/database_facade.dart';

import '../models/_system/schedule_note.dart';
import '../services/_account/account_manager_service.dart';
import '../services/_offline_service/offline_storage_service.dart';
import '../services/data_manager.dart';
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
  late PanelController _panelController;
  
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

     _panelController = PanelController();
    
    final cleanToken = widget.token.replaceAll('?offline=true', '');
    
    _dataFuture = _loadData(cleanToken);
    _notificationsStream = _notificationService.notificationsStream;
    _initializeNetworkService();

    _selectedIndex = 2;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _networkService.dispose();
    super.dispose();
  }

  void _initializeScreens() {
    _screens.clear();
    _screens.addAll([
      _buildMarksAndScheduleScreen(),
      _buildHomeworkScreen(),
      _buildMainMenuScreen(),
    ]);
  }

  void _togglePanel() {
    if (_panelController.isPanelClosed) {
      _panelController.open();
    } else {
      _panelController.close();
    }
  }

  void _closePanel() {
    _panelController.close();
  }

  Widget _buildMainMenuScreen() {
    return SingleChildScrollView(
      child: _buildMainContent(),
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
          child: StreamBuilder<bool>(
            stream: _networkService.connectionStream,
            initialData: _networkService.isConnected,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? true;
              
              if (!isConnected) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Доступно только в онлайн-режиме',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'Пожалуйста, подключитесь к интернету для доступа к заданиям',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Онлайн режим - показываем обычные кнопки
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isConnected ? Container(
                  padding: EdgeInsets.all(16),
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
                          'Предупреждение: В Offline режиме невозможно просматривать Задания',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ): SizedBox.shrink(),
                SizedBox(height: 20),
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
                  SizedBox(height: 60),
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
              );
            },
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

  Future<void> _initializeNetworkService() async {
    try {
      await _networkService.initialize();
    } catch (e) {
      print('❌ Ошибка инициализации NetworkService: $e');
    }
  }

  Future<Map<String, dynamic>> _loadData(String token) async {
    try {
      final List<dynamic> results = await Future.wait([
        _apiService.getUser(token),
        _apiService.getMarks(token),
      ]);
      
      return {
        'user': results[0] as UserData,
        'marks': results[1] as List<Mark>,
      };
    } catch (e) {
      print('❌ Ошибка загрузки данных: $e');
      
      if (e.toString().contains('Нет подключения') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Network') ||
          e.toString().contains('offline')) {
        
        return {
          'user': UserData(
            studentId: 0,
            fullName: 'offline режим',
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
          content: Text('Все данные синхронизированы для offline использования! ✅'),
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
    final filteredMarks = _filterTwelvePointMarks(marks);
    
    double totalHomeWorkMarks = 0;
    int homeWorkCount = 0;
    double totalControlWorkMarks = 0;
    int controlWorkCount = 0;
    double totalLabWorkMarks = 0;
    int labWorkCount = 0;
    double totalPracticalWorkMarks = 0;
    int practicalWorkCount = 0;
    double totalFinalWorkMarks = 0;
    int finalWorkCount = 0;
    double totalAllMarks = 0;
    int allMarksCount = 0;

    for (var mark in filteredMarks) {
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
      if (mark.practicalWorkMark != null) {
        totalPracticalWorkMarks += mark.practicalWorkMark!;
        practicalWorkCount++;
        totalAllMarks += mark.practicalWorkMark!;
        allMarksCount++;
      }
      if (mark.finalWorkMark != null) {
        totalFinalWorkMarks += mark.finalWorkMark!;
        finalWorkCount++;
        totalAllMarks += mark.finalWorkMark!;
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
      'practical': practicalWorkCount > 0 ? totalPracticalWorkMarks / practicalWorkCount : 0.0,
      'final': finalWorkCount > 0 ? totalFinalWorkMarks / finalWorkCount : 0.0,
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
  Future<void> _logout() async {
    try {
      final accountManager = AccountManagerService();
      final currentAccount = await accountManager.getCurrentAccount();
      
      if (currentAccount != null) {
        final offlineStorage = OfflineStorageService();
        await offlineStorage.clearAllOfflineData();
        
        final databaseFacade = DatabaseFacade();
        await databaseFacade.clearAllForAccount(currentAccount.id);
        await accountManager.removeAccount(currentAccount.id);
      }
      
      final secureStorage = SecureStorageService();
      await secureStorage.clearAll();
      
      final dataManager = DataManager();
      await dataManager.clearAllData();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              currentTheme: widget.currentTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
      
      print('✅ Выход выполнен: все данные аккаунта очищены');
    } catch (e) {
      print('❌ Ошибка при выходе: $e');

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
  
  return SingleChildScrollView(
    child: Column(
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
      
      const SizedBox(height: 4),
      
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
                    Center( // ✅ Центрируем текст
                      child: Text(
                        extractFirstName(userData.fullName),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center( // ✅ Центрируем текст
                      child: Text(
                        'ТопMoney: ${_getPointsByType(userData.pointsInfo, 1) + _getPointsByType(userData.pointsInfo, 2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
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
          final UserData userData = snapshot.data!['user'];

          final List<Mark> marks = snapshot.data!['marks'];

          final hasTwelvePointMarks = marks.any((mark) {
            try {
              if (mark.dateVisit.isNotEmpty == true) {
                final markDate = DateTime.parse(mark.dateVisit);
                final transitionDate = DateTime(2024, 9, 1);
                return markDate.isBefore(transitionDate);
              }
              return false;
            } catch (e) {
              return false;
            }
          });
          
          final filteredMarksForAverages = _filterTwelvePointMarks(marks);
          final twelvePointCount = marks.length - filteredMarksForAverages.length;
          
          final averages = _calculateAverages(filteredMarksForAverages);
          final attendance = _calculateAttendance(marks);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    if (hasTwelvePointMarks)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          color: Colors.orange.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.orange.shade800,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '12-балльная система',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'У вас есть $twelvePointCount оценок по 12-балльной системе. Они исключены из расчета средних баллов.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ],
                                ),
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                          child: Row(
                            children: [
                              Card(
                                elevation: 4,
                                margin: const EdgeInsets.all(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Посещение',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            spacing: 10,
                                            children: [
                                                _buildAttendanceLegendItem(
                                              const Color.fromARGB(255, 0, 0, 0), 
                                              'Всего', 
                                              attendance['total']?.toInt() ?? 0
                                              ),
                                              Row(
                                                spacing: 25,
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  _buildAttendanceLegendItem(
                                                    Colors.green, 
                                                    'Посещено', 
                                                    attendance['attended']?.toInt() ?? 0
                                                  ),
                                                  _buildAttendanceLegendItem(
                                                    Colors.orange, 
                                                    'Опоздания', 
                                                    attendance['late']?.toInt() ?? 0
                                                  ),
                                                  _buildAttendanceLegendItem(
                                                    Colors.red, 
                                                    'Пропуски', 
                                                    attendance['missed']?.toInt() ?? 0
                                                  ),
                                                ],
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                elevation: 4,
                                margin: const EdgeInsets.all(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Ср. Оценка',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 35),
                                      Row(
                                        children: [
                                          _buildLegendItemWithValue(Colors.blue, 'Общая', averages['overall'] ?? 0.0),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              ),
                            ]
                          ),
                          ),
                          const SizedBox(height: 8),
              // В методе _buildMainContent() заменить текущую карточку "Главное" на:

Card(
  elevation: 4,
  margin: EdgeInsets.all(8),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Сегодня',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            StreamBuilder<bool>(
              stream: _networkService.connectionStream,
              initialData: _networkService.isConnected,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? true;
                return Row(
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      isConnected ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: isConnected ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // Уведомления на сегодня
        FutureBuilder<List<ScheduleNote>>(
          future: _getTodayReminders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Ошибка загрузки: ${snapshot.error}');
            }
            
            final reminders = snapshot.data ?? [];
            
            if (reminders.isEmpty) {
              return Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 40,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Нет напоминаний на сегодня',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Напоминания (${reminders.length}):',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                ...reminders.map((note) => _buildReminderItem(note)).toList(),
              ],
            );
          },
        ),
        
        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 8),
        
        // Быстрые действия
        Column(
          children: [
            Row(
              children: [
                Expanded(
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
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.assignment),
                    label: Text('Задания'),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                        _pageController.animateToPage(
                          1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            StreamBuilder<bool>(
              stream: _networkService.connectionStream,
              initialData: _networkService.isConnected,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? true;
                return ElevatedButton.icon(
                  icon: Icon(Icons.sync),
                  label: Text('Синхронизировать'),
                  onPressed: isConnected ? _syncAllData : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: isConnected 
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ),
),
              const SizedBox(height: 8),
              Card(
  elevation: 4,
  margin: const EdgeInsets.all(8),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Заголовок с информацией
        Container(
          padding: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ваше место в рейтингах',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Нажмите для просмотра полного списка',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        // Кнопка лидеров группы с позицией
        _buildLeaderboardButtonWithPosition(
          title: 'Лидеры группы',
          icon: Icons.leaderboard,
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
          positionFuture: _getUserGroupPosition(),
        ),
        
        const SizedBox(height: 12),
        
        // Кнопка лидеров потока с позицией
        _buildLeaderboardButtonWithPosition(
          title: 'Лидеры потока',
          icon: Icons.leaderboard_outlined,
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
          positionFuture: _getUserStreamPosition(),
        ),
      ],
    ),
  ),
)
            ],
          );
        },
      ),
      SizedBox(height: 90),
      
      ],
    )
  );
  }

  @override
Widget build(BuildContext context) {
  if (_screens.isEmpty) {
    _initializeScreens();
  }

  return SlidingUpPanel(
    controller: _panelController,
    minHeight: 0,
    maxHeight: MediaQuery.of(context).size.height * 0.6,
    parallaxEnabled: true,
    parallaxOffset: 0.5,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    ),
    panelBuilder: (sc) => _buildPanelContent(sc),
    body: NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // Отключаем вертикальные свайпы в PageView, если панель открыта
        if (notification is UserScrollNotification) {
          if (_panelController.isPanelOpen || 
              _panelController.isPanelAnimating) {
            return true; // Предотвращаем прокрутку PageView
          }
        }
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: _selectedIndex == 2 ? Colors.transparent : Theme.of(context).appBarTheme.backgroundColor,
          elevation: _selectedIndex == 2 ? 0 : 4,
          automaticallyImplyLeading: false,
          actions: <Widget>[
              StreamBuilder<bool>(
              stream: _networkService.connectionStream,
              initialData: _networkService.isConnected,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? true;
                
                if (!isConnected) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.wifi_off,
                      color: Colors.orange,
                      size: 20,
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
              _buildNotificationIcon(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
              ),
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: _togglePanel,
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          // Добавьте этот параметр:
          scrollDirection: Axis.horizontal,
          // Отключите вертикальные свайпы:
          physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onIndexChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    ),
  );
}

  Widget _buildPanelContent(ScrollController sc) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final UserData userData = snapshot.data!['user'];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: userData.photoPath.isNotEmpty
                              ? NetworkImage(userData.photoPath)
                              : null,
                          child: userData.photoPath.isEmpty
                              ? Icon(Icons.account_circle, size: 60, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData.fullName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Группа: ${userData.groupName}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 16,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 12,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                        );
                      },
                    ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: EdgeInsets.zero,
                children: [
                    ListTile(
                      leading: Icon(Icons.feedback),
                      title: Text('Отзывы студента'),
                      onTap: () {
                        _closePanel();
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
                        _closePanel();
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
                            padding: EdgeInsets.all(16),
                            color: Colors.orange.withOpacity(0.1),
                            child: Row(
                              children: [
                                Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Offline режим',
                                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        else{
                        return Container(
                            padding: EdgeInsets.all(16),
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
                                  'Online режим',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  
                  StreamBuilder<bool>(
            stream: _networkService.connectionStream,
            initialData: _networkService.isConnected,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? true;
              
                      if (isConnected) {
                        return Container(
                          padding: EdgeInsets.all(16),
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
                                  'Предупреждение: В Offline режиме невозможно переключение между аккаунтами',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  
                  StreamBuilder<bool>(
                  stream: _networkService.connectionStream,
                  initialData: _networkService.isConnected,
                  builder: (context, snapshot) {
                    final isConnected = snapshot.data ?? true;
                    
                    return ListTile(
                      leading: Icon(
                        Icons.switch_account,
                        color: isConnected 
                          ? Theme.of(context).iconTheme.color
                          : Colors.grey,
                      ),
                      title: Text(
                        'Сменить аккаунт',
                        style: TextStyle(
                          color: isConnected 
                            ? Theme.of(context).textTheme.titleMedium?.color
                            : Colors.grey,
                        ),
                      ),
                      enabled: isConnected,
                      onTap: isConnected ? () {
                        _closePanel();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AccountSelectionScreen(
                              currentTheme: widget.currentTheme,
                              onThemeChanged: widget.onThemeChanged,
                            ),
                          ),
                        );
                      } : null,
                        );
                      },
                    ),
                  
                    ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Настройки'),
                      onTap: () {
                        _closePanel();
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
                  
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        _closePanel();
                        _logout();
                      },
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItemWithValue(Color color, String text, double value) {
    final valueText = value > 0 ? value.toStringAsFixed(1) : 'Н/Д';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            valueText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceLegendItem(Color color, String text, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    );
  }


  List<Mark> _filterTwelvePointMarks(List<Mark> marks) {
  return marks.where((mark) {
    try {
      if (mark.dateVisit.isNotEmpty == true) {
        final markDate = DateTime.parse(mark.dateVisit);
        final transitionDate = DateTime(2024, 9, 1);
        if (markDate.isBefore(transitionDate)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return true;
    }
  }).toList();
}

  String extractFirstName(String fullName) {
    if (fullName.isEmpty) return '';
    
    final parts = fullName.split(' ');
    if (parts.isNotEmpty) {
      return parts[1]; // получить имя из userdata.fullname - 
      //TODO: запомнить и потом вынести в утилиты.
    }
    
    return fullName;
  }

  Future<List<ScheduleNote>> _getTodayReminders() async {
  try {
    final databaseFacade = DatabaseFacade();
    final currentAccount = await databaseFacade.getCurrentAccount();
    
    if (currentAccount == null) {
      return [];
    }
    
    return await databaseFacade.getTodayReminders(currentAccount.id);
  } catch (e) {
    print('❌ Ошибка загрузки напоминаний: $e');
    return [];
  }
}

Widget _buildReminderItem(ScheduleNote note) {
  final time = note.reminderTime != null 
    ? DateFormat('HH:mm').format(note.reminderTime!)
    : 'Без времени';
  
  return Card(
    margin: EdgeInsets.symmetric(vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: note.noteColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: note.noteColor ?? Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        note.noteText,
        style: TextStyle(fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Icon(Icons.notifications, size: 12, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // При нажатии можно открыть редактирование или детали
        _showReminderDetails(context, note);
      },
    ),
  );
}

void _showReminderDetails(BuildContext context, ScheduleNote note) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Напоминание'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: note.noteColor ?? Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.noteText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (note.reminderTime != null)
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Время: ${DateFormat('HH:mm').format(note.reminderTime!)}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Дата: ${DateFormat('dd.MM.yyyy').format(note.date)}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Закрыть'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Реализовать переход к расписанию с открытием заметки
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ScheduleScreen(token: widget.token),
              ),
            ).then((_) {
              // Обновить список напоминаний после возвращения
              setState(() {});
            });
          },
          child: Text('Открыть в расписании'),
        ),
      ],
    ),
  );
}

// В class _MainMenuScreenState добавляем новые методы:

Future<int?> _getUserGroupPosition() async {
  try {
    final databaseFacade = DatabaseFacade();
    final currentAccount = await databaseFacade.getCurrentAccount();
    
    if (currentAccount == null) return null;
    
    final userDataFuture = await _dataFuture;
    if (!userDataFuture.containsKey('user')) return null;
    
    final UserData userData = userDataFuture['user'];
    
    // Получаем позицию пользователя в групповом лидерборде
    return await databaseFacade.getUserLeaderboardPosition(
      currentAccount.id,
      userData.studentId,
      true, // isGroupLeaders
    );
  } catch (e) {
    print('❌ Ошибка получения групповой позиции: $e');
    return null;
  }
}

Future<int?> _getUserStreamPosition() async {
  try {
    final databaseFacade = DatabaseFacade();
    final currentAccount = await databaseFacade.getCurrentAccount();
    
    if (currentAccount == null) return null;
    
    final userDataFuture = await _dataFuture;
    if (!userDataFuture.containsKey('user')) return null;
    
    final UserData userData = userDataFuture['user'];
    
    // Получаем позицию пользователя в потоковом лидерборде
    return await databaseFacade.getUserLeaderboardPosition(
      currentAccount.id,
      userData.studentId,
      false, // isGroupLeaders
    );
  } catch (e) {
    print('❌ Ошибка получения потоковой позиции: $e');
    return null;
  }
}

Widget _buildPositionBadge(int position) {
  return Container(
    width: 28,
    height: 28,
    margin: EdgeInsets.only(left: 8),
    decoration: BoxDecoration(
      color: _getPositionColor(position),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Center(
      child: Text(
        position.toString(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

Color _getPositionColor(int position) {
  if (position == 1) {
    return Color(0xFFFFD700); // Золотой
  } else if (position == 2) {
    return Color(0xFFC0C0C0); // Серебряный
  } else if (position == 3) {
    return Color(0xFFCD7F32); // Бронзовый
  } else if (position <= 10) {
    return Colors.blue.shade600;
  } else if (position <= 50) {
    return Colors.green.shade600;
  } else {
    return Colors.grey.shade600;
  }
}

String _getPositionSuffix(int position) {
  if (position % 10 == 1 && position % 100 != 11) return 'место';
  if (position % 10 >= 2 && position % 10 <= 4 && (position % 100 < 10 || position % 100 >= 20)) {
    return 'места';
  }
  return 'место';
}

Widget _buildLeaderboardButtonWithPosition({
  required String title,
  required IconData icon,
  required VoidCallback onPressed,
  required Future<int?> positionFuture,
}) {
  return SizedBox(
    width: double.infinity,
    child: FutureBuilder<int?>(
      future: positionFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasPosition = snapshot.hasData && snapshot.data != null;
        final position = snapshot.data;
        
        return ElevatedButton.icon(
          icon: icon != Icons.leaderboard_outlined 
            ? Icon(icon)
            : isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15),
                ),
              ),
              if (isLoading) ...[
                SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ] else if (hasPosition && position != null) ...[
                _buildPositionBadge(position),
                SizedBox(width: 8),
                Text(
                  '${_getPositionSuffix(position)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            backgroundColor: isLoading ? Colors.grey.shade700 : null,
          ),
        );
      },
    ),
  );
}
}