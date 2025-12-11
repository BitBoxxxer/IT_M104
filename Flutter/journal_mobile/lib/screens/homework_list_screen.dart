import 'package:flutter/material.dart';

import '../services/api_service.dart';

import '../models/_widgets/homework/homework_content.dart';
import '../models/_widgets/homework/homework_tab_bar.dart';
import '../models/_widgets/homework/homework.dart';
import '../models/_widgets/homework/homework_counter.dart';

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

  final Map<String, List<Homework>> _tabHomeworks = {};
  final Map<String, int> _tabCurrentPages = {};
  final Map<String, bool> _tabHasMoreData = {};
  final Map<String, bool> _tabIsLoading = {};
  final Map<String, bool> _tabIsLoadingMore = {};
  final Map<String, String> _tabErrorMessages = {};

  List<HomeworkCounter> _counters = [];

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
    _initializeTabStates();
    _tabController.addListener(_handleTabSelection);
    _loadCounters();
    
    String initialStatus = _tabs[_currentTabIndex]['status'];
    _loadHomeworksForTab(initialStatus);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeTabStates() {
    for (var tab in _tabs) {
      String status = tab['status'];
      _tabHomeworks[status] = [];
      _tabCurrentPages[status] = 1;
      _tabHasMoreData[status] = true;
      _tabIsLoading[status] = false;
      _tabIsLoadingMore[status] = false;
      _tabErrorMessages[status] = '';
    }
  }

  void _handleTabSelection() {
    if (_tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      
      String newTabStatus = _tabs[_currentTabIndex]['status'];
      _loadCounters();

      if (newTabStatus == 'deleted') {
        _loadCounters();
      }
      _loadCounters();
      
      if (_tabHomeworks[newTabStatus]!.isEmpty && 
          !_tabIsLoading[newTabStatus]! && 
          _tabErrorMessages[newTabStatus]!.isEmpty) {
        _loadHomeworksForTab(newTabStatus);
      }
    }
  }

  String get _currentFilterStatus => _tabs[_currentTabIndex]['status'];

  Future<void> _loadHomeworksForTab(String tabStatus, {bool loadMore = false}) async {
    try {
      _setLoadingState(tabStatus, loadMore);
      
      final type = widget.isLabWork ? 1 : 0;
      final statusParam = _getStatusParam(tabStatus);

      await Future.delayed(const Duration(milliseconds: 300));

      final homeworks = await _apiService.getHomeworks(
        widget.token, 
        type: type,
        page: _tabCurrentPages[tabStatus]!,
        status: statusParam,
      );

      _updateHomeworksState(tabStatus, homeworks, loadMore);
    } catch (e) {
      _setErrorState(tabStatus, e.toString());
    }
  }

  Future<void> _loadCounters() async {
    try {
      final type = widget.isLabWork ? 1 : 0;
      final counters = await _apiService.getHomeworkCounters(widget.token, type: type);
      setState(() {
        _counters = counters;
        
        final currentTabStatus = _tabs[_currentTabIndex]['status'];
        final currentLoaded = _tabHomeworks[currentTabStatus]?.length ?? 0;
        final totalCount = _getTotalCountByStatus(currentTabStatus);
        
        _tabHasMoreData[currentTabStatus] = currentLoaded < totalCount;
        
        print('📊 Счетчики обновлены: $currentTabStatus - загружено $currentLoaded из $totalCount, hasMore: ${_tabHasMoreData[currentTabStatus]}');
      });
    } catch (e) {
      print("Error loading counters: $e");
      setState(() {
        _counters = [];
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadCounters();

    setState(() {
      _tabCurrentPages[_currentFilterStatus] = 1;
    });

    await _loadHomeworksForTab(_currentFilterStatus);
  }

  Future<void> _loadMoreData(String tabStatus) async {
    print('🔄 loadMoreData для $tabStatus, currentPage: ${_tabCurrentPages[tabStatus]}, hasMore: ${_tabHasMoreData[tabStatus]}, isLoadingMore: ${_tabIsLoadingMore[tabStatus]}');
    
    final currentTotal = _tabHomeworks[tabStatus]?.length ?? 0;
    final totalCountByStatus = _getTotalCountByStatus(tabStatus);
    
    if (_tabIsLoadingMore[tabStatus]! || 
        _tabIsLoading[tabStatus]! ||
        !_tabHasMoreData[tabStatus]! ||
        currentTotal >= totalCountByStatus) {
      print('❌ Загрузка не требуется: currentTotal=$currentTotal, totalCount=$totalCountByStatus, hasMore=${_tabHasMoreData[tabStatus]}, isLoadingMore=${_tabIsLoadingMore[tabStatus]}');
      return;
    }
    
    setState(() {
      _tabCurrentPages[tabStatus] = _tabCurrentPages[tabStatus]! + 1;
      _tabIsLoadingMore[tabStatus] = true;
    });
    
    print('📊 Увеличен номер страницы перед запросом: ${_tabCurrentPages[tabStatus]}');
    
    try {
      await _loadHomeworksForTab(tabStatus, loadMore: true);
    } catch (e) {
      setState(() {
        _tabCurrentPages[tabStatus] = _tabCurrentPages[tabStatus]! - 1;
        _tabIsLoadingMore[tabStatus] = false;
        _tabErrorMessages[tabStatus] = 'Ошибка загрузки: $e';
      });
      print('❌ Ошибка при загрузке данных: $e');
    }
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

  int _getCounterForDeletedTab() {
    try {
      final counter = _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_DELETED);
      if (counter > 0) return counter;
      
      final deletedHomeworks = _tabHomeworks['deleted'] ?? [];
      return deletedHomeworks.isNotEmpty ? deletedHomeworks.length : 0;
    } catch (e) {
      return 0;
    }
  }

  // Вспомогательные методы
  void _setLoadingState(String tabStatus, bool loadMore) {
    setState(() {
      if (!loadMore) {
        _tabIsLoading[tabStatus] = true;
        _tabErrorMessages[tabStatus] = '';
        _tabHasMoreData[tabStatus] = true;
      } else {
        _tabIsLoadingMore[tabStatus] = true;
      }
    });
  }

  void _updateHomeworksState(String tabStatus, List<Homework> homeworks, bool loadMore) {
    setState(() {
      final totalCountByStatus = _getTotalCountByStatus(tabStatus);
      
      if (!loadMore) {
        _tabHomeworks[tabStatus] = homeworks;
        _tabCurrentPages[tabStatus] = 1;
        
        final loadedCount = homeworks.length;
        final totalCount = totalCountByStatus;
        
        _tabHasMoreData[tabStatus] = loadedCount < totalCount;
        print('📊 Первая загрузка $tabStatus: $loadedCount из $totalCount заданий, hasMore: ${_tabHasMoreData[tabStatus]} (loaded < total: $loadedCount < $totalCount)');
      } else {
        final existingIds = _tabHomeworks[tabStatus]!.map((h) => h.id).toSet();
        final uniqueNewHomeworks = homeworks.where((h) => !existingIds.contains(h.id)).toList();
        
        if (uniqueNewHomeworks.isNotEmpty) {
          _tabHomeworks[tabStatus]!.addAll(uniqueNewHomeworks);
          print('📊 Добавлено ${uniqueNewHomeworks.length} уникальных заданий');
        }
        
        final totalLoaded = _tabHomeworks[tabStatus]!.length;
        final totalCount = totalCountByStatus;
        
        _tabHasMoreData[tabStatus] = totalLoaded < totalCount;
        
        if (_tabHasMoreData[tabStatus]!) {
          _tabCurrentPages[tabStatus] = _tabCurrentPages[tabStatus]! + 1;
          print('📊 Увеличена страница на 1, теперь: ${_tabCurrentPages[tabStatus]}');
        } else {
          print('📊 Все задания загружены: $totalLoaded из $totalCount, пагинация не нужна');
        }
      }
      
      _tabIsLoading[tabStatus] = false;
      _tabIsLoadingMore[tabStatus] = false;
      
      print('📊 Итог $tabStatus: всего ${_tabHomeworks[tabStatus]!.length} заданий, hasMore: ${_tabHasMoreData[tabStatus]}, page: ${_tabCurrentPages[tabStatus]}');
    });
  }

  void _setErrorState(String tabStatus, String error) {
    setState(() {
      _tabErrorMessages[tabStatus] = 'Ошибка загрузки: $error';
      _tabIsLoading[tabStatus] = false;
      _tabIsLoadingMore[tabStatus] = false;
    });
  }

  int? _getStatusParam(String tabStatus) {
    switch (tabStatus) {
      case 'expired': return 0;
      case 'done': return 1;
      case 'inspection': return 2;
      case 'opened': return 3;
      case 'deleted': return 5;
      default: return null;
    }
  }

  int _getTotalCountByStatus(String tabStatus) {
    switch (tabStatus) {
      case 'opened':
        return _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_OPENED);
      case 'inspection':
        return _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_INSPECTION);
      case 'done':
        return _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_DONE);
      case 'expired':
        return _getCounterByStatus(HomeworkCounter.HOMEWORK_STATUS_EXPIRED);
      case 'deleted':
        return _getCounterForDeletedTab();
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLabWork ? 'Лабораторные работы' : 'Домашние задания'),
        bottom: HomeworkTabBar(
          tabController: _tabController,
          tabs: _tabs,
          getCounterByStatus: _getCounterByStatus,
          getCounterForDeletedTab: _getCounterForDeletedTab,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _tabIsLoading[_currentFilterStatus]! ? null : _refreshData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.asMap().entries.map((entry) {
          final tabIndex = entry.key;
          final tabStatus = entry.value['status'];
          
          return HomeworkContent(
            tabStatus: tabStatus,
            homeworks: _tabHomeworks[tabStatus] ?? [],
            isLoading: _tabIsLoading[tabStatus]!,
            isLoadingMore: _tabIsLoadingMore[tabStatus]!,
            hasMoreData: _tabHasMoreData[tabStatus]!,
            errorMessage: _tabErrorMessages[tabStatus]!,
            currentPage: _tabCurrentPages[tabStatus]!,
            getCounterByStatus: _getCounterByStatus,
            getCounterForDeletedTab: _getCounterForDeletedTab,
            onRefresh: _refreshData,
            onLoadMore: () => _loadMoreData(tabStatus),
            tabData: _tabs[tabIndex],
          );
        }).toList(),
      ),
    );
  }
}