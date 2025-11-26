class Mark {
  final String specName;
  final String lessonTheme;
  final String dateVisit;
  final int? homeWorkMark;
  final int? controlWorkMark;
  final int? labWorkMark;
  final int? classWorkMark;
  final int? practicalWorkMark;
  final int? statusWas;

  Mark({
    required this.specName,
    required this.lessonTheme,
    required this.dateVisit,
    this.homeWorkMark,
    this.controlWorkMark,
    this.labWorkMark,
    this.classWorkMark,
    this.practicalWorkMark,
    this.statusWas,
  });

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      specName: json['spec_name'] ?? "spec_name_offline",
      lessonTheme: json['lesson_theme'] ?? "lesson_theme_offline",
      dateVisit: json['date_visit'] ?? "date_visit_offline",
      homeWorkMark: json['home_work_mark'],
      controlWorkMark: json['control_work_mark'] as int?,
      labWorkMark: json['lab_work_mark'] as int?,
      classWorkMark: json['class_work_mark'] as int?,
      practicalWorkMark: json['practical_work_mark'] as int?,
      statusWas: json['status_was'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spec_name': specName,
      'lesson_theme': lessonTheme,
      'date_visit': dateVisit,
      'home_work_mark': homeWorkMark,
      'control_work_mark': controlWorkMark,
      'lab_work_mark': labWorkMark,
      'class_work_mark': classWorkMark,
      'practical_work_mark': practicalWorkMark,
      'status_was': statusWas,
    };
  }
}