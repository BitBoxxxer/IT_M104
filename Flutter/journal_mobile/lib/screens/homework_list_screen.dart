import 'package:flutter/material.dart';
import 'dart:io';

import '../services/api_service.dart';
import '../services/download_service.dart';

import '../models/homework.dart';
import '../models/homework_counter.dart';
import '../models/widgets/error_snackBar.dart';

class HomeworkListScreen extends StatefulWidget {
  final String token;
  final bool isLabWork;

  const HomeworkListScreen({
    super.key,
    required this.token,
    required this.isLabWork,
  });

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen> {
  final ApiService _apiService = ApiService();

  List<Homework> _allHomeworks = [];
  List<HomeworkCounter> _counters = [];
  String _filterStatus = 'all';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  bool _showFilters = false;
  
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadHomeworks();
    _loadCounters();
  }

Future<void> _loadHomeworks({bool loadMore = false}) async {
  try {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
          _currentPage = 1;
          _hasMoreData = true;
          _allHomeworks = [];
        });
      } else {
        setState(() {
          _isLoadingMore = true;
        });
      }
      final type = widget.isLabWork ? 1 : 0;

      final homeworks = await _apiService.getHomeworks(
        widget.token, 
        type: type,
        page: _currentPage,
      );

      setState(() {
        if (!loadMore) {
          _allHomeworks = homeworks;
        } else {
          final newHomeworks = homeworks.where((newHw) => 
            !_allHomeworks.any((existingHw) => existingHw.id == newHw.id)
          ).toList();
          _allHomeworks.addAll(newHomeworks);
        }
        if (homeworks.isNotEmpty) {
          _currentPage++;
          _hasMoreData = homeworks.length >= 6;
        } else {
          _hasMoreData = false;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
      print("Error loading homeworks: $e");
    }
  }

  Future<void> _loadCounters() async {
    try {
      final type = widget.isLabWork ? 1 : 0;
      final counters = await _apiService.getHomeworkCounters(
        widget.token, 
        type: type
      );
      setState(() {
        _counters = counters;
      });
    } catch (e) {
      print("Error loading counters: $e");
    }
  }

  Future<void> _refreshData() async {
    await _loadHomeworks();
    await _loadCounters();
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;
    await _loadHomeworks(loadMore: true);
  }

  int _getCounterByStatus(int status) {
    try {
      if (status == HomeworkCounter.HOMEWORK_STATUS_ALL) {
        final allCounter = _counters.firstWhere(
          (c) => c.counterType == HomeworkCounter.HOMEWORK_STATUS_ALL,
          orElse: () => HomeworkCounter(counterType: HomeworkCounter.HOMEWORK_STATUS_ALL, counter: 0),
        );
        
        if (allCounter.counter > 0) {
          return allCounter.counter;
        }
        
        return _counters
            .where((counter) => 
                counter.counterType != HomeworkCounter.HOMEWORK_STATUS_DELETED &&
                counter.counterType != HomeworkCounter.HOMEWORK_STATUS_ALL)
            .fold(0, (sum, counter) => sum + counter.counter);
      }
      
      final counter = _counters.firstWhere(
        (c) => c.counterType == status,
      );
      return counter.counter;
    } catch (e) {
      return 0;
    }
  }

  int get _totalCounter {
    return [
      HomeworkCounter.HOMEWORK_STATUS_OPENED,
      HomeworkCounter.HOMEWORK_STATUS_INSPECTION,
      HomeworkCounter.HOMEWORK_STATUS_DONE,
      HomeworkCounter.HOMEWORK_STATUS_EXPIRED,
    ].fold(0, (sum, status) => sum + _getCounterByStatus(status));
  }

  Color _getStatusColor(Homework homework) {
    if (homework.isExpired) return Colors.red.shade700;
    if (homework.isDone) return Colors.green.shade700;
    if (homework.isInspection) return Colors.blue.shade700;
    if (homework.isOpened) return Colors.orange.shade700;
    if (homework.isDeleted) return Colors.grey.shade700;
    return Colors.grey.shade700;
  }

  String _getStatusText(Homework homework) {
    if (homework.isExpired) return 'Просрочено';
    if (homework.isDone) return 'Проверено';
    if (homework.isInspection) return 'На проверке';
    if (homework.isOpened) return 'Активно';
    if (homework.isDeleted) return 'Удалено';
    return 'Неизвестно';
  }

  IconData _getStatusIcon(Homework homework) {
    if (homework.isExpired) return Icons.warning_rounded;
    if (homework.isDone) return Icons.check_circle_rounded;
    if (homework.isInspection) return Icons.hourglass_top_rounded;
    if (homework.isOpened) return Icons.assignment_rounded;
    if (homework.isDeleted) return Icons.delete_rounded;
    return Icons.help_rounded;
  }

  List<Homework> _filterHomeworks(List<Homework> homeworks) {
    if (_filterStatus == 'all') {
      return homeworks..sort((a, b) {
        final priorityA = _getHomeworkPriority(a);
        final priorityB = _getHomeworkPriority(b);
        return priorityA.compareTo(priorityB);
      });
    }
    
    return homeworks.where((hw) {
      switch (_filterStatus) {
        case 'expired':
          return hw.isExpired;
        case 'done':
          return hw.isDone;
        case 'inspection':
          return hw.isInspection;
        case 'opened':
          return hw.isOpened;
        case 'deleted':
          return hw.isDeleted;
        default:
          return true;
      }
    }).toList();
  }

  int _getHomeworkPriority(Homework homework) {
    if (homework.isExpired) return 0;
    if (homework.isOpened) return 1;
    if (homework.isInspection) return 2;
    if (homework.isDone) return 3;
    if (homework.isDeleted) return 4;
    return 5;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Проверяет, доступно ли задание для скачивания
  bool _isDownloadAvailable(Homework homework) {
    return homework.filePath != null && 
           homework.filePath!.isNotEmpty &&
           homework.downloadUrl != null &&
           homework.downloadUrl!.isNotEmpty;
  }

  /// Проверяет, доступно ли сданное задание для скачивания
  bool _isStudentDownloadAvailable(Homework homework) {
    return homework.homeworkStud?.filePath != null && 
           homework.homeworkStud!.filePath!.isNotEmpty &&
           homework.studentDownloadUrl != null &&
           homework.studentDownloadUrl!.isNotEmpty;
  }

  /// Получает текст для кнопки скачивания в зависимости от статуса
  String _getDownloadButtonText(Homework homework) {
    if (homework.isDone) return 'Скачать задание (оценено)';
    if (homework.isInspection) return 'Скачать задание (на проверке)';
    if (homework.isExpired) return 'Скачать задание (просрочено)';
    return 'Скачать задание';
  }

  /// Получает текст для кнопки скачивания студенческой работы
  String _getStudentDownloadButtonText(Homework homework) {
    if (homework.isDone) return 'Скачать сданную работу (оценено)';
    if (homework.isInspection) return 'Скачать сданную работу (на проверке)';
    if (homework.isExpired) return 'Скачать сданную работу (просрочено)';
    return 'Скачать сданную работу';
  }

  Widget _buildHomeworkCard(Homework homework, int index) {
    final statusColor = _getStatusColor(homework);
    final isDownloadAvailable = _isDownloadAvailable(homework);
    final isStudentDownloadAvailable = _isStudentDownloadAvailable(homework);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              statusColor.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: statusColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(homework),
                  color: statusColor,
                  size: 24,
                ),
              ),
              
              SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            homework.subjectName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(homework),
                                size: 12,
                                color: statusColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _getStatusText(homework),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 6),
                    
                    Text(
                      homework.theme,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (homework.description != null && homework.description!.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(height: 6),
                          Text(
                            homework.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    
                    SizedBox(height: 12),
                    
                    Column(
                      children: [
                        _buildInfoRow('Преподаватель', homework.teacherName, Icons.person),
                        _buildInfoRow('Выдано', _formatDate(homework.creationTime), Icons.calendar_today),
                        _buildInfoRow(
                          'Срок сдачи', 
                          _formatDate(homework.completionTime),
                          Icons.access_time,
                          isUrgent: homework.completionTime.isBefore(DateTime.now()) && 
                                    !homework.isDone && 
                                    !homework.isInspection
                        ),
                        
                        if (homework.homeworkStud?.filename != null && homework.homeworkStud!.filename!.isNotEmpty)
                          _buildInfoRow('Сданный файл', homework.homeworkStud!.filename!, Icons.assignment_turned_in),
                        
                        if (homework.homeworkStud?.creationTime != null)
                          _buildInfoRow('Сдано', _formatDate(homework.homeworkStud!.creationTime), Icons.schedule),
                        
                        if (homework.homeworkStud?.mark != null)
                          _buildInfoRow('Оценка', homework.homeworkStud!.mark!.toStringAsFixed(1), Icons.grade),
                        
                        if (homework.filename != null && homework.filename!.isNotEmpty)
                          _buildInfoRow('Файл задания', homework.filename!, Icons.attach_file),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (homework.isExpired)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning, size: 12, color: Colors.red),
                                SizedBox(width: 4),
                                Text(
                                  'Просрочено',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (homework.isDone && homework.homeworkStud?.mark != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Оценка: ${homework.homeworkStud!.mark!.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (homework.canUpload && !homework.isDeleted)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.upload, size: 12, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  'Можно сдать',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (isDownloadAvailable)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.purple,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download, size: 12, color: Colors.purple),
                                SizedBox(width: 4),
                                Text(
                                  'Файл задания доступен',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (isStudentDownloadAvailable)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.teal,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assignment_turned_in, size: 12, color: Colors.teal),
                                SizedBox(width: 4),
                                Text(
                                  'Работа сдана',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    if (isStudentDownloadAvailable)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _downloadStudentHomeworkFile(homework);
                          },
                          icon: Icon(Icons.download_done, size: 16),
                          label: Text(_getStudentDownloadButtonText(homework)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: BorderSide(color: Colors.teal),
                            backgroundColor: Colors.teal.withOpacity(0.05),
                          ),
                        ),
                      ),
                    
                    if (isDownloadAvailable)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _downloadHomeworkFile(homework);
                          },
                          icon: Icon(Icons.download, size: 16),
                          label: Text(_getDownloadButtonText(homework)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: statusColor,
                            side: BorderSide(color: statusColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isUrgent = false}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: isUrgent ? Colors.red : Colors.grey.shade500,
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
              color: isUrgent ? Colors.red : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStatsCard(List<Homework> homeworks) {
    final totalHomeworks = homeworks.length;
    final activeHomeworks = homeworks.where((hw) => hw.isOpened).length;
    final expiredHomeworks = homeworks.where((hw) => hw.isExpired).length;
    final doneHomeworks = homeworks.where((hw) => hw.isDone).length;
    final inspectionHomeworks = homeworks.where((hw) => hw.isInspection).length;
    final submittedHomeworks = homeworks.where((hw) => hw.homeworkStud != null).length;
    final deletedHomeworks = homeworks.where((hw) => hw.isDeleted).length;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Статистика заданий',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Всего', totalHomeworks.toString(), Icons.assignment, Colors.blue),
                if (activeHomeworks > 0)
                  _buildStatItem('Активные', activeHomeworks.toString(), Icons.assignment_turned_in, Colors.orange),
                _buildStatItem('Проверенные', doneHomeworks.toString(), Icons.check_circle, Colors.green),
                _buildStatItem('Сдано', submittedHomeworks.toString(), Icons.assignment_turned_in, Colors.teal),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (expiredHomeworks > 0)
                  _buildStatItem('Просрочено', expiredHomeworks.toString(), Icons.warning, Colors.red),
                if (inspectionHomeworks > 0)
                  _buildStatItem('На проверке', inspectionHomeworks.toString(), Icons.hourglass_top, Colors.blue),
                if (deletedHomeworks > 0)
                  _buildStatItem('Удалено', deletedHomeworks.toString(), Icons.delete, Colors.grey),
              ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
  final List<Map<String, dynamic>> filterOptions = [
    {'value': 'all', 'label': 'Все', 'count': _totalCounter},
    {'value': 'opened', 'label': 'Активные', 'count': _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_OPENED)},
    {'value': 'inspection', 'label': 'На проверке', 'count': _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_INSPECTION)},
    {'value': 'done', 'label': 'Проверенные', 'count': _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_DONE)},
    {'value': 'expired', 'label': 'Просроченные', 'count': _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_EXPIRED)},
    {'value': 'deleted', 'label': 'Удаленные', 'count': _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_DELETED)},
  ];

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Wrap(
      spacing: 8,
      children: filterOptions.map((filter) {
        final String filterValue = filter['value'] as String;
        final String filterLabel = filter['label'] as String;
        final int filterCount = filter['count'] as int;
        final bool isSelected = _filterStatus == filterValue;
        
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(filterLabel),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  filterCount.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filterStatus = filterValue;
            });
          },
          backgroundColor: Colors.grey.shade200,
          selectedColor: Colors.blue.shade100,
          checkmarkColor: Colors.blue,
          labelStyle: TextStyle(
            color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
          ),
        );
      }).toList(),
    ),
  );
}

