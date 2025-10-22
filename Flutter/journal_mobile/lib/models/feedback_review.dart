class FeedbackReview {
  final String teacherName;
  final String subject;
  final String feedbackText;
  final String date;

  FeedbackReview({
    required this.teacherName,
    required this.subject,
    required this.feedbackText,
    required this.date,
  });

  factory FeedbackReview.fromJson(Map<String, dynamic> json) {
    print("Parsing feedback JSON: $json");
    
    final teacherName = json['teacher'] ??  'Преподаватель';
    
    final subject = json['spec'] ?? 'Предмет';
    
    final feedbackText = json['message'] ??  'Нет сообщения';
    
    final date = json['date'] ?? '';
    
    return FeedbackReview(
      teacherName: teacherName,
      subject: subject,
      feedbackText: feedbackText,
      date: date,
    );
  }
}