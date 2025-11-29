import 'package:flutter/material.dart';

class HomeworkUtils {
  static Color getStatusColor(String status) {
    switch (status) {
      case 'deleted':
        return Colors.grey.shade700;
      case 'expired':
        return Colors.red.shade700;
      case 'done':
        return Colors.green.shade700;
      case 'inspection':
        return Colors.blue.shade700;
      case 'opened':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  static String getStatusText(String status) {
    switch (status) {
      case 'deleted':
        return 'Удалено';
      case 'expired':
        return 'Просрочено';
      case 'done':
        return 'Проверено';
      case 'inspection':
        return 'На проверке';
      case 'opened':
        return 'Активно';
      default:
        return 'Неизвестно';
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'deleted':
        return Icons.delete_rounded;
      case 'expired':
        return Icons.warning_rounded;
      case 'done':
        return Icons.check_circle_rounded;
      case 'inspection':
        return Icons.hourglass_top_rounded;
      case 'opened':
        return Icons.assignment_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String getEmptyStateDescription(String status) {
    switch (status) {
      case 'opened':
        return 'У вас нет активных заданий';
      case 'inspection':
        return 'Нет работ на проверке';
      case 'done':
        return 'Проверенные работы отсутствуют';
      case 'expired':
        return 'Просроченных работ нет';
      case 'deleted':
        return 'Удаленные работы отсутствуют';
      default:
        return 'Задания не найдены';
    }
  }
}