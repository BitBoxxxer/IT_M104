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
  final bool? isDeleted;

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
    this.isDeleted,
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
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  bool get isExpired => getRealStatus() == 0;
  bool get isDone => getRealStatus() == 1;
  bool get isInspection => getRealStatus() == 2;
  bool get isOpened => getRealStatus() == 3;
  bool get isDeletedStatus => getRealStatus() == 5;

  bool get hasAttachment => filename != null && filename!.isNotEmpty;
  String? get downloadUrl => filePath != null ? _buildDownloadUrl(filePath!) : null;
  
  String _buildDownloadUrl(String filePath) {
    if (filePath.startsWith('http')) {
      return filePath;
    } else {
      return 'https://msapi.top-academy.ru$filePath';
    }
  }

String? get studentDownloadUrl {
  if (homeworkStud?.filePath != null && homeworkStud!.filePath!.isNotEmpty) {
    return _buildDownloadUrl(homeworkStud!.filePath!);
  }
  return null;
}

String? get studentFilename => homeworkStud?.filename;

  int getRealStatus() {
    if (isDeleted == true) {
      return 5; // DELETED
    }
    
    if (status == 5 || commonStatus == 5) {
      return 5;
    }
    
    if (theme.toLowerCase().contains('удален') || 
        (description?.toLowerCase().contains('удален') == true)) {
      return 5;
    }
    
    if (homeworkStud?.mark != null) {
      return 1;
    }
    
    if (homeworkStud != null) {
      return 2;
    }
    
    final now = DateTime.now();
    if (now.isAfter(completionTime)) {
      return 0;
    }
    
    return 3;
  }
  
  int getDisplayStatus() {
    final realStatus = getRealStatus();
    if (realStatus == 5) {
      return 5;
    }
    return realStatus;
  }

  String get statusString {
    switch (getRealStatus()) {
      case 0: return 'expired';
      case 1: return 'done';
      case 2: return 'inspection';
      case 3: return 'opened';
      case 5: return 'deleted';
      default: return 'unknown';
    }
  }

  bool get canUpload => (isOpened || isExpired) && !isDeletedStatus;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher': teacherWorkId,
      'name_spec': subjectName,
      'theme': theme,
      'comment': description,
      'creation_time': creationTime.toIso8601String(),
      'completion_time': completionTime.toIso8601String(),
      'overdue_time': overdueTime?.toIso8601String(),
      'filename': filename,
      'file_path': filePath,
      'status': status,
      'common_status': commonStatus,
      'homework_stud': homeworkStud?.toJson(),
      'homework_comment': homeworkComment?.toJson(),
      'cover_image': coverImage,
      'fio_teach': teacherName,
      'material_type': materialType,
      'is_deleted': isDeleted,
    };
  }

  String? get safeFilename {
    if (filename != null && filename!.isNotEmpty) {
      return filename;
    }
    
    if (filePath != null && filePath!.isNotEmpty) {
      final uri = Uri.parse(filePath!);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    }
    
    return 'homework_$id';
  }

  String? get safeStudentFilename {
    if (homeworkStud?.filename != null && homeworkStud!.filename!.isNotEmpty) {
      return homeworkStud!.filename;
    }
    
    if (homeworkStud?.filePath != null && homeworkStud!.filePath!.isNotEmpty) {
      final uri = Uri.parse(homeworkStud!.filePath!);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    }
    
    return homeworkStud != null ? 'student_work_$id' : null;
  }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'stud_answer': answerText,
      'file_path': filePath,
      'tmp_file': tmpfile,
      'mark': mark,
      'auto_mark': autoMark,
      'creation_time': creationTime.toIso8601String(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'text_comment': textComment,
      'attachment': attachment,
      'attachment_path': attachmentPath,
      'date_updated': dateUpdated.toIso8601String(),
    };
  }
}