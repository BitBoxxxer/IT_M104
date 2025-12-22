import 'package:flutter/material.dart';
import '../models/days_element.dart';
import '../models/mark.dart';
import '../models/user_data.dart';
import '../screens/schedule_screen.dart';
import 'data_manager.dart';

class DataProvider extends ChangeNotifier {
  final DataManager _dataManager = DataManager();
  
  List<Mark> _marks = [];
  UserData? _userData;
  List<ScheduleElement> _schedule = [];
  bool _isLoading = false;
  String? _error;
  
  List<Mark> get marks => _marks;
  UserData? get userData => _userData;
  List<ScheduleElement> get schedule => _schedule;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadInitialData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await Future.wait([
        _loadUserData(),
        _loadMarks(),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadUserData() async {
    _userData = await _dataManager.getUserData();
  }
  
  Future<void> _loadMarks() async {
    _marks = await _dataManager.getMarks();
  }
  
  Future<void> loadSchedule(DateTime start, DateTime end) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _schedule = await _dataManager.getSchedule(
        dateFrom: formatDate(start),
        dateTo: formatDate(end),
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Принудительное обновление
  Future<void> refreshData() async {
    await _dataManager.syncAllData();
    await loadInitialData();
  }
  
  /// Проверка соединения и обновление
  Future<void> checkAndUpdate() async {
    final hasOfflineData = await _dataManager.hasOfflineData();
    
    if (!hasOfflineData) {
      await refreshData();
    }
  }
}