import 'dart:async';
import 'api_service.dart';
import 'settings/notification_service.dart';
import 'background/background_worker.dart';

class ServiceCoordinator {
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();
  
  Timer? _syncTimer;
  bool _servicesRunning = false;
  String? _currentToken;
  
  Future<void> startBackgroundServices(String token) async {
    if (_servicesRunning) return;
    
    _servicesRunning = true;
    _currentToken = token;
    
    print('🚀 Запуск оптимизированных фоновых сервисов...');
    
    try {
      await _apiService.syncCriticalDataOnly(token);
      
      _startBackgroundSync(token);
      
      print('✅ Фоновые сервисы запущены');
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
        print('📱 Фоновая синхронизация...');
        await _apiService.syncCriticalDataOnly(token);
        
        if (timer.tick % 2 == 0) {
          await _notificationService.checkForUpdates(token);
        }
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
      print('🚀 Быстрый старт приложения...');
      return await _apiService.loadCriticalData(token);
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