class Homework {
  final int id;
  final int teacherWorkId;
  final String subjectName;
  final String theme;
  final String? description;
  final DateTime creationTime;
  final DateTime completionTime;
  final DateTime? overdueTime;
  final String? filename;
  final String? filePath;
  final String? comment;
  final int status;
  final int commonStatus;
  final HomeworkStud? homeworkStud;
  final HomeworkComment? homeworkComment;
  final String? coverImage;
  final String teacherName;
  final int? materialType;

  Homework({
    required this.id,
    required this.teacherWorkId,
    required this.subjectName,
    required this.theme,
    this.description,
    required this.creationTime,
    required this.completionTime,
    this.overdueTime,
    this.filename,
    this.filePath,
    this.comment,
    required this.status,
    required this.commonStatus,
    this.homeworkStud,
    this.homeworkComment,
    this.coverImage,
    required this.teacherName,
    this.materialType,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateString) {
      if (dateString == null) return DateTime.now();
      try {
        return DateTime.parse(dateString.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return Homework(
      id: json['id'] ?? 0,
      teacherWorkId: json['teacher'] ?? json['id'] ?? 0,
      subjectName: json['name_spec'] ??'Не указано',
      theme: json['theme'] ?? 'Без темы',
      description: json['comment']?.toString(),
      creationTime: parseDate(json['creation_time']),
      completionTime: parseDate(json['completion_time']),
      overdueTime: json['overdue_time'] != null ? parseDate(json['overdue_time']) : null,
      filename: json['filename']?.toString(),
      filePath: json['file_path']?.toString(),
      comment: json['comment']?.toString(),
      status: json['status'] ?? 0,
      commonStatus: json['common_status'] ?? 0,
      homeworkStud: json['homework_stud'] != null 
          ? HomeworkStud.fromJson(json['homework_stud']) 
          : null,
      homeworkComment: json['homework_comment'] != null 
          ? HomeworkComment.fromJson(json['homework_comment']) 
          : null,
      coverImage: json['cover_image']?.toString(),
      teacherName: json['fio_teach'] ?? 'Не указан',
      materialType: json['material_type'] ?? json['type_id'],
    );
  }

  bool get isExpired => _getRealStatus() == 0;
  bool get isDone => _getRealStatus() == 1;
  bool get isInspection => _getRealStatus() == 2;
  bool get isOpened => _getRealStatus() == 3;
  bool get isDeleted => _getRealStatus() == 5;

  /// Определение реального статуса на основе всех доступных данных
  int _getRealStatus() {
    if (homeworkStud?.mark != null) {
      return 1; // DONE
    }
    
    if (homeworkStud != null && homeworkStud?.mark == null) {
      return 2; // INSPECTION
    }
    
    final now = DateTime.now();
    if (_isDateAfter(now, completionTime)) {
      return 0; // EXPIRED
    }
    
    return 3; // OPENED
  }

  String get statusString {
    switch (_getRealStatus()) {
      case 0: return 'expired';
      case 1: return 'done';
      case 2: return 'inspection';
      case 3: return 'opened';
      case 5: return 'deleted';
      default: return 'unknown';
    }
  }

  bool _isDateAfter(DateTime date1, DateTime date2) {
    final date1Normalized = DateTime(date1.year, date1.month, date1.day);
    final date2Normalized = DateTime(date2.year, date2.month, date2.day);
    return date1Normalized.isAfter(date2Normalized);
  }

  bool get canUpload => isOpened || isExpired;
}

class HomeworkStud {
  final int id;
  final String? filename;
  final String? answerText;
  final String? filePath;
  final String? tmpfile;
  final double? mark;
  final bool autoMark;
  final DateTime creationTime;

  HomeworkStud({
    required this.id,
    this.filename,
    this.answerText,
    this.filePath,
    this.tmpfile,
    this.mark,
    required this.autoMark,
    required this.creationTime,
  });

  factory HomeworkStud.fromJson(Map<String, dynamic> json) {
    return HomeworkStud(
      id: json['id'] ?? 0,
      filename: json['filename']?.toString(),
      answerText: json['stud_answer']?.toString(),
      filePath: json['file_path']?.toString(),
      tmpfile: json['tmp_file']?.toString(),
      mark: json['mark'] != null ? double.tryParse(json['mark'].toString()) : null,
      autoMark: json['auto_mark'] == true,
      creationTime: DateTime.parse(json['creation_time'] ?? DateTime.now().toString()),
    );
  }
}

class HomeworkComment {
  final String textComment;
  final String? attachment;
  final String? attachmentPath;
  final DateTime dateUpdated;

  HomeworkComment({
    required this.textComment,
    this.attachment,
    this.attachmentPath,
    required this.dateUpdated,
  });

  factory HomeworkComment.fromJson(Map<String, dynamic> json) {
    return HomeworkComment(
      textComment: json['text_comment'] ?? '',
      attachment: json['attachment']?.toString(),
      attachmentPath: json['attachment_path']?.toString(),
      dateUpdated: DateTime.parse(json['date_updated'] ?? DateTime.now().toString()),
    );
  }
}