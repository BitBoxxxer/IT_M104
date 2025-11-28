import 'package:flutter/material.dart';
import '../../exam.dart';
import '../../rabbits/exam_sort.dart';
import '../animation/slide_in_card.dart';

class PastExamCard extends StatelessWidget {
  final Exam exam;
  final int index;
  final bool showSystemInfo;

  const PastExamCard({
    super.key,
    required this.exam,
    required this.index,
    this.showSystemInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isTwelvePoint = exam.isTwelvePointSystem;
    final originalGrade = exam.originalNumericGrade;
    
    return SlideInCard(
      delay: Duration(milliseconds: 50), // Уменьшили задержку
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.subjectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showSystemInfo && isTwelvePoint && originalGrade != null)
                          Text(
                            '12-балльная система',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: exam.isPassed 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: exam.isPassed ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          exam.displayGrade,
                          style: TextStyle(
                            color: exam.isPassed ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isTwelvePoint && originalGrade != null && exam.displayGrade != originalGrade.toString())
                          Text(
                            '($originalGrade)',
                            style: TextStyle(
                              color: exam.isPassed ? Colors.green : Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exam.teacherName != null && exam.teacherName!.isNotEmpty) 
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          exam.teacherName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        ExamUtils.formatDate(exam.date),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}