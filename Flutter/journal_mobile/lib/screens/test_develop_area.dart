import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/_notification/notification_service.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text(
                      'Тестирование уведомлений',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 30),
                    
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
                    
                    const SizedBox(height: 50),
                    
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
                    const SizedBox(height: 50),

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
                        const SizedBox(height: 50),

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
                        const SizedBox(height: 50),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Чисто по приколу слепила, заценить прикол с SnackBar - Ди :D
            SizedBox(
              child: ElevatedButton(
                onPressed: () {
                  if (!mounted) return;
                  
                  final overlay = Overlay.of(context);
                  if (overlay.mounted) {
                    showTopSnackBar(
                      overlay,
                      const CustomSnackBar.success(
                        message: 'Пример новых CustomSnackBar.',
                        backgroundColor: Color.fromARGB(255, 255, 153, 0),
                        textStyle: TextStyle(
                          fontSize: 17, 
                          color: Colors.white, 
                          fontWeight: FontWeight.bold
                        ),
                        icon: Icon(
                          Icons.notifications_active,
                          size: 80,
                          color: Colors.white60,
                        ),
                        iconPositionLeft: -24,
                      ),
                      displayDuration: const Duration(seconds: 1),
                    );
                  }
                },
                child: Text('Показать новый стиль SnackBar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}