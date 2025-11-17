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

class _HomeworkListScreenState extends State<HomeworkListScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  Map<String, List<Homework>> _tabHomeworks = {};
  Map<String, int> _tabCurrentPages = {};
  Map<String, bool> _tabHasMoreData = {};
  Map<String, bool> _tabIsLoading = {};
  Map<String, bool> _tabIsLoadingMore = {};
  Map<String, String> _tabErrorMessages = {};

  List<HomeworkCounter> _counters = [];
  
  final int _pageSize = 6;

  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Активные', 'status': 'opened', 'icon': Icons.assignment, 'counterType': HomeworkCounter.HOMEWORK_STATUS_OPENED},
    {'label': 'На проверке', 'status': 'inspection', 'icon': Icons.hourglass_top, 'counterType': HomeworkCounter.HOMEWORK_STATUS_INSPECTION},
    {'label': 'Проверенные', 'status': 'done', 'icon': Icons.check_circle, 'counterType': HomeworkCounter.HOMEWORK_STATUS_DONE},
    {'label': 'Просроченные', 'status': 'expired', 'icon': Icons.warning, 'counterType': HomeworkCounter.HOMEWORK_STATUS_EXPIRED},
    {'label': 'Удаленные', 'status': 'deleted', 'icon': Icons.delete, 'counterType': HomeworkCounter.HOMEWORK_STATUS_DELETED},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    for (var tab in _tabs) {
      String status = tab['status'];
      _tabHomeworks[status] = [];
      _tabCurrentPages[status] = 1;
      _tabHasMoreData[status] = true;
      _tabIsLoading[status] = false;
      _tabIsLoadingMore[status] = false;
      _tabErrorMessages[status] = '';
    }

    _tabController.addListener(_handleTabSelection);
    _loadCounters();
    String firstTabStatus = _tabs[_currentTabIndex]['status'];
    _loadHomeworksForTab(firstTabStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabHomeworks['deleted']!.isEmpty && 
          !_tabIsLoading['deleted']! && 
          _tabErrorMessages['deleted']!.isEmpty) {
        _loadHomeworksForTab('deleted');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
  if (_tabController.index != _currentTabIndex) {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
    
    String newTabStatus = _tabs[_currentTabIndex]['status'];
    
    if (newTabStatus == 'deleted') {
      _loadCounters();
    }
    
    if (_tabHomeworks[newTabStatus]!.isEmpty && 
        !_tabIsLoading[newTabStatus]! && 
        _tabErrorMessages[newTabStatus]!.isEmpty) {
      _loadHomeworksForTab(newTabStatus);
    }
  }
}

