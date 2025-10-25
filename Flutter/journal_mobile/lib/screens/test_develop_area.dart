import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/settings/notification_service.dart';

// TODO: Добавить список логинов разработчиков, чтобы не показывать этот экран в продакшн сборке.
class AreaDevelopScreen extends StatefulWidget {
  const AreaDevelopScreen({super.key});

  @override
  State<AreaDevelopScreen> createState() => _AreaDevelopScreenState();
}

class _AreaDevelopScreenState extends State<AreaDevelopScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _pollingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPollingStatus();
  }

  Future<void> _loadPollingStatus() async {
    final enabled = await _notificationService.isPollingEnabled();
    setState(() {
      _pollingEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Арена разработки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            const Text(
              'Тестовые функции:',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // УВЕДОМЛЕНИЯ
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text(
                      'Тестирование уведомлений',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _pollingEnabled ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _pollingEnabled ? Colors.green : Colors.orange,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _pollingEnabled ? Icons.play_arrow : Icons.pause,
                                color: _pollingEnabled ? Colors.green : Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _pollingEnabled ? 'Активен' : 'Приостановлен',
                                style: TextStyle(
                                  color: _pollingEnabled ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _pollingEnabled,
                          onChanged: (value) async {
                            await _notificationService.setPollingEnabled(value);
                            setState(() {
                              _pollingEnabled = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value ? 'Polling включен' : 'Polling выключен'),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Кнопки тестирования уведомлений
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.notifications, size: 18),
                          label: const Text('Тест оценок'),
                          onPressed: () async {
                            await _notificationService.showNewMarksNotification(3);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Тест уведомления оценок отправлен')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade800,
                          ),
                        ),
                        
                        ElevatedButton.icon(
                          icon: const Icon(Icons.timer, size: 18),
                          label: const Text('Тест опозданий'),
                          onPressed: () async {
                            await _notificationService.showNewMarksNotification(3);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Тест уведомления опозданий отправлен')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade100,
                            foregroundColor: Colors.orange.shade800,
                          ),
                        ),
                        
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Тест пропусков'),
                          onPressed: () async {
                            await _notificationService.showAttendanceNotification({
                              'lates': 0,
                              'absences': 1
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Тест уведомления пропусков отправлен')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.notification_important, size: 18),
                      label: const Text('Проверить систему'),
                      onPressed: () async {
                        print('🔄 Проверка системы уведомлений...');
                        
                        try {
                          // Проверяем инициализацию
                          final isInitialized = await _notificationService.isInitialized();
                          print('📱 Система инициализирована: $isInitialized');
                          
                          if (!isInitialized) {
                            print('⚠️ Переинициализируем систему...');
                            await _notificationService.initialize();
                          }

                          // Получаем полный статус системы
                          final status = await _notificationService.getNotificationStatus();
                          print('📱 Статус системы: $status');
                          
                          // Проверяем разрешения
                          final bool? granted = await _notificationService.areNotificationsEnabled();
                          print('📱 Разрешения на уведомления: $granted');
                          
                          // Проверяем активные каналы
                          final activeChannels = await _notificationService.getActiveNotificationChannels();
                          print('📱 Активные каналы: ${activeChannels?.length ?? 0}');
                          
                          if (activeChannels != null) {
                            for (final channel in activeChannels) {
                              print('   - ${channel.id}: ${channel.name}');
                            }
                          }
                          
                          await _notificationService.showTestNotification();
                          print('✅ Тестовое уведомление отправлено в систему');
                          
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Диагностика уведомлений'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('✅ Инициализирована: $isInitialized'),
                                    Text('✅ Разрешения: ${granted ?? "неизвестно"}'),
                                    Text('✅ Каналы: ${activeChannels?.length ?? 0}'),
                                    const SizedBox(height: 10),
                                    const Text('Тестовое уведомление отправлено!'),
                                    const SizedBox(height: 10),
                                    if (granted == false)
                                      const Text(
                                        '⚠️ Включите уведомления в настройках устройства',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          
                        } catch (e) {
                          print('❌ Ошибка отправки: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.perm_device_info, size: 18),
                      label: const Text('Проверить разрешения'),
                      onPressed: () async {
                        final status = await _notificationService.checkPermissionStatus();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Статус разрешений'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Разрешения: ${status['enabled'] ?? "неизвестно"}'),
                                Text('Платформа: ${status['platform'] ?? "неизвестно"}'),
                                Text('Инициализирована: ${status['initialized'] ?? false}'),
                                const SizedBox(height: 10),
                                if (status['enabled'] == false)
                                  const Text(
                                    '⚠️ Включите уведомления в настройках устройства',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade100,
                        foregroundColor: Colors.teal.shade800,
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // Дополнительные функции
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Очистить хэши'),
                          onPressed: () async {
                            await _notificationService.clearAllData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Хэши очищены - след. проверка покажет все как новое')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade100,
                            foregroundColor: Colors.purple.shade800,
                          ),
                        ),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.speed, size: 18),
                          label: const Text('Быстрая проверка'),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final lastCheck = prefs.getInt('last_successful_check') ?? 0;
                            
                            final now = DateTime.now().millisecondsSinceEpoch;
                            
                            // Если lastCheck равен 0, значит проверка никогда не выполнялась
                            if (lastCheck == 0) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Статус Polling'),
                                  content: const Text('Проверка еще не выполнялась'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            
                            if (lastCheck > now || (now - lastCheck) > 365 * 24 * 60 * 60 * 1000) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Статус Polling'),
                                  content: const Text('Данные времени повреждены'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            
                            final diffMinutes = (now - lastCheck) ~/ 60000;
                            final nextCheckIn = 15 - diffMinutes;
                            
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Статус Polling'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Polling включен: $_pollingEnabled'),
                                    Text('Последняя проверка: $diffMinutes минут назад'),
                                    Text('Следующая проверка: через ${nextCheckIn > 0 ? nextCheckIn : 0} минут'),
                                    const SizedBox(height: 10),
                                    Text(
                                      diffMinutes >= 15 ? '✅ Готов к проверке' : '⏳ Ожидание...',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: diffMinutes >= 15 ? Colors.green : Colors.orange
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('Переинициализировать'),
                          onPressed: () async {
                            await _notificationService.initialize();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Система уведомлений переинициализирована')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade100,
                            foregroundColor: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                icon: Icon(Icons.bug_report, color: Colors.red),
                label: Text('Симулировать ошибку токена', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  final apiService = ApiService();
                  await apiService.simulateTokenError();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка токена симулирована! Перезайдите в приложение'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                ),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                icon: Icon(Icons.delete, color: Colors.purple),
                label: Text('Очистить все данные Secure_Storage', style: TextStyle(color: Colors.purple)),
                onPressed: () async {
                  final apiService = ApiService();
                  await apiService.clearTokenForTesting();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Secure_Storage данные очищены! Перезайдите в приложение'),
                      backgroundColor: const Color.fromARGB(255, 181, 64, 202),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade50,
                ),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                icon: Icon(Icons.security, color: Colors.blue),
                label: Text('Проверить текущий токен', style: TextStyle(color: Colors.blue)),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  final username = prefs.getString('username');
                  
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Информация о токене'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Токен: ${token?.substring(0, 20)}...'),
                          Text('Длина: ${token?.length ?? 0} символов'),
                          Text('Username: $username'),
                          SizedBox(height: 10),
                          Text(
                            token == null || token.isEmpty ? 'Токен отсутствует' : 'Токен есть',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: token == null || token.isEmpty ? Colors.red : Colors.green
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}