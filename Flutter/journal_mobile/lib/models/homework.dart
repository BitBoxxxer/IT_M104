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
    // 1. САМЫЙ ПРИОРИТЕТНЫЙ: проверяем явное поле isDeleted
    if (isDeleted == true) {
      return 5; // DELETED
    }
    
    // 2. Проверяем старые способы определения удаления
    if (status == 5 || commonStatus == 5) {
      return 5; // DELETED
    }
    
    // 3. Если работа помечена как удаленная в теме или описании
    if (theme.toLowerCase().contains('удален') || 
        (description?.toLowerCase().contains('удален') == true)) {
      return 5; // DELETED
    }
    
    // 4. ОСТАЛЬНАЯ ЛОГИКА СТАТУСОВ для НЕудаленных работ
    
    // Если работа сдана и есть оценка - проверено
    if (homeworkStud?.mark != null) {
      return 1; // DONE
    }
    
    // Если работа сдана, но нет оценки - на проверке
    if (homeworkStud != null) {
      return 2; // INSPECTION
    }
    
    // Если срок сдачи прошел - просрочено
    final now = DateTime.now();
    if (now.isAfter(completionTime)) {
      return 0; // EXPIRED
    }
    
    // Во всех остальных случаях - активно
    return 3; // OPENED
  }
  
  // Добавим метод для получения "чистого" статуса без удаления
  int getDisplayStatus() {
    final realStatus = getRealStatus();
    // Если работа удалена, возвращаем специальный статус
    if (realStatus == 5) {
      return 5; // DELETED
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