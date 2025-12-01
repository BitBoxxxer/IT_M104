import 'package:flutter/material.dart';
import 'package:journal_mobile/models/exam.dart';

class ExamUtils {
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  static Color getGradeColor(double grade) {
    if (grade >= 4.5) return Colors.blueAccent;
    if (grade >= 4) return Colors.green;
    if (grade >= 3) return Colors.orange;
    return Colors.red;
  }

  static Map<String, dynamic> calculateAverageGrade(List<Exam> exams) {
    final numericGrades = exams
        .map((e) => e.numericGrade)
        .where((grade) => grade != null && grade > 0)
        .cast<int>()
        .toList();
    
    final count = numericGrades.length;
    final average = count > 0 
        ? (numericGrades.reduce((a, b) => a + b) / count)
        : 0.0;

    return {
      'average': average,
      'count': count,
    };
  }
}