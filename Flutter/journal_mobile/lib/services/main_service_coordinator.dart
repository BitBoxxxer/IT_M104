import 'dart:async';
import 'package:journal_mobile/services/data_manager.dart';

import 'api_service.dart';
import '_notification/notification_service.dart';

class ServiceCoordinator {
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();
  final DataManager _dataManager = DataManager();
  
  Timer? _syncTimer;
  bool _servicesRunning = false;
  String? _currentToken;
  
  Future<void> startBackgroundServices(String token) async {
    if (_servicesRunning) return;
    
    _servicesRunning = true;
    _currentToken = token;
    
    print('🚀 Запуск сервисов с SQLite...');
    
    try {
      // Проверяем и загружаем минимальные данные
      final hasData = await _dataManager.hasOfflineData();
      
      if (!hasData) {
        await _dataManager.syncAllData(background: true);
      }
      
      _startBackgroundSync(token);
      
      print('✅ Сервисы запущены (SQLite готов)');
    } catch (e) {
      print('❌ Ошибка запуска сервисов: $e');
      _servicesRunning = false;
    }
  }
  
   void _startBackgroundSync(String token) {
    _syncTimer?.cancel();
    
    _syncTimer = Timer.periodic(Duration(minutes: 30), (timer) async {
      if (!_servicesRunning) return;
      
      try {
        print('📱 Фоновая синхронизация в SQLite...');
        await _dataManager.syncAllData(background: true);
      } catch (e) {
        print('⚠️ Ошибка фоновой синхронизации: $e');
      }
    });
  }
  
  Future<void> stopBackgroundServices() async {
    if (!_servicesRunning) return;
    
    print('🛑 Останавливаем фоновые сервисы...');
    
    _syncTimer?.cancel();
    _syncTimer = null;
    
    _servicesRunning = false;
    _currentToken = null;
    
    print('✅ Фоновые сервисы остановлены');
  }
  
  Future<void> manualSync(String token) async {
    print('🔄 Принудительная ручная синхронизация...');
    await _apiService.syncAllData(token);
  }

  Future<void> quickSync(String token) async {
    print('⚡ Быстрая синхронизация...');
    await _apiService.syncCriticalDataOnly(token);
  }
  
  Future<void> onAppPaused() async {
    print('⏸️ Приложение ушло в фон');
  }
  
  Future<void> onAppResumed() async {
    print('▶️ Приложение вернулось');
    if (_currentToken != null && _servicesRunning) {
      _apiService.syncCriticalDataOnly(_currentToken!);
    }
  }

  /// Метод для быстрого старта приложения с приоритетом оффлайн данных
  Future<Map<String, dynamic>> quickStart(String token) async {
    try {
      print('🚀 Быстрый старт с SQLite...');
      
      // 1. Пробуем получить данные из SQLite
      final hasData = await _dataManager.hasOfflineData();
      
      if (hasData) {
        print('📱 Используем данные из SQLite для быстрого старта');
        
        final userData = await _dataManager.getUserData();
        final marks = await _dataManager.getMarks();
        
        return {
          'user': userData,
          'marks': marks,
          'source': 'offline',
        };
      }
      
      // 2. Если данных нет, загружаем из сети
      print('🌐 Загружаем данные из сети...');
      
      await _dataManager.syncAllData(background: true);
      
      final userData = await _dataManager.getUserData();
      final marks = await _dataManager.getMarks();
      
      return {
        'user': userData,
        'marks': marks,
        'source': 'online',
      };
    } catch (e) {
      print('❌ Ошибка быстрого старта: $e');
      rethrow;
    }
  }
  
  Future<void> restartBackgroundServices(String token) async {
    await stopBackgroundServices();
    await Future.delayed(Duration(seconds: 1));
    await startBackgroundServices(token);
  }
  
  bool get areServicesRunning => _servicesRunning;
  
  void dispose() {
    stopBackgroundServices();
    _apiService.dispose();
    _notificationService.dispose();
  }
}