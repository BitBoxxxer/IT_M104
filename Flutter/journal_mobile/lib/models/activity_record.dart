class ActivityRecord {
  final String date;
  final int action;
  final int currentPoint;
  final int pointTypesId;
  final String pointTypesName;
  final int? achievementsId;
  final String? achievementsName;
  final int? achievementsType;
  final int badge;
  final bool oldCompetition;
  
  String? lessonSubject;
  String? lessonTheme;

  ActivityRecord({
    required this.date,
    required this.action,
    required this.currentPoint,
    required this.pointTypesId,
    required this.pointTypesName,
    this.achievementsId,
    this.achievementsName,
    this.achievementsType,
    required this.badge,
    required this.oldCompetition,
    this.lessonSubject,
    this.lessonTheme,
  });

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      date: json['date']?.toString() ?? '',
      action: json['action'] as int? ?? 0,
      currentPoint: json['current_point'] as int? ?? 0,
      pointTypesId: json['point_types_id'] as int? ?? 0,
      pointTypesName: json['point_types_name']?.toString() ?? '',
      achievementsId: json['achievements_id'] as int?,
      achievementsName: json['achievements_name']?.toString(),
      achievementsType: json['achievements_type'] as int?,
      badge: json['badge'] as int? ?? 0,
      oldCompetition: json['old_competition'] as bool? ?? false,
    );
  }

  ActivityRecord copyWith({
    String? lessonSubject,
    String? lessonTheme,
  }) {
    return ActivityRecord(
      date: date,
      action: action,
      currentPoint: currentPoint,
      pointTypesId: pointTypesId,
      pointTypesName: pointTypesName,
      achievementsId: achievementsId,
      achievementsName: achievementsName,
      achievementsType: achievementsType,
      badge: badge,
      oldCompetition: oldCompetition,
      lessonSubject: lessonSubject ?? this.lessonSubject,
      lessonTheme: lessonTheme ?? this.lessonTheme,
    );
  }
}