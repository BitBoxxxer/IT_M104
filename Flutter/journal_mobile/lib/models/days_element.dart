class ScheduleElement {
  final String date;
  final String startedAt;
  final String finishedAt;
  final int lesson;
  final String roomName;
  final String subjectName;
  final String teacherName;

  ScheduleElement({
    required this.date,
    required this.startedAt,
    required this.finishedAt,
    required this.lesson,
    required this.roomName,
    required this.subjectName,
    required this.teacherName,
  });

  factory ScheduleElement.fromJson(Map<String, dynamic> json) {
    return ScheduleElement(
      date: json['date'] as String,
      startedAt: json['started_at'] as String,
      finishedAt: json['finished_at'] as String,
      lesson: json['lesson'] as int,
      roomName: json['room_name'] as String,
      subjectName: json['subject_name'] as String,
      teacherName: json['teacher_name'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'started_at': startedAt,
      'finished_at': finishedAt,
      'lesson': lesson,
      'room_name': roomName,
      'subject_name': subjectName,
      'teacher_name': teacherName,
    };
  }
}