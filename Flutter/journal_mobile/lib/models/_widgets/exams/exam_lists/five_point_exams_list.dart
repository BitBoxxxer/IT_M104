import 'package:flutter/material.dart';

import '../exam.dart';
import '../../../_rabbits/exam_sort.dart';
import '../empty_exams.dart';
import '../past_exam_card.dart';
import '../average_grade_card.dart';

class FivePointExamsList extends StatelessWidget {
  final List<Exam> exams;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const FivePointExamsList({
    super.key,
    required this.exams,
    required this.emptyMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return EmptyExams(
        message: emptyMessage,
        icon: Icons.assignment,
      );
    }

    final stats = ExamUtils.calculateAverageGrade(exams);

    return Column(
      children: [
        if (stats['count']! > 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: AverageGradeCard(
              averageGrade: (stats['average'] as double).toStringAsFixed(1),
              gradedExamsCount: stats['count']!,
              systemName: '5-балльная система',
              color: Colors.blue,
            ),
          ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                return PastExamCard(
                  exam: exams[index],
                  index: index,
                  showSystemInfo: false,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}