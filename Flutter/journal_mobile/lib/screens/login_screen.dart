import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/_system/account_model.dart';
import '../services/_account/account_manager_service.dart';
import '../services/_network/network_service.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../services/url_launcher_service.dart';
import '../services/main_service_coordinator.dart';

import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;
  final bool skipAutoLogin;

  const LoginScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.skipAutoLogin = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();
  final _secureStorage = SecureStorageService();
  final _urlLauncher = UrlLauncherService();
  final NetworkService _networkService = NetworkService();
  final AccountManagerService _accountManager = AccountManagerService();
  final ServiceCoordinator _serviceCoordinator = ServiceCoordinator();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _checkingAutoLogin = true;
  bool _isOfflineMode = false;
  List<Account> _savedAccounts = [];
  bool _showAccountSelection = false;
  bool _loadingAccounts = true;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
    _initNetworkListener();
    if (!widget.skipAutoLogin) {
      _checkAutoLogin();
    } else {
      _checkingAutoLogin = false;
    }
  }

  void _initNetworkListener() {
    // Проверяем текущее состояние подключения
    _networkService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  /// Загрузка сохраненных аккаунтов из БД
  Future<void> _loadSavedAccounts() async {
    try {
      setState(() {
        _loadingAccounts = true;
      });
      
      final accounts = await _accountManager.getAllAccounts();
      
      if (mounted) {
        setState(() {
          _savedAccounts = accounts;
          _loadingAccounts = false;
          
          _showAccountSelection = accounts.isNotEmpty;
        });
      }
    } catch (e) {
      print("Ошибка загрузки аккаунтов: $e");
      if (mounted) {
        setState(() {
          _loadingAccounts = false;
        });
      }
    }
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
      
      String? username;
      String? password;
      String? token;
      
      try {
        final credentialsResult = await _secureStorage.getCredentials();
        username = credentialsResult['username'];
        password = credentialsResult['password'];
        token = await _secureStorage.getToken();
      } catch (e) {
        print("❌ Ошибка чтения сохраненных данных: $e");
      }
      
      final hasCredentials = username != null && password != null;
      final hasToken = token != null && token.isNotEmpty;
      
      print("Auto-login check: hasCredentials=$hasCredentials, hasToken=$hasToken");
      
      if (!hasCredentials && !hasToken) {
        if (mounted) {
          setState(() {
            _checkingAutoLogin = false;
          });
        }
        return;
      }
      if (hasCredentials) {
        await _onlineAutoLogin(username, password);
      } 
      else if (hasToken) {
        await _offlineAutoLogin(token, username ?? 'username_offline');
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
        _fallbackToOffline(username);
      }
    } catch (e) {
      print("Online auto-login exception: $e");
      _fallbackToOffline(username);
    }
  }

  Future<void> _offlineAutoLogin(String token, String username) async {
    try {
      print("Attempting offline auto-login for user: $username");
      
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

  Future<void> _fallbackToOffline(String username) async {
    try {
      final savedToken = await _secureStorage.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        print("Trying offline auto-login with saved token");
        if (mounted) {
          setState(() {
            _isOfflineMode = true;
          });
          await Future.delayed(Duration(milliseconds: 500));
          _navigateToMainMenu(savedToken, isOffline: true);
        }
      } else {
        if (mounted) {
          setState(() {
            _checkingAutoLogin = false;
          });
        }
      }
    } catch (e) {
      print("Offline fallback error: $e");
      if (mounted) {
        setState(() {
          _checkingAutoLogin = false;
        });
      }
    }
  }

  void _navigateToMainMenu(String token, {bool isOffline = false}) {
    if (mounted) {
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

  /// Вход с использованием сохраненного аккаунта
  Future<void> _loginWithAccount(Account account) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("🔄 Вход с сохраненным аккаунтом: ${account.username}");
      
      // Получаем валидный токен для аккаунта
      final token = await _getValidTokenForAccount(account);
      
      if (token != null && mounted) {
        await _accountManager.switchAccount(account.id);
        
        final updatedAccount = account.copyWith(
          token: token,
          lastLogin: DateTime.now(),
          isActive: true,
        );
        
        await _accountManager.updateAccount(updatedAccount);
        
        await _secureStorage.saveAccountData(updatedAccount);
        
        try {
          final userData = await _apiService.getUser(token);
          final accountWithUserData = updatedAccount.copyWith(
            fullName: userData.fullName,
            groupName: userData.groupName,
            photoPath: userData.photoPath,
            studentId: userData.studentId,
          );
          
          await _accountManager.updateAccount(accountWithUserData);
        } catch (e) {
          print("⚠️ Не удалось обновить данные пользователя: $e");
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Успешный вход как ${account.fullName}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        _navigateToMainMenu(token, isOffline: false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось войти. Проверьте интернет-соединение.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          final savedToken = await _secureStorage.getAccountToken(account.id);
          if (savedToken != null && savedToken.isNotEmpty) {
            final useOffline = await _showOfflineModeDialog();
            if (useOffline && mounted) {
              _navigateToMainMenu(savedToken, isOffline: true);
            }
          }
        }
      }
    } catch (e) {
      print("❌ Ошибка входа с сохраненным аккаунтом: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
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

  /// Диалог для предложения оффлайн режима
  Future<bool> _showOfflineModeDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Проблемы с подключением'),
          content: Text('Не удалось подключиться к серверу. Хотите использовать оффлайн режим с сохраненными данными?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Нет'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Да'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Получение валидного токена для аккаунта
  Future<String?> _getValidTokenForAccount(Account account) async {
    try {
      if (account.token.isNotEmpty) {
        try {
          final isValid = await _apiService.validateToken(account.token);
          if (isValid) {
            return account.token;
          } else {
            print("Токен невалиден, пробуем перелогин");
          }
        } catch (e) {
          print("Ошибка проверки токена: $e");
        }
      }
      
      // ВАЖНО: раньше здесь читали через SecureStorageService.getAccountCredentials(),
      // а сохраняются учётки через AccountManagerService.saveAccountCredentials() —
      // это ДВА РАЗНЫХ сервиса с ДВУМЯ РАЗНЫМИ схемами ключей в secure storage
      // ('username_$id'/'password_$id' vs 'acc_${id}_username'/'acc_${id}_password').
      // Из-за этого сохранённый пароль для аккаунта никогда не находился здесь —
      // всегда приходили null/null. Для основного аккаунта это не так заметно
      // (токен обновляется при обычном логине), а вот при переключении на ВТОРОЙ,
      // не так часто используемый аккаунт, когда его токен успевал протухнуть,
      // тихий перелогин по сохранённому паролю просто не мог найти пароль и
      // либо падал, либо неожиданно требовал ввести пароль заново — это и
      // выглядело как "не могу зайти во второй аккаунт". Теперь читаем через
      // тот же сервис, который их сохраняет.
      final credentials = await _accountManager.getAccountCredentials(account.id);
      final username = credentials['username'];
      final password = credentials['password'];
      
      if (username != null && password != null) {
        print("🔄 Пробуем перелогин для аккаунта: $username");
        try {
          final newToken = await _apiService.login(username, password);
          if (newToken != null) {
            print("✅ Перелогин успешен, получен новый токен");
            
            final updatedAccount = account.copyWith(token: newToken);
            await _accountManager.updateAccount(updatedAccount);
            
            await _secureStorage.saveAccountData(updatedAccount);
            
            return newToken;
          }
        } catch (e) {
          print("❌ Ошибка при перелогине: $e");
        }
      } else {
        print("⚠️ Не найдены учетные данные для аккаунта ${account.id}");
      }
      
      final generalCredentials = await _secureStorage.getCredentials();
      final generalUsername = generalCredentials['username'];
      final generalPassword = generalCredentials['password'];
      
      if (generalUsername != null && 
          generalPassword != null && 
          generalUsername == account.username) {
        print("🔄 Пробуем перелогин с общими учетными данными");
        try {
          final newToken = await _apiService.login(generalUsername, generalPassword);
          if (newToken != null) {
            print("✅ Перелогин с общими данными успешен");
            
            final updatedAccount = account.copyWith(token: newToken);
            await _accountManager.updateAccount(updatedAccount);
            
            await _secureStorage.saveAccountData(updatedAccount);
            
            return newToken;
          }
        } catch (e) {
          print("❌ Ошибка при перелогине с общими данными: $e");
        }
      }
      
      return await _requestPasswordForAccount(account);
      
    } catch (e) {
      print("Ошибка получения токена для аккаунта: $e");
      return null;
    }
  }

/// Запрос пароля у пользователя для конкретного аккаунта
Future<String?> _requestPasswordForAccount(Account account) async {
  final password = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final passwordController = TextEditingController();
      
      return AlertDialog(
        title: Text('Требуется пароль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Для входа в аккаунт ${account.fullName} введите пароль:'),
            SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.of(context).pop(passwordController.text);
              }
            },
            child: Text('Войти'),
          ),
        ],
      );
    },
  );
  
  if (password != null && password.isNotEmpty) {
    try {
      print("🔄 Пробуем вход с введенным паролем");
      final newToken = await _apiService.login(account.username, password);
      
      if (newToken != null) {
        print("✅ Вход с введенным паролем успешен");
        
        await _secureStorage.saveAccountData(
          account.copyWith(
            token: newToken,
          ),
        );
        
        return newToken;
      }
    } catch (e) {
      print("❌ Ошибка при входе с введенным паролем: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Неверный пароль'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  return null;
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
        final accountManager = AccountManagerService();
        final account = await accountManager.getCurrentAccount();
        
        if (account != null) {
          print('✅ Аккаунт найден: ${account.username} (ID: ${account.id})');
          
          final allAccounts = await accountManager.getAllAccounts();
          final duplicateAccounts = allAccounts.where((a) => a.username == username).toList();
          
          if (duplicateAccounts.length > 1) {
            print('⚠️ Обнаружены дубликаты аккаунтов: ${duplicateAccounts.length}');
            
            final newestAccount = duplicateAccounts.reduce((a, b) => 
              a.lastLogin.isAfter(b.lastLogin) ? a : b
            );
            
            for (var duplicate in duplicateAccounts) {
              if (duplicate.id != newestAccount.id) {
                print('🗑️ Удаляем дубликат: ${duplicate.username} (ID: ${duplicate.id})');
                await accountManager.removeAccount(duplicate.id);
              }
            }
            
            await accountManager.switchAccount(newestAccount.id);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Синхронизация данных для offline режима...'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );

          _apiService.syncAllData(token).then((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Все данные сохранены для offline использования ✅'),
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

          // ВАЖНО: раньше фоновые сервисы (периодическая синхронизация,
          // hot-refresh при восстановлении сети) запускались только один
          // раз при холодном старте приложения (см. main.dart). При входе
          // в другой аккаунт БЕЗ перезапуска приложения они никогда не
          // подхватывали токен нового аккаунта. Теперь перезапускаем их
          // явно с актуальным токеном сразу после успешного логина.
          _serviceCoordinator.startBackgroundServices(token);

          _navigateToMainMenu(token, isOffline: false);
        } else {
          print('❌ Аккаунт не найден после логина');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка создания аккаунта'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
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

  /// Виджет для отображения сохраненных аккаунтов
  Widget _buildAccountSelection() {
    if (_loadingAccounts) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_savedAccounts.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сохраненные аккаунты',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showAccountSelection ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showAccountSelection = !_showAccountSelection;
                  });
                },
              ),
            ],
          ),
        ),
        
        if (_showAccountSelection)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _savedAccounts.length,
              itemBuilder: (context, index) {
                final account = _savedAccounts[index];
                return _buildAccountItem(account);
              },
            ),
          ),
        
        if (_showAccountSelection)
          const SizedBox(height: 16),
      ],
    );
  }

  /// Виджет для отображения одного аккаунта
  Widget _buildAccountItem(Account account) {
  final canLogin = _isConnected || account.isActive;
  
  return Card(
    color: Colors.white.withOpacity(0.1),
    margin: EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.2),
        child: account.photoPath.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  account.photoPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      color: Colors.white,
                    );
                  },
                ),
              )
            : Icon(
                Icons.person,
                color: Colors.white,
              ),
      ),
      title: Text(
        account.fullName,
        style: TextStyle(
          color: canLogin ? Colors.white : Colors.white.withOpacity(0.5),
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${account.groupName} • ${account.username}',
        style: TextStyle(
          color: canLogin ? 
            Colors.white.withOpacity(0.7) : 
            Colors.white.withOpacity(0.3),
          fontSize: 12,
        ),
      ),
      trailing: account.isActive
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                'Активен',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                ),
              ),
            )
          : null,
      onTap: canLogin ? () {
        _loginWithAccount(account);
      } : null,
    ),
  );
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
                _isOfflineMode ? 'Offline вход...' : 'Автоматический вход...',
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
              StreamBuilder<bool>(
                stream: _networkService.connectionStream,
                initialData: _networkService.isConnected,
                builder: (context, snapshot) {
                  final isConnected = snapshot.data ?? true;
                  
                  if (!isConnected) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.wifi_off,
                        color: Colors.orange,
                        size: 20,
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
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

                    if (_savedAccounts.isNotEmpty)
                      _buildAccountSelection(),

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
                                  backgroundColor: _isConnected ? 
                                    Colors.white.withOpacity(0.2) : 
                                    Colors.grey.withOpacity(0.5),
                                  foregroundColor: _isConnected ? Colors.white : Colors.white.withOpacity(0.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: _isConnected ? 
                                        Colors.white.withOpacity(0.3) : 
                                        Colors.grey.withOpacity(0.3),
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
                                        _isConnected ? 'Войти' : 'Нет подключения',
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