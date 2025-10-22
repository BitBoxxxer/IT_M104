import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/menu_screen.dart';
import 'screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ), // TODO: пока так, настройка темы будет в будущих настройках.
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
            return MainMenuScreen(token: snapshot.data!['token']!);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}