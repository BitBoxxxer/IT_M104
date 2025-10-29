class Exam {
  final String subjectName;
  final String specName;
  final dynamic grade;
  final dynamic value;
  final String date;
  final String? teacherName;

  Exam({
    required this.subjectName,
    required this.specName,
    required this.grade,
    this.value,
    required this.date,
    this.teacherName,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      subjectName: json['spec']?.toString() ?? json['subject_name']?.toString() ?? 'Неизвестный предмет',
      specName: json['spec_name']?.toString() ?? json['subject_name']?.toString() ?? 'Неизвестный предмет',
      grade: json['grade'] ?? json['value'] ?? json['mark'],
      date: json['date']?.toString() ?? '',
      teacherName: json['teacher']?.toString(),
    );
  }

  bool get isFuture {
    try {
      if (date.isEmpty || date == 'null') return true;
      
      final examDate = DateTime.parse(date);
      final now = DateTime.now();
      return examDate.isAfter(now);
    } catch (e) {
      return true;
    }
  }

  bool get isPast {
    return !isFuture;
  }

  String get displayGrade {
    if (isFuture) return 'Ожидается';

    final gradeValue = grade ?? value;
    
    if (gradeValue != null) {
      if (gradeValue is int) {
        return gradeValue > 0 ? gradeValue.toString() : 'Ожидается';
      }
      if (gradeValue is double) {
        return gradeValue > 0 ? gradeValue.toStringAsFixed(1) : 'Ожидается';
      }
      if (gradeValue is String) {
        final gradeStr = gradeValue.toString().trim();
        if (gradeStr.isNotEmpty && gradeStr != 'null' && gradeStr != '0') {
          return gradeStr;
        }
      }
    }
    
    return 'Ожидается';
  }

  bool get isPassed {
    if (isFuture) return false;

    final gradeValue = grade ?? value;
    
    if (gradeValue == null) return false;
    
    if (gradeValue is num) {
      return gradeValue > 0;
    }
    
    if (gradeValue is String) {
      final gradeStr = gradeValue.toString().toLowerCase();
      return gradeStr.isNotEmpty && 
             gradeStr != '0' && 
             gradeStr != 'null' && 
             !gradeStr.contains('не сдан') &&
             !gradeStr.contains('незачет');
    }
    
    return false;
  }

  bool get hasGrade {
    if (isFuture) return false;
    
    final gradeValue = grade ?? value;
    if (gradeValue == null) return false;
    
    if (gradeValue is num) {
      return gradeValue > 0;
    }
    
    if (gradeValue is String) {
      final gradeStr = gradeValue.toString().trim();
      return gradeStr.isNotEmpty && gradeStr != 'null' && gradeStr != '0';
    }
    
    return false;
  }

  int? get numericGrade {
    if (isFuture) return null;
    
    final gradeValue = grade ?? value;
    if (gradeValue is int && gradeValue > 0) return gradeValue;
    if (gradeValue is double && gradeValue > 0) return gradeValue.round();
    if (gradeValue is String) {
      final parsed = int.tryParse(gradeValue);
      return parsed != null && parsed > 0 ? parsed : null;
    }
    return null;
  }
}