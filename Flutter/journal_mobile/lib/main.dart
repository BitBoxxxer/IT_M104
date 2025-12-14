import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/login_screen.dart';
import 'services/_account/account_manager_service.dart';
import 'services/_offline_service/offline_storage_service.dart';
import 'services/api_service.dart';
import 'services/_background/background_worker.dart';
import 'services/theme_service.dart';
import 'services/main_service_coordinator.dart';
import 'services/_notification/notification_service.dart';
import 'services/_network/network_service.dart';

import 'models/_system/blue_theme.dart';

import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('Ошибка инициализации уведомлений: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ThemeService _themeService = ThemeService();
  final ServiceCoordinator _serviceCoordinator = ServiceCoordinator();
  final ApiService _apiService = ApiService();
  final NetworkService _networkService = NetworkService();
  String _currentTheme = ThemeService.dark;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    
    BackgroundWorker.initialize();
  }

  Future<void> _initializeServices() async {
    try {
      await _networkService.initialize();
      await _loadTheme();
    } catch (e) {
      print('Ошибка инициализации сервисов: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceCoordinator.dispose();
    _apiService.dispose();
    _networkService.dispose();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final theme = await _themeService.getTheme();
    setState(() {
      _currentTheme = theme;
    });
  }

  void _changeTheme(String newTheme) async {
    await _themeService.saveTheme(newTheme);
    setState(() {
      _currentTheme = newTheme;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 Приложение активно - восстанавливаем сервисы');
        _serviceCoordinator.onAppResumed();
        break;
      case AppLifecycleState.inactive:
        print('📱 Приложение неактивно');
        break;
      case AppLifecycleState.paused:
        print('📱 Приложение в фоне - оптимизируем сервисы');
        _serviceCoordinator.onAppPaused();
        break;
      case AppLifecycleState.detached:
        print('📱 Приложение закрыто');
        _serviceCoordinator.stopBackgroundServices();
        break;
      case AppLifecycleState.hidden:
        print('📱 Приложение скрыто');
        _serviceCoordinator.onAppPaused();
        break;
    }
  }

  Future<Map<String, dynamic>> _getInitialScreen() async {
    try {
      if (!_isInitialized) {
        await Future.delayed(Duration(milliseconds: 500));
      }

      final accountManager = AccountManagerService();
      await accountManager.fixMultipleActiveAccounts();

      final currentAccount = await accountManager.getCurrentAccount();
      
      if (currentAccount != null) {
        final bool hasMinimumOfflineData = await _checkOfflineDataAvailable(currentAccount.id);
        final bool isOnline = _networkService.isConnected;
        
        if (hasMinimumOfflineData || isOnline) {
          print('🚀 Есть активный аккаунт и ${isOnline ? 'интернет' : 'оффлайн данные'} - запускаем меню');
          
          if (isOnline) {
            // валидность токена онлайн
            try {
              final isValid = await _apiService.validateToken(currentAccount.token);
              if (isValid) {
                return {
                  'screen': 'menu',
                  'token': currentAccount.token,
                  'isOffline': false,
                  'accountId': currentAccount.id
                };
              } else {
                // Токен невалиден, но есть оффлайн данные
                if (hasMinimumOfflineData) {
                  print('⚠️ Токен невалиден, но есть оффлайн данные - запускаем в оффлайн режиме');
                  return {
                    'screen': 'menu',
                    'token': currentAccount.token,
                    'isOffline': true,
                    'accountId': currentAccount.id
                  };
                }
              }
            } catch (e) {
              // Ошибка проверки токена, но есть оффлайн данные
              if (hasMinimumOfflineData) {
                print('⚠️ Ошибка проверки токена, но есть оффлайн данные - запускаем в оффлайн режиме');
                return {
                  'screen': 'menu',
                  'token': currentAccount.token,
                  'isOffline': true,
                  'accountId': currentAccount.id
                };
              }
            }
          } else {
            // Нет интернета, но есть оффлайн данные
            if (hasMinimumOfflineData) {
              print('📱 Нет интернета, но есть оффлайн данные - запускаем в оффлайн режиме');
              return {
                'screen': 'menu',
                'token': currentAccount.token,
                'isOffline': true,
                'accountId': currentAccount.id
              };
            }
          }
        }
      }
      
      print('🎯 Нет условий для запуска меню - показываем логин');
      return {
        'screen': 'login',
        'token': null,
        'isOffline': false,
        'accountId': null
      };
      
    } catch (e) {
      print('❌ Ошибка при определении начального экрана: $e');
      return {
        'screen': 'login',
        'token': null,
        'isOffline': false,
        'accountId': null
      };
    }
  }

  /// Метод для проверки наличия оффлайн данных
  Future<bool> _checkOfflineDataAvailable(String accountId) async {
    try {
      final offlineStorage = OfflineStorageService();
      final stats = await offlineStorage.getOfflineDataStats();
      
      final hasUserData = stats['user'] != null && stats['user']! > 0;
      final hasMarks = stats['marks'] != null && stats['marks']! > 0;
      final hasSchedule = stats['schedule'] != null && stats['schedule']! > 0;
      
      final hasMinimumData = hasUserData && hasMarks;
      
      print('📱 Проверка оффлайн данных для аккаунта $accountId:');
      print('   - Есть данные пользователя: $hasUserData');
      print('   - Есть оценки: $hasMarks');
      print('   - Есть расписание: $hasSchedule');
      print('   - Достаточно данных для оффлайн режима: $hasMinimumData');
      
      return hasMinimumData;
    } catch (e) {
      print('❌ Ошибка проверки оффлайн данных: $e');
      return false;
      }
    }

  ThemeData _getDarkTheme() {
    return _currentTheme == ThemeService.blue 
        ? blueTheme
        : ThemeData.dark();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'It top M',
      theme: ThemeData.light(),
      darkTheme: _getDarkTheme(),
      themeMode: _themeService.getThemeMode(_currentTheme),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (!_isInitialized || snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Загрузка приложения...'),
                    if (!_networkService.isConnected)
                      Text(
                        'Офлайн режим',
                        style: TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 20),
                    Text('Ошибка загрузки'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isInitialized = false;
                        });
                        _initializeServices();
                      },
                      child: Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final screenType = data['screen'] ?? 'login';
          final token = data['token'];
          final isOffline = data['isOffline'] == true;
          final accountId = data['accountId'];

          if (screenType == 'menu' && token != null) {
            if (!isOffline) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _serviceCoordinator.startBackgroundServices(token);
                
                _serviceCoordinator.manualSync(token).catchError((e) {
                  print('Автосинхронизация не удалась: $e');
                });
              });
            } else {
              print('📱 Запуск в оффлайн режиме для аккаунта $accountId');

              WidgetsBinding.instance.addPostFrameCallback((_) {
                print('⚠️ Приложение работает в оффлайн режиме');
              });
            }
            
            return MainMenuScreen(
              token: token,
              currentTheme: _currentTheme,
              onThemeChanged: _changeTheme,
              isOfflineMode: isOffline,
            );
          } else {
          return LoginScreen(
            currentTheme: _currentTheme,
            onThemeChanged: _changeTheme,
          );
        }
        },
      ),
    );
  }
}