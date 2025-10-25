import 'package:flutter/material.dart';
import 'dart:async';
import 'package:journal_mobile/services/settings/notification_service.dart';
import 'package:journal_mobile/services/secure_storage_service.dart';
import 'package:journal_mobile/models/notification_item.dart';

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({super.key});

  @override
  State<UserNotificationScreen> createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  late Future<List<NotificationItem>> _notificationsFuture;
  bool _isLoading = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _notificationService.getNotificationsHistory();
    _markAllAsRead();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    Future.delayed(Duration(seconds: 1), () {
      _refreshNotifications();
    });

    _scheduleNextRefresh();
  }

  void _scheduleNextRefresh() {
    _autoRefreshTimer?.cancel();
    
    final interval = _getCurrentPollingInterval();
    
    _autoRefreshTimer = Timer(interval, () {
      _refreshNotifications();
      _scheduleNextRefresh();
    });
  }

  Duration _getCurrentPollingInterval() {
    final hour = DateTime.now().hour;
    
    if (hour >= 23 || hour <= 6) {
      return Duration(minutes: 60);
    } else if (hour >= 8 && hour <= 18) {
      return Duration(minutes: 10);
    } else {
      return Duration(minutes: 30);
    }
  }

  Future<void> _markAllAsRead() async {
    final notifications = await _notificationService.getNotificationsHistory();
    for (final notification in notifications.where((n) => !n.isRead)) {
      await _notificationService.markAsRead(notification.id);
    }
    _refreshNotifications();
  }

  void _refreshNotifications() {
    if (mounted) {
      setState(() {
        _notificationsFuture = _notificationService.getNotificationsHistory();
      });
    }
  }

  Future<void> _manualCheck() async {
    setState(() {
      _isLoading = true;
    });

    final secureStorage = SecureStorageService();
    final token = await secureStorage.getToken();
    
    if (token != null) {
      await _notificationService.manualCheckWithNotification(token);
      await Future.delayed(const Duration(seconds: 2));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _refreshNotifications();
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text('Вы уверены, что хотите очистить всю историю уведомлений?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await _notificationService.clearNotificationsHistory();
      _refreshNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('История уведомлений очищена')),
      );
    }
  }

  Future<void> _deleteNotification(NotificationItem notification) async {
    await _notificationService.deleteNotification(notification.id);
    _refreshNotifications();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Уведомление удалено'),
        action: SnackBarAction(
          label: 'Отмена',
          onPressed: () async {
            await _notificationService.saveNotificationToHistory(notification);
            _refreshNotifications();
          },
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newMarks:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school, color: Colors.green, size: 20),
        );
      case NotificationType.attendance:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.access_time, color: Colors.orange, size: 20),
        );
      case NotificationType.schedule:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
        );
      case NotificationType.achievement:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events, color: Colors.purple, size: 20),
        );
      case NotificationType.system:
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.info, color: Colors.grey, size: 20),
        );
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} д. назад';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshNotifications,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearAllNotifications,
            tooltip: 'Очистить историю',
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Проверка обновлений',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoading 
                            ? 'Выполняется проверка...' 
                            : 'Автообновление каждые ${_getCurrentPollingInterval().inMinutes} мин.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : FloatingActionButton(
                          mini: true,
                          onPressed: _manualCheck,
                          child: const Icon(Icons.search),
                        ),
                ],
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<NotificationItem>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Ошибка загрузки уведомлений',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _refreshNotifications,
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Уведомлений пока нет',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Новые оценки и изменения посещаемости\nпоявятся здесь автоматически',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    
                    return Dismissible(
                      key: Key(notification.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Удалить уведомление?'),
                            content: Text('Удалить "${notification.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        return shouldDelete ?? false;
                      },
                      onDismissed: (direction) async {
                        await _deleteNotification(notification);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: notification.isRead 
                            ? Theme.of(context).cardTheme.color
                            : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        elevation: 1,
                        child: ListTile(
                          leading: _buildNotificationIcon(notification.type),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead 
                                  ? FontWeight.normal 
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.message),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(notification.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: notification.isRead 
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () async {
                            if (!notification.isRead) {
                              await _notificationService.markAsRead(notification.id);
                              _refreshNotifications();
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}