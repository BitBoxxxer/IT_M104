import 'dart:io';

import 'package:flutter/material.dart';
import 'package:futuristic_onboarding/futuristic_onboarding.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_initializer.dart';

import '_database/database_health_check.dart';
import '_database/sqflite_init.dart';

import 'core/bug_report/logging_service.dart';
import 'screens/login_screen.dart';
import 'services/_account/account_manager_service.dart';
import 'services/_offline_service/offline_storage_service.dart';
import 'services/api_service.dart';
import 'services/_background/background_worker.dart';
import 'services/schedule_note_service.dart';
import 'services/theme_service.dart';
import 'services/main_service_coordinator.dart';
import 'services/_notification/notification_service.dart';
import 'services/_network/network_service.dart';

import 'models/_system/futuristic_theme.dart';

import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Тест системы логирования
  final loggingService = LoggingService();
  await loggingService.initialize();
  
  // Тестовые логи при запуске
  await loggingService.logAction('APP_INIT', 'Запуск main()', extraInfo: {
    'timestamp': DateTime.now().toIso8601String(),
    'flutter_version': '3.16.0',
    'platform': Platform.operatingSystem,
  });
  
  try {
    await SqfliteInitializer.initialize();
    await loggingService.logAction('DATABASE_INIT', 'База данных инициализирована');
  } catch (e, stack) {
    await loggingService.logError('DATABASE_ERROR', 'Ошибка инициализации БД: $e', stack);
  }

   await SqfliteInitializer.initialize();
  await initializeDateFormatting('ru', null);
  final accountManager = AccountManagerService();
  
  await accountManager.migrateOldAccountIds();
  
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('Ошибка инициализации уведомлений: $e');
  }

  final appInitializer = AppInitializer();
  await appInitializer.initializeApp();
  await appInitializer.checkDataMigration();

  final noteService = ScheduleNoteService();
  await noteService.initialize();
  
  // Перепланируем все напоминания при запуске
  WidgetsBinding.instance.addPostFrameCallback((_) {
    noteService.scheduleAllReminders();
  });
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
    
  }

  Future<void> _initializeServices() async {
    try {
      await DatabaseHealthCheck.repairDatabaseIfNeeded();
      await _networkService.initialize();
      await BackgroundWorker.initialize();
      await BackgroundWorker.scheduleBackgroundSync();
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
          print('🚀 Есть активный аккаунт и ${isOnline ? 'интернет' : 'оффлайн данные'}');
          
          String? validToken;
          bool isOfflineMode = false;
          
          if (isOnline) {
            // Попытка получить валидный токен с перелогином
            print('🔄 Попытка получить валидный токен для аккаунта: ${currentAccount.username}');
            validToken = await accountManager.getValidTokenForCurrentAccount();
            
            if (validToken != null) {
              print('✅ Получен валидный токен через re-authenticate');
            } else if (hasMinimumOfflineData) {
              print('⚠️ Не удалось получить валидный токен, но есть оффлайн данные');
              isOfflineMode = true;
              validToken = currentAccount.token; // Используем старый токен для оффлайн режима
            }
          } else {
            // Нет интернета, используем оффлайн режим
            if (hasMinimumOfflineData) {
              print('📱 Нет интернета, но есть оффлайн данные');
              isOfflineMode = true;
              validToken = currentAccount.token;
            }
          }
          
          if (validToken != null) {
            return {
              'screen': 'menu',
              'token': validToken,
              'isOffline': isOfflineMode,
              'accountId': currentAccount.id
            };
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
    return futuristicTheme;
  }

  ThemeData _getLightTheme() => futuristicLightTheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'It top M',
      theme: _getLightTheme(),
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
                        'Offline режим',
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

          final Widget startScreen;
          if (screenType == 'menu' && token != null) {
            if (!isOffline) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                _serviceCoordinator.startBackgroundServices(token);
                
                Future.delayed(Duration(seconds: 2), () {
                  _serviceCoordinator.manualSync(token).catchError((e) {
                    print('Автосинхронизация не удалась: $e');
                  });
                });
              });
            } else {
              print('📱 Запуск в оффлайн режиме для аккаунта $accountId');
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                print('⚠️ Приложение работает в оффлайн режиме');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Работаем в оффлайн режиме'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }
            
            startScreen = MainMenuScreen(
              token: token,
              currentTheme: _currentTheme,
              onThemeChanged: _changeTheme,
              isOfflineMode: isOffline,
            );
          } else {
          startScreen = LoginScreen(
            currentTheme: _currentTheme,
            onThemeChanged: _changeTheme,
          );
        }
          return _OnboardingShell(child: startScreen);
        },
      ),
    );
  }
}

class _OnboardingShell extends StatefulWidget {
  const _OnboardingShell({required this.child});

  final Widget child;

  @override
  State<_OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<_OnboardingShell> {
  static const _completedKey = 'futuristic_onboarding_completed';
  final _titleKey = GlobalKey();
  final _contentKey = GlobalKey();
  bool? _isCompleted;

  List<OnboardingStep> get _steps => [
        OnboardingStep(
          targetKey: _titleKey,
          title: 'Добро пожаловать',
          description: 'Обновленный интерфейс приложения в стиле HUD и Liquid Glass.',
          highlightShape: HighlightShape.roundedRect,
          tooltipPosition: TooltipPosition.bottom,
          illustration: const Icon(Icons.auto_awesome, size: 42, color: Colors.cyan),
        ),
        OnboardingStep(
          targetKey: _contentKey,
          title: 'Все важное под рукой',
          description: 'Здесь находятся расписание, оценки, задания и настройки приложения.',
          highlightShape: HighlightShape.roundedRect,
          tooltipPosition: TooltipPosition.top,
          illustration: const Icon(Icons.dashboard_customize, size: 42, color: Colors.amber),
          skippable: false,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadCompletionState();
  }

  Future<void> _loadCompletionState() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isCompleted = preferences.getBool(_completedKey) ?? false);
    }
  }

  Future<void> _markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedKey, true);
    if (mounted) setState(() => _isCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted == null) return widget.child;

    return FuturisticOnboarding(
      key: const ValueKey('journal_futuristic_onboarding'),
      steps: _steps,
      theme: OnboardingTheme.cyberpunk,
      showParticles: true,
      enableGestures: true,
      autoStart: !_isCompleted!,
      onCompleted: _markCompleted,
      onSkipped: _markCompleted,
      child: Column(
        children: [
          SizedBox(key: _titleKey, height: 1),
          Expanded(
            child: Container(key: _contentKey, child: widget.child),
          ),
        ],
      ),
    );
  }
}