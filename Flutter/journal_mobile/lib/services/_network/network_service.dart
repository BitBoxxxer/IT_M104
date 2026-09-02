import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// ВАЖНО: раньше этот сервис ориентировался только на connectivity_plus,
/// который говорит лишь "есть ли активный сетевой интерфейс" (включен ли
/// wifi/моб. интернет и есть ли ассоциация с точкой доступа/вышкой). Это НЕ
/// означает реальный доступ в интернет — можно быть "подключенной" к wifi
/// без интернета или иметь плохой сигнал сотовой сети. Из-за этого
/// приложение считало себя online, даже когда реально работать с сетью
/// не могло, и чтобы попасть в offline-режим, приходилось вручную
/// выключать и wifi, и моб. данные.
///
/// Теперь при каждом изменении интерфейса, а также раз в [_pollInterval],
/// сервис ДОПОЛНИТЕЛЬНО делает короткий HTTP-запрос к реальному API и
/// только по его результату решает, online мы или нет.
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollingTimer;

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Срабатывает ОДИН раз в момент перехода offline -> online.
  /// На это событие подписывается DataManager/экраны, чтобы сделать
  /// "hot refresh" данных сразу, как только сеть реально появилась,
  /// а не ждать следующего ручного действия пользователя.
  final StreamController<void> _reconnectedController = StreamController<void>.broadcast();
  Stream<void> get onReconnected => _reconnectedController.stream;

  bool _isConnected = true;
  bool _checkInProgress = false;

  static const String _probeUrl = 'https://msapi.top-academy.ru/api/v2';
  static const Duration _probeTimeout = Duration(seconds: 4);
  static const Duration _pollInterval = Duration(seconds: 15);

  Future<void> initialize() async {
    try {
      await _refreshStatus();

      _subscription = _connectivity.onConnectivityChanged.listen((_) {
        _refreshStatus();
      });

      // Даже если интерфейс не менялся, реальная доступность сервера могла
      // измениться (плохой сигнал то есть, то нет) — перепроверяем регулярно.
      _pollingTimer = Timer.periodic(_pollInterval, (_) => _refreshStatus());
    } catch (e) {
      print('❌ Ошибка инициализации NetworkService: $e');
    }
  }

  Future<void> _refreshStatus() async {
    if (_checkInProgress) return;
    _checkInProgress = true;
    try {
      final interfaceResults = await _connectivity.checkConnectivity();
      final hasInterface = interfaceResults.isNotEmpty &&
          interfaceResults.any((r) => r != ConnectivityResult.none);

      final reallyConnected = hasInterface ? await _probeInternet() : false;

      final wasConnected = _isConnected;
      _isConnected = reallyConnected;
      _connectionController.add(_isConnected);

      if (!wasConnected && _isConnected) {
        print('🌐 Соединение реально восстановлено');
        _reconnectedController.add(null);
      } else if (wasConnected && !_isConnected) {
        print('📶 Нет реального доступа в сеть (интерфейс есть: $hasInterface)');
      }
    } finally {
      _checkInProgress = false;
    }
  }

  /// Короткий запрос к реальному API вместо доверия интерфейсу.
  /// Любой ответ сервера (даже 404/405) значит, что сеть реально работает —
  /// нам важно не "200 OK", а сам факт получения ответа.
  Future<bool> _probeInternet() async {
    try {
      final response = await http.head(Uri.parse(_probeUrl)).timeout(_probeTimeout);
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  bool get isConnected => _isConnected;
  
  /// Принудительная проверка прямо сейчас (например, pull-to-refresh).
  Future<bool> checkConnection() async {
    await _refreshStatus();
    return _isConnected;
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
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _connectionController.close();
    _reconnectedController.close();
  }
}