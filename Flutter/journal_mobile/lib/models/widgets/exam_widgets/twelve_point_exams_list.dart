import 'package:flutter/material.dart';
import '../animation/slide_in_card.dart';
import '../animation/fade_in_animation.dart';
import '../animation/scale_animation.dart';
import '../animation/fade_in_row.dart';
import 'package:journal_mobile/models/exam.dart';

class TwelvePointExamsList extends StatefulWidget {
  final List<Exam> exams;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const TwelvePointExamsList({
    Key? key,
    required this.exams,
    required this.emptyMessage,
    required this.onRefresh,
  }) : super(key: key);

  @override
  TwelvePointExamsListState createState() => TwelvePointExamsListState();
}

class TwelvePointExamsListState extends State<TwelvePointExamsList> {
  bool _isConversionExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 64, color: Colors.orange[400]),
            SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final stats = _calculateAverageGrade(widget.exams);

    return Column(
      children: [
        if (stats['count']! > 0)
          Padding(
            padding: EdgeInsets.all(16),
            child: _buildAverageGradeCard(
              (stats['average'] as double).toStringAsFixed(1),
              stats['count']!,
              '12-балльная система',
              Colors.orange,
            ),
          ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildConversionGuideCard(),
        ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 16),
              itemCount: widget.exams.length,
              itemBuilder: (context, index) {
                return _buildPastExamCard(widget.exams[index], index, showSystemInfo: false);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversionGuideCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _isConversionExpanded = !_isConversionExpanded;
                });
              },
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Конвертация оценок',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                  Icon(
                    _isConversionExpanded 
                      ? Icons.expand_less 
                      : Icons.expand_more,
                    size: 20,
                    color: Colors.orange[700],
                  ),
                ],
              ),
            ),
            
            if (_isConversionExpanded) 
              _buildConversionContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionContent() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 8),
      SlideInCard(
        delay: Duration(milliseconds: 0),
        child: Text(
          '12-балльная система → 5-балльная система:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      SizedBox(height: 4),
      _buildAnimatedConversionRow('12, 11, 10 баллов', '5', 'Отлично', Icons.numbers, Colors.green, 0),
      _buildDivider(),
      _buildAnimatedConversionRow('9, 8 баллов', '4', 'Хорошо', Icons.numbers, Colors.blue, 1),
      _buildDivider(),
      _buildAnimatedConversionRow('7, 6, 5 баллов', '3', 'Удовл.', Icons.numbers, Colors.orange, 2),
      _buildDivider(),
      _buildAnimatedConversionRow('4, 3, 2, 1 балла', '2', 'Неудовл.', Icons.numbers, Colors.red, 3),
      SizedBox(height: 4),
      SlideInCard(
        delay: Duration(milliseconds: 400),
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, size: 12, color: Colors.grey[600]),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Средний балл рассчитывается после конвертации в 5-балльную систему',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          )
        ),
      )
    ]
  );
}

Widget _buildAnimatedConversionRow(String from, String grade, String description, IconData icon, Color color, int index) {
  return SlideInCard(
    delay: Duration(milliseconds: 100 + (index * 50)),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          ScaleAnimation(
            delay: Duration(milliseconds: 150 + (index * 50)),
            child: Icon(icon, size: 14, color: color),
          ),
          SizedBox(width: 6),
          
          Expanded(
            flex: 2,
            child: FadeInAnimation(
              delay: Duration(milliseconds: 200 + (index * 50)),
              child: Text(
                from,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          FadeInAnimation(
            delay: Duration(milliseconds: 250 + (index * 50)),
            child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey[500]),
          ),
          
          Expanded(
            flex: 2,
            child: FadeInAnimation(
              delay: Duration(milliseconds: 300 + (index * 50)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    grade,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildPastExamCard(Exam exam, int index, {bool showSystemInfo = true}) {
    final isTwelvePoint = exam.isTwelvePointSystem;
    final originalGrade = exam.originalNumericGrade;
    
    return SlideInCard(
      delay: Duration(milliseconds: 100 * index),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showSystemInfo && isTwelvePoint && originalGrade != null)
                          FadeInAnimation(
                            delay: Duration(milliseconds: 150 + 100 * index),
                            child: Text(
                              '12-балльная система',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ScaleAnimation(
                    delay: Duration(milliseconds: 200 + 100 * index),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exam.teacherName != null && exam.teacherName!.isNotEmpty) 
                    FadeInRow(
                      delay: Duration(milliseconds: 250 + 100 * index),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            exam.teacherName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 4),
                  
                  FadeInRow(
                    delay: Duration(milliseconds: 300 + 100 * index),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.blue[700]),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(exam.date),
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Map<String, dynamic> _calculateAverageGrade(List<Exam> exams) {
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

  Widget _buildAverageGradeCard(String averageGrade, int gradedExamsCount, String systemName, Color color) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
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
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Средний балл',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      averageGrade,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getGradeColor(double.parse(averageGrade)),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Оценок',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
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

  Color _getGradeColor(double grade) {
    if (grade >= 4.5) return Colors.blueAccent;
    if (grade >= 4) return Colors.green;
    if (grade >= 3) return Colors.orange;
    return Colors.red;
  }
}