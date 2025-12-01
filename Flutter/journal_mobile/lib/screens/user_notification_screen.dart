import 'package:flutter/material.dart';
import 'dart:async';

import 'package:journal_mobile/models/notification_item.dart';
import 'package:journal_mobile/models/_rabbits/notification_time.dart';
import 'package:journal_mobile/models/_widgets/notifications/empty_notifications.dart';
import 'package:journal_mobile/models/_widgets/notifications/error_notifications.dart';
import 'package:journal_mobile/models/_widgets/notifications/notification_list.dart';

import 'package:journal_mobile/services/_settings/notification_service.dart';
import 'package:journal_mobile/services/secure_storage_service.dart';

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({super.key});

  @override
  State<UserNotificationScreen> createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  late Stream<List<NotificationItem>> _notificationsStream;
  bool _isLoading = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _notificationService.notificationsStream;
    _markAllAsRead();
    _startAutoRefresh();
    _refreshNotifications();
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
    
    final interval = NotificationTime.getCurrentPollingInterval();
    
    _autoRefreshTimer = Timer(interval, () {
      _refreshNotifications();
      _scheduleNextRefresh();
    });
  }

  Future<void> _markAllAsRead() async {
    final notifications = await _notificationService.getNotificationsHistory();
    for (final notification in notifications.where((n) => !n.isRead)) {
      await _notificationService.markAsRead(notification.id);
    }
    _refreshNotifications();
  }

  void _refreshNotifications() {
    _notificationService.getNotificationsHistory().then((_) {
    });
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

  Future<void> _onNotificationTap(NotificationItem notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      _refreshNotifications();
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
          _buildControlCard(),
          Expanded(
            child: StreamBuilder<List<NotificationItem>>(
              stream: _notificationsStream,
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ErrorNotifications(onRetry: _refreshNotifications);
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const EmptyNotifications();
                }

                return NotificationList(
                  notifications: notifications,
                  onNotificationTap: _onNotificationTap,
                  onNotificationDelete: _deleteNotification,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

        Widget _buildControlCard() {
          return Card(
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
                            : 'Автообновление каждые ${NotificationTime.getCurrentPollingInterval().inMinutes} мин.',
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
    );
  }
}