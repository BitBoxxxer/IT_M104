import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../models/exam.dart';

import '../models/widgets/exam_widgets/twelve_point_exams_list.dart';
import '../models/widgets/animation/slide_in_card.dart';
import '../models/widgets/animation/fade_in_animation.dart';
import '../models/widgets/animation/scale_animation.dart';
import '../models/widgets/animation/fade_in_row.dart';

class ExamScreen extends StatefulWidget {
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  String _debugInfo = '';
  List<Widget> _tabs = [];
  List<Widget> _tabViews = [];

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
        icon: Icon(Icons.upcoming),
        text: 'Предстоящие (${futureExams.length})',
      ),
    );
    _tabViews.add(
      _buildFutureExamsList(futureExams, 'Нет предстоящих экзаменов'),
    );

    if (twelvePointExams.isNotEmpty) {
      _tabs.add(
        Tab(
          icon: Icon(Icons.star, color: Colors.orange),
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
        icon: Icon(Icons.history),
        text: '5-балльные (${fivePointExams.length})',
      ),
    );
    _tabViews.add(
      _buildFivePointExamsList(fivePointExams, 'Нет экзаменов по 5-балльной системе'),
    );

    _tabController.dispose();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  Widget _buildFutureExamCard(Exam exam, int index) {
    return SlideInCard(
      delay: Duration(milliseconds: 100 * index),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.subjectName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ScaleAnimation(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        'Ожидается',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exam.teacherName != null && exam.teacherName!.isNotEmpty) 
                    FadeInRow(
                      delay: Duration(milliseconds: 200 + 100 * index),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            exam.teacherName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 4),
                  
                  FadeInRow(
                    delay: Duration(milliseconds: 300 + 100 * index),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.blue[700]),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(exam.date),
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  FadeInAnimation(
                    delay: Duration(milliseconds: 400 + 100 * index),
                    child: Text(
                      '📅 Предстоящий экзамен',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastExamCard(Exam exam, int index, {bool showSystemInfo = true}) {
    final isTwelvePoint = exam.isTwelvePointSystem;
    final originalGrade = exam.originalNumericGrade;
    
    return SlideInCard(
      delay: Duration(milliseconds: 100 * index),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.subjectName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showSystemInfo && isTwelvePoint && originalGrade != null)
                          FadeInAnimation(
                            delay: Duration(milliseconds: 150 + 100 * index),
                            child: Text(
                              '12-балльная система',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ScaleAnimation(
                    delay: Duration(milliseconds: 200 + 100 * index),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: exam.isPassed 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: exam.isPassed ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            exam.displayGrade,
                            style: TextStyle(
                              color: exam.isPassed ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isTwelvePoint && originalGrade != null && exam.displayGrade != originalGrade.toString())
                            Text(
                              '($originalGrade)',
                              style: TextStyle(
                                color: exam.isPassed ? Colors.green : Colors.orange,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exam.teacherName != null && exam.teacherName!.isNotEmpty) 
                    FadeInRow(
                      delay: Duration(milliseconds: 250 + 100 * index),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            exam.teacherName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 4),
                  
                  FadeInRow(
                    delay: Duration(milliseconds: 300 + 100 * index),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.blue[700]),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(exam.date),
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildFutureExamsList(List<Exam> exams, String emptyMessage) {
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          return _buildFutureExamCard(exams[index], index);
        },
      ),
    );
  }

  Widget _buildFivePointExamsList(List<Exam> exams, String emptyMessage) {
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final stats = _calculateAverageGrade(exams);

    return Column(
      children: [
        if (stats['count']! > 0)
          Padding(
            padding: EdgeInsets.all(16),
            child: _buildAverageGradeCard(
              (stats['average'] as double).toStringAsFixed(1),
              stats['count']!,
              '5-балльная система',
              Colors.blue,
            ),
          ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadExams,
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 16),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                return _buildPastExamCard(exams[index], index, showSystemInfo: false);
              },
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateAverageGrade(List<Exam> exams) {
    final numericGrades = exams
        .map((e) => e.numericGrade)
        .where((grade) => grade != null && grade > 0)
        .cast<int>()
        .toList();
    
    final count = numericGrades.length;
    final average = count > 0 
        ? (numericGrades.reduce((a, b) => a + b) / count)
        : 0.0;

    return {
      'average': average,
      'count': count,
    };
  }

  Widget _buildAverageGradeCard(String averageGrade, int gradedExamsCount, String systemName, Color color) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              systemName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Средний балл',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      averageGrade,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getGradeColor(double.parse(averageGrade)),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Оценок',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      gradedExamsCount.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 4.5) return Colors.blueAccent;
    if (grade >= 4) return Colors.green;
    if (grade >= 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Экзамены'),
        bottom: _tabs.isNotEmpty
            ? TabBar(
                controller: _tabController,
                tabs: _tabs,
              )
            : null,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка экзаменов...'),
                  if (_debugInfo.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      _debugInfo,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadExams,
                        child: Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _tabViews,
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadExams,
        child: Icon(Icons.refresh),
        tooltip: 'Обновить',
      ),
    );
  }
}