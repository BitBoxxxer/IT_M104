class Exam {
  final String subjectName;
  final dynamic grade;
  final dynamic value;
  final String date;
  final String? teacherName;

  Exam({
    required this.subjectName,
    required this.grade,
    this.value,
    required this.date,
    this.teacherName,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing Exam JSON: $json');
    return Exam(
      subjectName: json['spec']?.toString() ?? 'Неизвестный предмет',
      grade: json['mark'],
      date: json['date']?.toString() ?? '',
      teacherName: json['teacher']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spec': subjectName,
      'mark': grade,
      'date': date,
      'teacher': teacherName,
    };
  }

  bool get isTwelvePointSystem {
    try {
      if (date.isEmpty || date == 'null') return false;
      
      final examDate = DateTime.parse(date);
      final transitionDate = DateTime(2024, 9, 1);
      // Стас сказал с 24 года 1 сент. 
      // - ввели 5-ую систему оценивания
      
      return examDate.isBefore(transitionDate);
    } catch (e) {
      return false;
    }
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
    
    if (gradeValue is int && gradeValue > 0) {
      return _convertToFivePointSystem(gradeValue);
    }
    if (gradeValue is double && gradeValue > 0) {
      return _convertToFivePointSystem(gradeValue.round());
    }
    if (gradeValue is String) {
      final parsed = int.tryParse(gradeValue);
      return parsed != null && parsed > 0 ? _convertToFivePointSystem(parsed) : null;
    }
    return null;
  }

  int _convertToFivePointSystem(int grade) {
    if (!isTwelvePointSystem) {
      return grade;
    }
    
    switch (grade) {
      case 12:
      case 11:
      case 10:
        return 5;
      case 9:
      case 8:
        return 4;
      case 7:
      case 6:
      case 5:
        return 3;
      case 4:
      case 3:
      case 2:
      case 1:
        return 2;
      default:
        return grade;
    }
  }

  int? get originalNumericGrade {
    if (isFuture) return null;
    
    final gradeValue = grade ?? value;
    if (gradeValue is int && gradeValue > 0) return gradeValue;
    if (gradeValue is double && gradeValue > 0) return gradeValue.round();
    if (gradeValue is String) {
      return int.tryParse(gradeValue);
    }
    return null;
  }
}