import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/menu_screen.dart';
import 'screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';
import 'services/settings/notification_service.dart';
import 'models/system/blue_theme.dart'; // Добавляем импорт синей темы

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();
  String _currentTheme = ThemeService.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
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

  Future<Map<String, dynamic>> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null || token.isEmpty) {
      return {'isValid': false, 'token': null};
    }
    
    final apiService = ApiService();
    final isValid = await apiService.validateToken(token);
    return {'isValid': isValid, 'token': isValid ? token : null};
  }

  // Новый метод для получения правильной темы
  ThemeData _getDarkTheme() {
    return _currentTheme == ThemeService.blue 
        ? blueTheme  // Используем синюю тему
        : ThemeData.dark(); // Стандартная темная тема
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student App',
      theme: ThemeData.light(),
      darkTheme: _getDarkTheme(), // Используем наш метод
      themeMode: _themeService.getThemeMode(_currentTheme),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && 
              snapshot.data!['isValid'] == true && 
              snapshot.data!['token'] != null) {
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService().startSmartPolling(snapshot.data!['token']!);
            });
            
            return MainMenuScreen(
              token: snapshot.data!['token']!,
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