int _getCounterForDeletedTab() {
  try {
    final counter = _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_DELETED);
    if (counter > 0) return counter;
    
    final deletedHomeworks = _tabHomeworks['deleted'] ?? [];
    if (deletedHomeworks.isNotEmpty) {
      return deletedHomeworks.length;
    }
    
    return 0;
  } catch (e) {
    return 0;
  }
}

  String get _currentFilterStatus {
    return _tabs[_currentTabIndex]['status'];
  }

  Future<void> _loadHomeworksForTab(String tabStatus, {bool loadMore = false}) async {
    try {
      if (!loadMore) {
        setState(() {
          _tabIsLoading[tabStatus] = true;
          _tabErrorMessages[tabStatus] = '';
          _tabCurrentPages[tabStatus] = 1;
          _tabHasMoreData[tabStatus] = true;
        });
      } else {
        setState(() {
          _tabIsLoadingMore[tabStatus] = true;
        });
      }
      
      final type = widget.isLabWork ? 1 : 0;

      int? statusParam;
      switch (tabStatus) {
        case 'expired':
          statusParam = 0;
          break;
        case 'done':
          statusParam = 1;
          break;
        case 'inspection':
          statusParam = 2;
          break;
        case 'opened':
          statusParam = 3;
          break;
        case 'deleted':
          statusParam = 5;
          break;
        default:
          statusParam = null;
      }

      await Future.delayed(Duration(milliseconds: 300));

      final homeworks = await _apiService.getHomeworks(
        widget.token, 
        type: type,
        page: _tabCurrentPages[tabStatus]!,
        status: statusParam,
      );

      setState(() {
        if (!loadMore) {
          _tabHomeworks[tabStatus] = homeworks;
        } else {
          _tabHomeworks[tabStatus]!.addAll(homeworks);
        }
        
        _tabHasMoreData[tabStatus] = homeworks.isNotEmpty && homeworks.length >= _pageSize;
        if (_tabHasMoreData[tabStatus]! && loadMore) {
        _tabCurrentPages[tabStatus] = _tabCurrentPages[tabStatus]! + 1;
      }
        
        _tabIsLoading[tabStatus] = false;
        _tabIsLoadingMore[tabStatus] = false;
      });

    } catch (e) {
      setState(() {
        _tabErrorMessages[tabStatus] = 'Ошибка загрузки: $e';
        _tabIsLoading[tabStatus] = false;
        _tabIsLoadingMore[tabStatus] = false;
      });
      print("Error loading homeworks for tab $tabStatus: $e");
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
    await _loadCounters();
    await _loadHomeworksForTab(_currentFilterStatus);
  }

  Future<void> _loadMoreData(String tabStatus) async {
    if (_tabIsLoadingMore[tabStatus]! || !_tabHasMoreData[tabStatus]!) return;
    await _loadHomeworksForTab(tabStatus, loadMore: true);
  }

  int _getCounterByStatus(int status) {
    try {
      final counter = _counters.firstWhere(
        (c) => c.counterType == status,
        orElse: () => HomeworkCounter(counterType: status, counter: 0),
      );
      return counter.counter;
    } catch (e) {
      return 0;
    }
  }

  Color _getStatusColor(Homework homework) {
    if (homework.isDeletedStatus) return Colors.grey.shade700;
    if (homework.isExpired) return Colors.red.shade700;
    if (homework.isDone) return Colors.green.shade700;
    if (homework.isInspection) return Colors.blue.shade700;
    if (homework.isOpened) return Colors.orange.shade700;
    return Colors.grey.shade700;
  }

  String _getStatusText(Homework homework) {
    if (homework.isDeletedStatus) return 'Удалено';
    if (homework.isExpired) return 'Просрочено';
    if (homework.isDone) return 'Проверено';
    if (homework.isInspection) return 'На проверке';
    if (homework.isOpened) return 'Активно';
    return 'Неизвестно';
  }

  IconData _getStatusIcon(Homework homework) {
    if (homework.isDeletedStatus) return Icons.delete_rounded;
    if (homework.isExpired) return Icons.warning_rounded;
    if (homework.isDone) return Icons.check_circle_rounded;
    if (homework.isInspection) return Icons.hourglass_top_rounded;
    if (homework.isOpened) return Icons.assignment_rounded;
    return Icons.help_rounded;
  }

  List<Homework> _filterHomeworks(List<Homework> homeworks) {
    final currentFilter = _currentFilterStatus;
    
    List<Homework> filtered;
    
    if (currentFilter == 'all') {
      filtered = homeworks;
    } else {
      filtered = homeworks.where((hw) {
      switch (currentFilter) {
        case 'expired':
          return hw.isExpired;
        case 'done':
          return hw.isDone;
        case 'inspection':
          return hw.isInspection;
        case 'opened':
          return hw.isOpened;
        case 'deleted':
          return hw.isDeletedStatus;
        default:
          return true;
      }
    }).toList();
    }
    
    filtered.sort((a, b) {
      final priorityA = _getHomeworkPriority(a);
      final priorityB = _getHomeworkPriority(b);
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      return a.completionTime.compareTo(b.completionTime);
    });
    
    return filtered;
  }

  int _getHomeworkPriority(Homework homework) {
    if (homework.isDeletedStatus) return 0;
    if (homework.isExpired) return 1;
    if (homework.isOpened) return 2;
    if (homework.isInspection) return 3;
    if (homework.isDone) return 4;
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
    if (homework.isDeletedStatus) return 'Скачать задание (удалено)';
    if (homework.isDone) return 'Скачать задание (оценено)';
    if (homework.isInspection) return 'Скачать задание (на проверке)';
    if (homework.isExpired) return 'Скачать задание (просрочено)';
    return 'Скачать задание';
  }

  /// Получает текст для кнопки скачивания студенческой работы
  String _getStudentDownloadButtonText(Homework homework) {
    if (homework.isDeletedStatus) return 'Скачать сданную работу (удалено)';
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
                                    !homework.isInspection &&
                                    !homework.isDeletedStatus
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
                        if (homework.isDeletedStatus)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete, size: 12, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'Удалено',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
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

  Widget _buildStatsCard(List<Homework> homeworks, String tabStatus) {
    final currentTab = _tabs.firstWhere((tab) => tab['status'] == tabStatus);
    final totalCounter = tabStatus == 'deleted' 
      ? _getCounterForDeletedTab()
      : _getCounterByStatus(currentTab['counterType']);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(currentTab['icon'], size: 20, color: Colors.blue),
                SizedBox(width: 8),
            Text(
              '${currentTab['label']} задания',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Всего', totalCounter.toString(), Icons.assignment, Colors.blue),
                _buildStatItem('Найдено', homeworks.length.toString(), Icons.search, Colors.green),
                if (homeworks.isNotEmpty)
                  _buildStatItem('Страница', '${_tabCurrentPages[tabStatus]!}', Icons.numbers, Colors.orange),
              ],
            ),
            SizedBox(height: 8),
            if (totalCounter > homeworks.length)
              Text(
                'Загружено ${homeworks.length} из $totalCounter работ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
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

  Widget _buildLoadMoreIndicator(String tabStatus) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _tabIsLoadingMore[tabStatus]! 
            ? Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Загрузка следующих заданий...'),
                ],
              )
            : _tabHasMoreData[tabStatus]!
                ? TextButton(
                    onPressed: () => _loadMoreData(tabStatus),
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

  Widget _buildEmptyState(String tabStatus) {
    final currentTab = _tabs.firstWhere((tab) => tab['status'] == tabStatus);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            currentTab['icon'],
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '${currentTab['label']} отсутствуют',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            _getEmptyStateDescription(currentTab['status']),
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getEmptyStateDescription(String status) {
    switch (status) {
      case 'opened':
        return 'У вас нет активных заданий';
      case 'inspection':
        return 'Нет работ на проверке';
      case 'done':
        return 'Проверенные работы отсутствуют';
      case 'expired':
        return 'Просроченных работ нет';
      case 'deleted':
        return 'Удаленные работы отсутствуют';
      default:
        return 'Задания не найдены';
    }
  }

  Widget _buildContent(String tabStatus) {
    final currentHomeworks = _tabHomeworks[tabStatus] ?? [];
    final filteredHomeworks = _filterHomeworks(currentHomeworks);
    
    if (currentHomeworks.isEmpty && !_tabIsLoading[tabStatus]!) {
      return _buildEmptyState(tabStatus);
    }
    
    return Column(
      children: [
        _buildStatsCard(currentHomeworks, tabStatus),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo is ScrollUpdateNotification) {
                  final metrics = scrollInfo.metrics;
                  if (metrics.maxScrollExtent - metrics.pixels < 200 && 
                      !_tabIsLoadingMore[tabStatus]! && 
                      _tabHasMoreData[tabStatus]!) {
                    _loadMoreData(tabStatus);
                  }
                }
                return false;
              },
              child: ListView.builder(
                itemCount: filteredHomeworks.length + (_tabHasMoreData[tabStatus]! ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredHomeworks.length) {
                    return _buildLoadMoreIndicator(tabStatus);
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

  Widget _buildTabContent(int tabIndex) {
    String tabStatus = _tabs[tabIndex]['status'];
    if (_tabIsLoading[tabStatus]! && _tabHomeworks[tabStatus]!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка ${_tabs[tabIndex]['label'].toString().toLowerCase()}...'),
            SizedBox(height: 8),
            Text(
              '${_getCounterByStatus(_tabs[tabIndex]['counterType'])} работ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    } else if (_tabErrorMessages[tabStatus]!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _tabErrorMessages[tabStatus]!,
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadHomeworksForTab(tabStatus),
              child: Text('Повторить'),
            ),
          ],
        ),
      );
    } else if (_tabHomeworks[tabStatus]!.isEmpty) {
      return _buildEmptyState(tabStatus);
    } else {
      return _buildContent(tabStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLabWork ? 'Лабораторные работы' : 'Домашние задания'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) {
            final counter = tab['status'] == 'deleted' 
              ? _getCounterForDeletedTab() // Особый метод для удаленных
              : _getCounterByStatus(tab['counterType']);
            return Tab(
              icon: Badge(
                label: Text(counter.toString()),
                isLabelVisible: counter > 0,
                smallSize: 18,
                child: Icon(tab['icon'], size: 20),
              ),
              text: tab['label'],
            );
          }).toList(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _tabIsLoading[_currentFilterStatus]! ? null : _refreshData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.asMap().entries.map((entry) {
          return _buildTabContent(entry.key);
        }).toList(),
      ),
    );
  }
}