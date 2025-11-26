import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/api_service.dart';
import 'services/background/background_worker.dart';
import 'services/theme_service.dart';
import 'services/secure_storage_service.dart';
import 'services/main_service_coordinator.dart';
import 'services/settings/notification_service.dart';

import 'models/system/blue_theme.dart';

import 'screens/login_screen.dart';
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
  final SecureStorageService _secureStorage = SecureStorageService();
  final ServiceCoordinator _serviceCoordinator = ServiceCoordinator();
  final ApiService _apiService = ApiService();
  String _currentTheme = ThemeService.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    
    BackgroundWorker.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceCoordinator.dispose();
    _apiService.dispose();
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

  Future<Map<String, dynamic>> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        return {'isValid': false, 'token': null, 'isOffline': false};
      }
      
      final hasCredentials = await _secureStorage.hasSavedCredentials();
      
      try {
        final isValid = await _apiService.validateToken(token);
        return {
          'isValid': isValid, 
          'token': isValid ? token : null, 
          'isOffline': false
        };
      } catch (e) {
        if (hasCredentials) {
          print('🌐 Ошибка онлайн проверки, но есть офлайн данные: $e');
          return {
            'isValid': true,
            'token': token, 
            'isOffline': true
          };
        } else {
          return {'isValid': false, 'token': null, 'isOffline': false};
        }
      }
    } catch (e) {
      print('Ошибка при получении токена: $e');
      return {'isValid': false, 'token': null, 'isOffline': false};
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
        future: _getToken(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!['isValid'] == true) {
            final token = snapshot.data!['token']!;
            final isOffline = snapshot.data!['isOffline'] == true;
            
            if (!isOffline) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _serviceCoordinator.startBackgroundServices(token);
                
                _serviceCoordinator.manualSync(token).catchError((e) {
                  print('Автосинхронизация не удалась: $e');
                });
              });
            }
            
            return MainMenuScreen(
              token: token,
              currentTheme: _currentTheme,
              onThemeChanged: _changeTheme,
            );
          }
          return LoginScreen(
            currentTheme: _currentTheme,
            onThemeChanged: _changeTheme,
          );
        },
      ),
    );
  }
}