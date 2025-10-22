import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/feedback_review.dart';

class FeedbackReviewScreen extends StatefulWidget {
  final String token;

  const FeedbackReviewScreen({super.key, required this.token});

  @override
  State<FeedbackReviewScreen> createState() => _FeedbackReviewScreenState();
}

class _FeedbackReviewScreenState extends State<FeedbackReviewScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<FeedbackReview>> _feedbackFuture;

  @override
  void initState() {
    super.initState();
    _feedbackFuture = _loadFeedback();
  }

  Future<List<FeedbackReview>> _loadFeedback() async {
    return await _apiService.getFeedbackReview(widget.token);
  }

  Widget _buildFeedbackCard(FeedbackReview feedback, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSubjectColor(feedback.subject),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.teacherName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        feedback.subject,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Divider(height: 1, color: Colors.grey.shade300),
            SizedBox(height: 12),
            
            Text(
              feedback.feedbackText,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            
            SizedBox(height: 12),
            
            if (feedback.date.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatDate(feedback.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
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

  String _formatDate(String date) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отзывы о студенте'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<FeedbackReview>>(
        future: _feedbackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Загрузка отзывов...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _feedbackFuture = _loadFeedback();
                      });
                    },
                    child: Text('Попробовать снова'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.reviews_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Отзывов пока нет',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Преподаватели еще не оставили отзывы',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          final feedbackList = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _feedbackFuture = _loadFeedback();
              });
            },
            child: ListView.builder(
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                return _buildFeedbackCard(feedbackList[index], index);
              },
            ),
          );
        },
      ),
    );
  }
}