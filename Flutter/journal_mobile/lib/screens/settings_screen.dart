import 'package:flutter/material.dart';
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
  late String _selectedTheme;
  bool _notificationsEnabled = true;
  bool _hasNotificationPermission = true;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() async {
    final enabled = await _notificationService.isPollingEnabled();
    final permissionStatus = await _notificationService.checkPermissionStatus();
    
    setState(() {
      _notificationsEnabled = enabled;
      _hasNotificationPermission = permissionStatus['enabled'] ?? true;
    });
  }

  void _changeTheme(String theme) {
    setState(() {
      _selectedTheme = theme;
    });
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
    await _notificationService.openAppNotificationSettings();
    
    await Future.delayed(const Duration(seconds: 1));
    _loadNotificationSettings();
  }

  Future<void> _checkPermissions() async {
    final permissionStatus = await _notificationService.checkPermissionStatus();
    final hasPermission = permissionStatus['enabled'] ?? true;
    
    setState(() {
      _hasNotificationPermission = hasPermission;
    });
    
    if (!hasPermission) {
      _showPermissionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Разрешения предоставлены ✅')),
      );
    }
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
      body: ListView(
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
                  'Темная тема с синими акцентами [ЕЩЕ В ПРОЦЕССЕ - Ди. Пока что это прост dark тема]',
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
                      'Проверить разрешения',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _checkPermissions,
                    dense: true,
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
                // (выйти из акка, смена аватарки, личных данных на аккаунте) - Ди
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
        groupValue: _selectedTheme,
        onChanged: (value) => _changeTheme(value!),
      ),
      onTap: () => _changeTheme(themeValue),
    );
  }
}