Future<void> _downloadHomeworkFile(Homework homework) async {
  try {
    ErrorSnackBar.showWarningSnackBar(context, 'Начинаем загрузку задания...');
    final downloadedFile = await _apiService.downloadHomeworkFile(
      widget.token, 
      homework
    );
    
    if (downloadedFile != null) {
      final String fileName = homework.filename ?? 
          downloadedFile.path.split('/').last ??
          'homework_${homework.id}';
      
      ErrorSnackBar.showSuccessSnackBar(
        context, 
        'Файл задания "$fileName" скачан!'
      );
      
      _showOpenFileDialog(downloadedFile, fileName);
    }
  } catch (e) {
    String errorMessage = 'Ошибка скачивания задания: $e';
    
    if (e.toString().contains('permission') || e.toString().contains('Permission')) {
      errorMessage = 'Проблема с доступом к хранилищу. Файл будет сохранен в папку Downloads.';
    }
    ErrorSnackBar.showErrorSnackBar(context, errorMessage);
  }
}
Future<void> _downloadStudentHomeworkFile(Homework homework) async {
  try {
    ErrorSnackBar.showWarningSnackBar(context, 'Начинаем загрузку студенческой работы...');
    final downloadedFile = await _apiService.downloadStudentHomeworkFile(
      widget.token, 
      homework
    );
    
    if (downloadedFile != null) {
      final String fileName = homework.studentFilename ?? 
          downloadedFile.path.split('/').last ??
          'student_homework_${homework.id}';
      
      ErrorSnackBar.showSuccessSnackBar(
        context, 
        'Сданная работа "$fileName" скачана!'
      );
      
      _showOpenFileDialog(downloadedFile, fileName);
    }
  } catch (e) {
    String errorMessage = 'Ошибка скачивания студенческой работы: $e';
    
    if (e.toString().contains('permission') || e.toString().contains('Permission')) {
      errorMessage = 'Проблема с доступом к хранилищу. Файл будет сохранен в папку Downloads.';
    }
    ErrorSnackBar.showErrorSnackBar(context, errorMessage);
  }
}
void _showOpenFileDialog(File file, String fileName) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Файл скачан'),
      content: Text('Файл "$fileName" успешно скачан. Хотите открыть его?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Закрыть'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            DownloadService.openDownloadedFile(file);
          },
          child: Text('Открыть'),
        ),
      ],
    ),
  );
}

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore 
            ? Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Загрузка следующих заданий...'),
                ],
              )
            : _hasMoreData
                ? TextButton(
                    onPressed: _loadMoreData,
                    child: Text('Загрузить еще'),
                  )
                : Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Все задания загружены',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isLabWork ? Icons.science : Icons.assignment,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            widget.isLabWork 
                ? 'Лабораторных работ нет'
                : 'Домашних заданий нет',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            'Здесь будут отображаться ваши учебные задания',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final filteredHomeworks = _filterHomeworks(_allHomeworks);
    
    if (_allHomeworks.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        _buildStatsCard(_allHomeworks),
        
        if (_showFilters) ...[
          _buildFilterChips(),
          SizedBox(height: 8),
          Text(
            'Найдено заданий: ${filteredHomeworks.length}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
        ],
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo is ScrollUpdateNotification) {
                  final metrics = scrollInfo.metrics;
                  if (metrics.maxScrollExtent - metrics.pixels < 200 && 
                      !_isLoadingMore && 
                      _hasMoreData) {
                    _loadMoreData();
                  }
                }
                return false;
              },
              child: ListView.builder(
                itemCount: filteredHomeworks.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredHomeworks.length) {
                    return _buildLoadMoreIndicator();
                  }
                  return _buildHomeworkCard(filteredHomeworks[index], index);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLabWork ? 'Лабораторные работы' : 'Домашние задания'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? Colors.blue : null,
            ),
            onPressed: _toggleFilters,
            tooltip: 'Фильтры',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading && _allHomeworks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка заданий...'),
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
                        onPressed: _refreshData,
                        child: Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }
}