import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/theme_service.dart';
import '../services/_settings/notification_service.dart';
import '../services/offline_storage_service.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedTheme;
  bool _notificationsEnabled = true;
  bool _hasNotificationPermission = true;
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadThemeFromStorage();
    await _loadNotificationSettings();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadThemeFromStorage() async {
    try {
      final savedTheme = await _secureStorage.read(key: 'selected_theme');
      
      final themeToUse = savedTheme ?? widget.currentTheme;
      
      setState(() {
        _selectedTheme = themeToUse;
      });
      
      if (savedTheme != null && savedTheme != widget.currentTheme) {
        widget.onThemeChanged(savedTheme);
      }
    } catch (e) {
      print('Ошибка загрузки темы из secure_storage: $e');
      setState(() {
        _selectedTheme = widget.currentTheme;
      });
    }
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTheme != widget.currentTheme && _selectedTheme != null) {
      setState(() {
        _selectedTheme = widget.currentTheme;
      });
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final enabled = await _notificationService.isPollingEnabled();
      final permissionStatus = await _notificationService.checkPermissionStatus();
      
      setState(() {
        _notificationsEnabled = enabled;
        _hasNotificationPermission = permissionStatus['enabled'] ?? true;
      });
    } catch (e) {
      print('Ошибка загрузки настроек уведомлений: $e');
    }
  }

  Future<void> _changeTheme(String theme) async {
    setState(() {
      _selectedTheme = theme;
    });
    try {
      await _secureStorage.write(key: 'selected_theme', value: theme);
    } catch (e) {
      print('Ошибка сохранения темы в secure_storage: $e');
    }
    widget.onThemeChanged(theme);
  }

  void _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _notificationService.setPollingEnabled(value);
    
    if (value) {
      final permissionStatus = await _notificationService.checkPermissionStatus();
      final hasPermission = permissionStatus['enabled'] ?? true;
      
      if (!hasPermission) {
        _showPermissionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Уведомления включены')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Уведомления выключены')),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разрешение уведомлений'),
        content: const Text(
          'Для работы уведомлений необходимо предоставить разрешение. '
          'Хотите открыть настройки и включить уведомления для этого приложения?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openNotificationSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  Future<void> openNotificationSettings() async {
    try {
      print('Открываем настройки уведомлений...');
      
      await _notificationService.openAppNotificationSettings();
      await Future.delayed(const Duration(seconds: 3));
      await _loadNotificationSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вернитесь в приложение после настройки разрешений'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Ошибка открытия настроек уведомлений: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть настройки. Попробуйте позже.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _checkPermissions() async {
    await openNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading || _selectedTheme == null
    ? const Center(child: CircularProgressIndicator())
    : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Внешний вид',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _buildThemeOption(
                  'Системная',
                  'Следует системным настройкам',
                  Icons.phone_android,
                  ThemeService.system,
                ),
                _buildThemeOption(
                  'Светлая', 
                  'Яркая светлая тема',
                  Icons.light_mode,
                  ThemeService.light,
                ),
                _buildThemeOption(
                  'Темная',
                  'Темная тема (по умолчанию)',
                  Icons.dark_mode,
                  ThemeService.dark,
                ),
                _buildThemeOption(
                  'Синяя',
                  'Темная тема с синими акцентами',
                  Icons.color_lens,
                  ThemeService.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Другие настройки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: _hasNotificationPermission ? Colors.green : Colors.orange,
                  ),
                  title: const Text('Уведомления'),
                  subtitle: _hasNotificationPermission 
                      ? const Text('Разрешения предоставлены ✅')
                      : const Text('Требуется разрешение для работы ⚠️'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: _hasNotificationPermission ? Colors.green : Colors.orange,
                    onChanged: _toggleNotifications,
                  ),
                ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings, size: 20),
                    title: const Text(
                      'Настроить разрешения',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Открыть настройки уведомлений приложения'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _checkPermissions,
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Безопасность'),
              subtitle: const Text('Настройки аккаунта'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // (выйти из акка, смена аватарки, личных данных на аккаунте)
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Помощь и поддержка'),
              subtitle: const Text('Частые вопросы и контакты'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Перейти к разделу помощи
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Разработчики приложения'),
              subtitle: const Text('Связаться'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Ссылка на GITHUB репозиторий и т.д.
              },
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.storage, color: Colors.blue),
                  title: Text('Офлайн данные'),
                  subtitle: Text('Управление локально сохраненными данными'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.download, color: Colors.green),
                  title: Text('Синхронизировать сейчас'),
                  subtitle: Text('Обновить все данные для офлайн использования'),
                  trailing: Icon(Icons.sync),
                  onTap: () async {
                    final shouldSync = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Синхронизация данных'),
                        content: Text('Это может занять некоторое время. Хотите продолжить?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Синхронизировать'),
                          ),
                        ],
                      ),
                    );
                    
                    if (shouldSync == true) {
                      _syncOfflineData();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.storage, color: Colors.orange),
                  title: Text('Статистика данных'),
                  subtitle: FutureBuilder<Map<String, int>>(
                    future: _getOfflineStats(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final stats = snapshot.data!;
                        return Text(
                          'Оценки: ${stats['marks'] ?? 0}, Пользователь: ${stats['user'] ?? 0}, Расписание: ${stats['schedule'] ?? 0}',
                          maxLines: 2,
                        );
                      }
                      return Text('Загрузка...');
                    },
                  ),
                  trailing: Icon(Icons.analytics),
                  onTap: () {
                    _showOfflineStats();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Очистить офлайн данные'),
                  subtitle: Text('Удалить все локально сохраненные данные'),
                  trailing: Icon(Icons.clean_hands),
                  onTap: () {
                    _clearOfflineData();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, String subtitle, IconData icon, String themeValue) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Radio<String>(
        value: themeValue,
        groupValue: _selectedTheme!,
        onChanged: (value) => _changeTheme(value!),
      ),
      onTap: () => _changeTheme(themeValue),
    );
  }

  Future<Map<String, int>> _getOfflineStats() async {
    final offlineStorage = OfflineStorageService();
    return await offlineStorage.getOfflineDataStats();
  }

  void _showOfflineStats() async {
    final stats = await _getOfflineStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Статистика офлайн данных'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('👤 Данные пользователя', stats['user'] == 1 ? 'Есть' : 'Нет'),
              _buildStatItem('📊 Оценки', '${stats['marks'] ?? 0} записей'),
              _buildStatItem('📅 Расписание', '${stats['schedule'] ?? 0} пар'),
              _buildStatItem('🎯 Активности', '${stats['activities'] ?? 0} записей'),
              _buildStatItem('📝 Экзамены', '${stats['exams'] ?? 0} записей'),
              _buildStatItem('💬 Отзывы', '${stats['feedbacks'] ?? 0} записей'),
              _buildStatItem('📚 Домашние задания', '${stats['homeworks'] ?? 0} шт'),
              _buildStatItem('🏆 Лидеры группы', '${stats['groupLeaders'] ?? 0} чел'),
              _buildStatItem('🚀 Лидеры потока', '${stats['streamLeaders'] ?? 0} чел'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _syncOfflineData() async {
    try {
      final secureStorage = SecureStorageService();
      final token = await secureStorage.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Требуется авторизация'), backgroundColor: Colors.red),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Синхронизация данных...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 5),
        ),
      );
      
      final apiService = ApiService();
      await apiService.syncAllData(token);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Данные синхронизированы для офлайн использования ✅'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {});
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка синхронизации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearOfflineData() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистка офлайн данных'),
        content: Text('Все локально сохраненные данные будут удалены. Это действие нельзя отменить. Продолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (shouldClear == true) {
      try {
        final offlineStorage = OfflineStorageService();
        await offlineStorage.clearAllOfflineData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Офлайн данные очищены'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {});
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка очистки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}