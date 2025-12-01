import 'package:flutter/material.dart';
import '../../exam.dart';
import '../../_rabbits/exam_sort.dart';
import '../animation/slide_in_card.dart';

class FutureExamCard extends StatelessWidget {
  final Exam exam;
  final int index;

  const FutureExamCard({
    super.key,
    required this.exam,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return SlideInCard(
      delay: Duration(milliseconds: 50),
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Text(
                      'Ожидается',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                  
                  const SizedBox(height: 8),
                  Text(
                    '📅 Предстоящий экзамен',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
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