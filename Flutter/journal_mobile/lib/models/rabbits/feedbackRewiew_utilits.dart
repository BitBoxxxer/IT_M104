import 'package:flutter/material.dart';

class FeedbackUtils {
  static Color getSubjectColor(String subject) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.red.shade700,
      Colors.teal.shade700,
    ];
    final index = subject.hashCode % colors.length;
    return colors[index];
  }

  static String formatDate(String date) {
    if (date.contains('-')) {
      try {
        final parts = date.split(' ')[0].split('-');
        if (parts.length == 3) {
          return '${parts[2]}.${parts[1]}.${parts[0]}';
        }
      } catch (e) {
        print("Error formatting date: $e");
      }
    }
    return date;
  }
}