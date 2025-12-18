import 'package:flutter/material.dart';
import 'package:journal_mobile/models/_widgets/exams/error_exams.dart';
import 'package:journal_mobile/models/_widgets/exams/loading_exams.dart';

import '../services/_network/network_service.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

import '../models/_widgets/exams/exam_lists/five_point_exams_list.dart';
import '../models/_widgets/exams/exam_lists/future_exams_list.dart';
import '../models/_widgets/exams/exam_lists/twelve_point_exams_list.dart';
import '../models/_widgets/exams/exam_tab_bar.dart';
import '../models/_widgets/exams/exam.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final NetworkService _networkService = NetworkService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  String _debugInfo = '';
  final List<Widget> _tabs = [];
  final List<Widget> _tabViews = [];

  final GlobalKey<TwelvePointExamsListState> _twelvePointListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _debugInfo = 'Начинаем загрузку...';
      });

      final token = await _secureStorage.getToken();
      if (token == null) {
        throw Exception('Токен не найден');
      }

      setState(() {
        _debugInfo = 'Токен получен, загружаем экзамены...';
      });

      final allExams = await _apiService.getExams(token);
      final futureExams = await _apiService.getFutureExams(token);

      final pastExams = allExams.where((exam) => exam.isPast).toList();
      
      final twelvePointExams = pastExams.where((exam) => exam.isTwelvePointSystem && exam.hasGrade).toList();
      final fivePointExams = pastExams.where((exam) => !exam.isTwelvePointSystem && exam.hasGrade).toList();

      _createTabs(twelvePointExams, fivePointExams, futureExams);

      setState(() {
        _isLoading = false;
        _debugInfo = 'Загружено: ${allExams.length} всех экзаменов, ${futureExams.length} предстоящих, ${pastExams.length} прошедших (${twelvePointExams.length} 12-балльных, ${fivePointExams.length} 5-балльных)';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoading = false;
        _debugInfo = 'Ошибка: $e';
      });
      print('Error loading exams: $e');
    }
  }

  void _createTabs(List<Exam> twelvePointExams, List<Exam> fivePointExams, List<Exam> futureExams) {
    _tabs.clear();
    _tabViews.clear();

    _tabs.add(
      Tab(
        icon: const Icon(Icons.upcoming),
        text: 'Предстоящие (${futureExams.length})',
      ),
    );
    _tabViews.add(
      FutureExamsList(
        exams: futureExams,
        emptyMessage: 'Нет предстоящих экзаменов',
        onRefresh: _loadExams,
      ),
    );

    if (twelvePointExams.isNotEmpty) {
      _tabs.add(
        Tab(
          icon: const Icon(Icons.star, color: Colors.orange),
          text: '12-балльные (${twelvePointExams.length})',
        ),
      );
      _tabViews.add(
        TwelvePointExamsList(
          key: _twelvePointListKey,
          exams: twelvePointExams,
          emptyMessage: 'Нет экзаменов по 12-балльной системе',
          onRefresh: _loadExams,
        ),
      );
    }

    _tabs.add(
      Tab(
        icon: const Icon(Icons.history),
        text: '5-балльные (${fivePointExams.length})',
      ),
    );
    _tabViews.add(
      FivePointExamsList(
        exams: fivePointExams,
        emptyMessage: 'Нет экзаменов по 5-балльной системе',
        onRefresh: _loadExams,
      ),
    );

    _tabController.dispose();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Экзамены'),
        bottom: _tabs.isNotEmpty
            ? ExamTabBar(
                tabController: _tabController,
                tabs: _tabs,
              )
            : null,
        actions: [
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
        ],
      ),
      body: _isLoading
          ? LoadingExams(debugInfo: _debugInfo)
          : _errorMessage.isNotEmpty
              ? ErrorExams(
                  errorMessage: _errorMessage,
                  onRetry: _loadExams,
                )
              : TabBarView(
                  controller: _tabController,
                  children: _tabViews,
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadExams,
        tooltip: 'Обновить',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}