import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import 'menu_screen.dart';

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
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _checkingAutoLogin = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      // Даем небольшую задержку для лучшего UX
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

      // ПРОСТО ПЫТАЕМСЯ АВТОМАТИЧЕСКИ ВОЙТИ БЕЗ ПРОВЕРОК
      final credentials = await _secureStorage.getCredentials();
      if (credentials['username'] != null && credentials['password'] != null) {
        await _autoLogin(credentials['username']!, credentials['password']!);
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

  Future<void> _autoLogin(String username, String password) async {
    try {
      print("Attempting auto-login for user: $username");
      
      final token = await _apiService.login(username, password);
      
      if (token != null && mounted) {
        print("Auto-login successful!");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainMenuScreen(
              token: token,
              currentTheme: widget.currentTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        print("Auto-login failed: token is null");
        if (mounted) {
          setState(() {
            _checkingAutoLogin = false;
          });
        }
      }
    } catch (e) {
      print("Auto-login exception: $e");
      if (mounted) {
        setState(() {
          _checkingAutoLogin = false;
        });
        
        // Показываем ошибку только если это не сетевые проблемы
        if (!e.toString().contains('Network') && !e.toString().contains('Socket')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Автовход не удался: $e'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainMenuScreen(
              token: token,
              currentTheme: widget.currentTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
          (Route<dynamic> route) => false,
        );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сети: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
                'Автоматический вход...',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Проверка сохраненных данных',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
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
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Journal ITTOP M',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Войдите в свой аккаунт',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // логин
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: TextFormField(
                            controller: _usernameController,
                            validator: _validateUsername,
                            decoration: InputDecoration(
                              labelText: 'Логин',
                              labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline, 
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              errorStyle: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16, 
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // пароль
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline, 
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16, 
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // вход
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 210, 31, 25),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 16),

                        Text(
                          'Student Journal',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
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
    );
  }
}