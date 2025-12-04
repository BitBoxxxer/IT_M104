import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import 'homework.dart';
import 'homework_counter.dart';

import 'homework_content.dart';
import 'homework_tab_bar.dart';

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
            icon: Icon(Icons.refresh),
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