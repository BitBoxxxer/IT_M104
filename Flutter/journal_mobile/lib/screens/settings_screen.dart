import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/theme_service.dart';
import '../services/settings/notification_service.dart';

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
              _openNotificationSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotificationSettings() async {
    try {
      print('Пытаемся открыть настройки уведомлений...');
      await _notificationService.openAppNotificationSettings();
      
      // Ждем немного и проверяем обновились ли разрешения
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
    await _openNotificationSettings();
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
                if (!_hasNotificationPermission) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings, size: 20),
                    title: const Text(
                      'Настроить разрешения',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Открыть настройки устройства'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _checkPermissions,
                  ),
                ],
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
}