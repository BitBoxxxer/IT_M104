import 'package:flutter/material.dart';

import '../../services/_account/account_manager_service.dart';
import '../../services/_account/account_auth_service.dart';
import '../../services/api_service.dart';

import '../login_screen.dart';
import '../menu_screen.dart';

import '../../models/_system/account_model.dart';

class AccountSelectionScreen extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const AccountSelectionScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<AccountSelectionScreen> createState() => _AccountSelectionScreenState();
}

class _AccountSelectionScreenState extends State<AccountSelectionScreen> {
  final AccountManagerService _accountManager = AccountManagerService();
  final AccountAuthService _accountAuthService = AccountAuthService();

  late Future<List<Account>> _accountsFuture;
  bool _isLoading = false;
  String? _switchingAccountId;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _accountManager.getAllAccounts();
  }

  Future<void> _refreshAccounts() async {
    setState(() {
      _accountsFuture = _accountManager.getAllAccounts();
    });
  }

  Future<void> _switchAccount(Account account) async {
    if (account.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Этот аккаунт уже активен'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    setState(() {
      _switchingAccountId = account.id;
    });

    try {
      print('🔄 Начинаем переключение на: ${account.username}');
      
      // 1. Получаем валидный токен (с перелогином если нужно)
      final validToken = await _accountAuthService.getValidTokenForAccount(account.id);
      
      print('✅ Получен валидный токен: ${validToken.substring(0, 20)}...');
      
      // 2. Переключаем аккаунт в менеджере
      await _accountManager.switchAccount(account.id);
      
      // 3. Получаем свежие данные пользователя с новым токеном
      final apiService = ApiService();
      final userData = await apiService.getUser(validToken);
      
      // 4. Обновляем аккаунт с новыми данными
      final updatedAccount = account.copyWith(
        token: validToken,
        fullName: userData.fullName,
        groupName: userData.groupName,
        photoPath: userData.photoPath,
        studentId: userData.studentId,
        lastLogin: DateTime.now(),
        isActive: true,
      );
      
      await _accountManager.updateAccount(updatedAccount);
      
      print('🎯 Переключение завершено, переходим в меню...');
      
      // 5. Переходим в главное меню
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainMenuScreen(
              token: validToken,
              currentTheme: widget.currentTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
      
    } catch (e) {
      print('❌ Ошибка переключения аккаунта: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка переключения: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Обновляем список
        await _refreshAccounts();
      }
    } finally {
      if (mounted) {
        setState(() {
          _switchingAccountId = null;
        });
      }
    }
  }

  Future<void> _deleteAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить аккаунт?'),
        content: Text('Вы уверены, что хотите удалить аккаунт ${account.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _accountManager.removeAccount(account.id);
        await _refreshAccounts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Аккаунт удален'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAccountCard(Account account, BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: account.photoPath.isNotEmpty
              ? NetworkImage(account.photoPath)
              : null,
          child: account.photoPath.isEmpty
              ? Icon(Icons.person)
              : null,
        ),
        title: Text(
          account.fullName,
          style: TextStyle(
            fontWeight: account.isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Группа: ${account.groupName}'),
            Text('Логин: ${account.username}'),
            Text(
              'Последний вход: ${_formatDate(account.lastLogin)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (account.isActive)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  'Активен',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteAccount(account);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Удалить'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: account.isActive ? null : () => _switchAccount(account),
        onLongPress: () => _deleteAccount(account),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выбор аккаунта'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAccounts,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Account>>(
              future: _accountsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }
                
                final accounts = snapshot.data ?? [];
                
                return Column(
                  children: [
                    Expanded(
                      child: accounts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Нет сохраненных аккаунтов',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: accounts.length,
                              itemBuilder: (context, index) {
                                return _buildAccountCard(accounts[index], context);
                              },
                            ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.refresh, size: 18),
                              label: Text('Обновить токены всех аккаунтов'),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      
                                      try {
                                        await _accountAuthService.reauthenticateAllAccounts();
                                        await _refreshAccounts();
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Токены всех аккаунтов обновлены'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Ошибка: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.add),
                              label: Text('Добавить новый аккаунт'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LoginScreen(
                                      currentTheme: widget.currentTheme,
                                      onThemeChanged: widget.onThemeChanged,
                                      skipAutoLogin: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 8),
                          if (accounts.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.build, size: 18),
                              label: Text('Исправить активные аккаунты'),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      final accountManager = AccountManagerService();
                                      await accountManager.fixMultipleActiveAccounts();
                                      await _refreshAccounts();
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Состояние аккаунтов исправлено'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                              ),
                            ),
                          ),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Очистить все аккаунты?'),
                                      content: Text('Это действие удалит все сохраненные аккаунты. Продолжить?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text('Отмена'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text('Очистить', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirmed == true) {
                                    await _accountManager.clearAllAccounts();
                                    await _refreshAccounts();
                                  }
                                },
                                child: Text('Очистить все аккаунты'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}