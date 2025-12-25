import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/_notification/notification_service.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../services/schedule_note_service.dart';

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
                    // Добавьте в Column виджетов:
Card(
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      children: [
        const Text(
          'Тестирование заметок расписания',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        const SizedBox(height: 16),
        
        ElevatedButton.icon(
          icon: const Icon(Icons.alarm_add, size: 18),
          label: const Text('Тест напоминания на 1 минуту'),
          onPressed: () async {
            try {
              final noteService = ScheduleNoteService();
              await noteService.saveNote(
                date: DateTime.now(),
                text: 'Тестовое напоминание на 1 минуту',
                color: Colors.blue,
                reminderTime: DateTime.now().add(const Duration(minutes: 1)),
                reminderEnabled: true,
              );
              
              showTopSnackBar(
                Overlay.of(context),
                const CustomSnackBar.success(
                  message: 'Напоминание запланировано через 1 минуту',
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка: $e')),
              );
            }
          },
        ),

        /* ElevatedButton.icon(
          icon: const Icon(Icons.schedule, size: 18),
          label: const Text('Показать запланированные напоминания'),
          onPressed: () async {
            final androidPlugin = FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
            if (androidPlugin != null) {
              final scheduled = await androidPlugin.getScheduledNotifications();
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Запланированные уведомления'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: scheduled.length,
                      itemBuilder: (context, index) {
                        final notification = scheduled[index];
                        return ListTile(
                          title: Text(notification.title ?? 'Без названия'),
                          subtitle: Text('ID: ${notification.id}'),
                          trailing: Text(notification.body ?? ''),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
         */
        const SizedBox(height: 12),
        
        ElevatedButton.icon(
          icon: const Icon(Icons.notifications, size: 18),
          label: const Text('Проверить напоминания заметок'),
          onPressed: () async {
            final noteService = ScheduleNoteService();
            await noteService.checkAndTriggerReminders();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Проверка напоминаний выполнена')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade100,
            foregroundColor: Colors.teal.shade800,
          ),
        ),
        
        const SizedBox(height: 12),
        
        ElevatedButton.icon(
          icon: const Icon(Icons.list, size: 18),
          label: const Text('Показать предстоящие напоминания'),
          onPressed: () async {
            final noteService = ScheduleNoteService();
            final reminders = await noteService.getUpcomingReminders(limit: 5);
            
            if (reminders.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Нет предстоящих напоминаний')),
              );
            } else {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Предстоящие напоминания'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        final note = reminders[index];
                        return ListTile(
                          leading: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: note.noteColor ?? Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            note.noteText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${DateFormat('dd.MM.yyyy HH:mm').format(note.reminderTime!)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade100,
            foregroundColor: Colors.indigo.shade800,
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