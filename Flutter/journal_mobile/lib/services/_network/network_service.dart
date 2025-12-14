import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = true;
  
  Future<void> initialize() async {
    try {
      final initialResult = await _connectivity.checkConnectivity();
      _isConnected = initialResult != ConnectivityResult.none;
      
      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        _isConnected = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
        _connectionController.add(_isConnected);
        print(_isConnected ? '🌐 Сеть подключена' : '📶 Сеть отключена');
      });
    } catch (e) {
      print('❌ Ошибка инициализации NetworkService: $e');
    }
  }
  
  bool get isConnected => _isConnected;
  
  /// Асинхронная проверка подключения
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
      return _isConnected;
    } catch (e) {
      print('❌ Ошибка проверки подключения: $e');
      return false;
    }
  }
  
  /// Получить текущие типы подключений
  Future<List<ConnectivityResult>> getConnectionTypes() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      print('❌ Ошибка получения типов подключений: $e');
      return [];
    }
  }
  
  /// Проверить, есть ли Wi-Fi подключение
  Future<bool> hasWifiConnection() async {
    try {
      final results = await getConnectionTypes();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }
  
  /// Проверить, есть ли мобильное подключение
  Future<bool> hasMobileConnection() async {
    try {
      final results = await getConnectionTypes();
      return results.contains(ConnectivityResult.mobile);
    } catch (e) {
      return false;
    }
  }
  
  /// Проверить, есть ли подключение через Ethernet
  Future<bool> hasEthernetConnection() async {
    try {
      final results = await getConnectionTypes();
      return results.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }
  
  /// Отключение мониторинга
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _connectionController.close();
  }
}