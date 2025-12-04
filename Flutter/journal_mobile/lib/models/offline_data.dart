// models/offline_data.dart
import './mark.dart';
import './user_data.dart';
import './days_element.dart';
import './activity_record.dart';
import '_widgets/exams/exam.dart';
import './feedback_review.dart';
import '_widgets/homework/homework.dart';
import '_widgets/homework/homework_counter.dart';
import './leaderboard_user.dart';

class OfflineData {
  final List<Mark> marks;
  final UserData? userData;
  final List<ScheduleElement>? schedule;
  final List<ActivityRecord>? activityRecords;
  final List<Exam>? exams;
  final List<FeedbackReview>? feedbackReviews;
  final List<Homework>? homeworks;
  final List<HomeworkCounter>? homeworkCounters;
  final List<LeaderboardUser>? groupLeaders;
  final List<LeaderboardUser>? streamLeaders;
  final DateTime lastUpdated;

  OfflineData({
    required this.marks,
    this.userData,
    this.schedule,
    this.activityRecords,
    this.exams,
    this.feedbackReviews,
    this.homeworks,
    this.homeworkCounters,
    this.groupLeaders,
    this.streamLeaders,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'marks': marks.map((m) => m.toJson()).toList(),
      'userData': userData?.toJson(),
      'schedule': schedule?.map((s) => s.toJson()).toList(),
      'activityRecords': activityRecords?.map((a) => a.toJson()).toList(),
      'exams': exams?.map((e) => e.toJson()).toList(),
      'feedbackReviews': feedbackReviews?.map((f) => f.toJson()).toList(),
      'homeworks': homeworks?.map((h) => h.toJson()).toList(),
      'homeworkCounters': homeworkCounters?.map((h) => h.toJson()).toList(),
      'groupLeaders': groupLeaders?.map((g) => g.toJson()).toList(),
      'streamLeaders': streamLeaders?.map((s) => s.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory OfflineData.fromJson(Map<String, dynamic> json) {
    return OfflineData(
      marks: (json['marks'] as List? ?? [])
          .map((m) => Mark.fromJson(m))
          .toList(),
      userData: json['userData'] != null 
          ? UserData.fromJson(json['userData']) 
          : null,
      schedule: (json['schedule'] as List? ?? [])
          .map((s) => ScheduleElement.fromJson(s))
          .toList(),
      activityRecords: (json['activityRecords'] as List? ?? [])
          .map((a) => ActivityRecord.fromJson(a))
          .toList(),
      exams: (json['exams'] as List? ?? [])
          .map((e) => Exam.fromJson(e))
          .toList(),
      feedbackReviews: (json['feedbackReviews'] as List? ?? [])
          .map((f) => FeedbackReview.fromJson(f))
          .toList(),
      homeworks: (json['homeworks'] as List? ?? [])
          .map((h) => Homework.fromJson(h))
          .toList(),
      homeworkCounters: (json['homeworkCounters'] as List? ?? [])
          .map((h) => HomeworkCounter.fromJson(h))
          .toList(),
      groupLeaders: (json['groupLeaders'] as List? ?? [])
          .map((g) => LeaderboardUser.fromJson(g))
          .toList(),
      streamLeaders: (json['streamLeaders'] as List? ?? [])
          .map((s) => LeaderboardUser.fromJson(s))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}