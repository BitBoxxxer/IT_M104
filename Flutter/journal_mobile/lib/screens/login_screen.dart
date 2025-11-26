import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../services/url_launcher_service.dart';
import 'menu_screen.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const LoginScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _secureStorage = SecureStorageService();
  final _urlLauncher = UrlLauncherService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _checkingAutoLogin = true;
  bool _isOfflineMode = false; // Добавляем флаг офлайн режима

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  /// Обработка открытия ссылок через сервис
  Future<void> _launchURL(String url) async {
    try {
      await _urlLauncher.launchUrl(url);
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        _showUrlDialog(url);
      }
    }
  }

  void _showUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ссылка'),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Закрыть'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ссылка скопирована')),
                );
              },
              child: Text('Копировать'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAutoLogin() async {
    try {
      // Небольшую задержку для лучшего UX - Ди
      await Future.delayed(Duration(milliseconds: 500));
      
      final hasCredentials = await _secureStorage.hasSavedCredentials();
      
      if (!hasCredentials) {
        if (mounted) {
          setState(() {
            _checkingAutoLogin = false;
          });
        }
        return;
      }

      // Получаем сохраненные учетные данные
      final credentials = await _secureStorage.getCredentials();
      if (credentials['username'] != null && credentials['password'] != null) {
        // Пытаемся получить сохраненный токен
        final token = await _secureStorage.getToken();
        
        if (token != null && token.isNotEmpty) {
          // Есть сохраненный токен - пробуем офлайн вход
          await _offlineAutoLogin(token, credentials['username']!);
        } else {
          // Нет токена, пробуем онлайн вход
          await _onlineAutoLogin(credentials['username']!, credentials['password']!);
        }
      } else {
        if (mounted) {
          setState(() {
            _checkingAutoLogin = false;
          });
        }
      }
    } catch (e) {
      print("Auto-login error: $e");
      if (mounted) {
        setState(() {
          _checkingAutoLogin = false;
        });
      }
    }
  }

  Future<void> _onlineAutoLogin(String username, String password) async {
    try {
      print("Attempting online auto-login for user: $username");
      
      final token = await _apiService.login(username, password);
      
      if (token != null && mounted) {
        print("Online auto-login successful!");
        _navigateToMainMenu(token, isOffline: false);
      } else {
        print("Online auto-login failed: token is null");
        if (mounted) {
          setState(() {
            _checkingAutoLogin = false;
          });
        }
      }
    } catch (e) {
      print("Online auto-login exception: $e");
      
      // Если онлайн не удалось, пробуем офлайн с сохраненным токеном
      final savedToken = await _secureStorage.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        print("Trying offline auto-login with saved token");
        await _offlineAutoLogin(savedToken, username);
      } else {
        if (mounted) {
          setState(() {
            _checkingAutoLogin = false;
          });
        }
      }
    }
  }

  Future<void> _offlineAutoLogin(String token, String username) async {
    try {
      print("Attempting offline auto-login for user: $username");
      
      // В офлайн режиме просто используем сохраненный токен
      if (mounted) {
        setState(() {
          _isOfflineMode = true;
        });
        
        _navigateToMainMenu(token, isOffline: true);
      }
    } catch (e) {
      print("Offline auto-login exception: $e");
      if (mounted) {
        setState(() {
          _checkingAutoLogin = false;
        });
      }
    }
  }

  void _navigateToMainMenu(String token, {bool isOffline = false}) {
    if (mounted) {
      // Добавляем метку офлайн режима к токену для передачи в MainMenuScreen
      final tokenWithOfflineFlag = isOffline ? '$token?offline=true' : token;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainMenuScreen(
            token: tokenWithOfflineFlag,
            currentTheme: widget.currentTheme,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      
      final token = await _apiService.login(username, password);

      if (token != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Синхронизация данных для офлайн режима...'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );

      _apiService.syncAllData(token).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Все данные сохранены для офлайн использования ✅'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }).catchError((e) {
        print('Ошибка синхронизации: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Синхронизация завершена с ошибками ⚠️'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

        _navigateToMainMenu(token, isOffline: false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Неверный логин или пароль'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("Manual login error: $e");
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Network') ||
          e.toString().contains('host lookup')) {
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Проблемы с интернетом. Проверьте подключение.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка входа: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите логин';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    return null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAutoLogin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                _isOfflineMode ? 'Офлайн вход...' : 'Автоматический вход...',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _isOfflineMode 
                  ? 'Используются сохраненные данные'
                  : 'Проверка сохраненных данных',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (_isOfflineMode) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Офлайн режим',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
          
        SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Journal ITTOP M',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Войдите в свой аккаунт',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),

                Expanded(
                  flex: 3,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // логин
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: TextFormField(
                            controller: _usernameController,
                            validator: _validateUsername,
                            decoration: InputDecoration(
                              labelText: 'Логин',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline, 
                                color: Colors.white.withOpacity(0.8),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              errorStyle: TextStyle(
                                color: Colors.orange[300],
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.white,
                            ),
                            cursorColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // пароль
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline, 
                                color: Colors.white.withOpacity(0.8),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              errorStyle: TextStyle(
                                color: Colors.orange[300],
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.white,
                            ),
                            cursorColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Student Journal',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Spacer(),

                        // вход
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Войти',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        
                        Spacer(),
                        
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              Text(
                                'Соц. сети разработчиков:',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () => _launchURL('https://t.me/ImKaseyFuck'),
                                        icon: Icon(Icons.telegram, size: 28),
                                        color: Colors.white,
                                        tooltip: 'Telegram',
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Telegram',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () => _launchURL('https://github.com/BitBoxxxer/Journal_Mobile'),
                                        icon: Icon(Icons.castle, size: 28),
                                        color: Colors.white,
                                        tooltip: 'GitHub',
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'GitHub',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}