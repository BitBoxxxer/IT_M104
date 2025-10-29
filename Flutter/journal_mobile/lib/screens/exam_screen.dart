import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../models/exam.dart';

class ExamScreen extends StatefulWidget {
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  List<Exam> _allExams = [];
  List<Exam> _futureExams = [];
  List<Exam> _pastExams = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _debugInfo = '';

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

      setState(() {
        _allExams = allExams;
        _futureExams = futureExams;
        _pastExams = pastExams;
        _isLoading = false;
        _debugInfo = 'Загружено: ${allExams.length} всех экзаменов, ${futureExams.length} предстоящих, ${pastExams.length} прошедших';
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

  Widget _buildFutureExamCard(Exam exam) {
    return Card(
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
                Container(
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
              ],
            ),
            
            SizedBox(height: 12),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (exam.teacherName != null && exam.teacherName!.isNotEmpty) 
                  Row(
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
                
                SizedBox(height: 4),
                
                Row(
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
                
                SizedBox(height: 8),
                Text(
                  '📅 Предстоящий экзамен',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastExamCard(Exam exam) {
    return Card(
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
                Container(
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
                  child: Text(
                    exam.displayGrade,
                    style: TextStyle(
                      color: exam.isPassed ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                  Row(
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
                
                SizedBox(height: 4),
                
                Row(
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
                
                SizedBox(height: 8),
              ],
            ),
          ],
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
          return _buildFutureExamCard(exams[index]);
        },
      ),
    );
  }

Widget _buildPastExamsList(List<Exam> exams, String emptyMessage) {
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

  final numericGrades = exams
      .map((e) => e.numericGrade)
      .where((grade) => grade != null && grade > 0)
      .cast<int>()
      .toList();
  
  final averageGrade = numericGrades.isNotEmpty 
      ? (numericGrades.reduce((a, b) => a + b) / numericGrades.length).toStringAsFixed(1)
      : '0.0';

  return Column(
    children: [
      if (numericGrades.isNotEmpty)
        Container(
          padding: EdgeInsets.all(16),
          child: _buildAverageGradeCard(averageGrade, numericGrades.length),
        ),
      
      Expanded(
        child: RefreshIndicator(
          onRefresh: _loadExams,
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 16),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              return _buildPastExamCard(exams[index]);
            },
          ),
        ),
      ),
    ],
  );
}

Widget _buildAverageGradeCard(String averageGrade, int gradedExamsCount) {
  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16),
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Средний балл',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                averageGrade,
                style: TextStyle(
                  fontSize: 24,
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
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                gradedExamsCount.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.upcoming),
              text: 'Предстоящие (${_futureExams.length})',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Сданные (${_pastExams.length})',
            ),
          ],
        ),
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
                  children: [
                    _buildFutureExamsList(
                      _futureExams,
                      'Нет предстоящих экзаменов',
                    ),
                    _buildPastExamsList(
                      _pastExams,
                      'Нет сданных экзаменов',
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadExams,
        child: Icon(Icons.refresh),
        tooltip: 'Обновить',
      ),
    );
  }
}