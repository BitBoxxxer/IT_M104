import 'package:flutter/material.dart';
import 'package:journal_mobile/models/rabbits/exam_sort.dart';

class AverageGradeCard extends StatelessWidget {
  final String averageGrade;
  final int gradedExamsCount;
  final String systemName;
  final Color color;

  const AverageGradeCard({
    super.key,
    required this.averageGrade,
    required this.gradedExamsCount,
    required this.systemName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              systemName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Средний балл',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      averageGrade,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ExamUtils.getGradeColor(double.parse(averageGrade)),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Оценок',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gradedExamsCount.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}