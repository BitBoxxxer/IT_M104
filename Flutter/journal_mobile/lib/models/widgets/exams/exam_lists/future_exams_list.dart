import 'package:flutter/material.dart';
import '../empty_exams.dart';
import '../future_exam_card.dart';
import '../../../exam.dart';

class FutureExamsList extends StatelessWidget {
  final List<Exam> exams;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const FutureExamsList({
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
        icon: Icons.event_available,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          return FutureExamCard(
            exam: exams[index],
            index: index,
          );
        },
      ),
    );
  }
}