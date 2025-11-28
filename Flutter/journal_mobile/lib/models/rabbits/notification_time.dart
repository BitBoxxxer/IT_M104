class NotificationTime {
  static String formatTimeAgo(DateTime timestamp) {
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

  static Duration getCurrentPollingInterval() {
    final hour = DateTime.now().hour;
    
    if (hour >= 23 || hour <= 6) {
      return const Duration(minutes: 60);
    } else if (hour >= 8 && hour <= 18) {
      return const Duration(minutes: 10);
    } else {
      return const Duration(minutes: 30);
    }
  }
}