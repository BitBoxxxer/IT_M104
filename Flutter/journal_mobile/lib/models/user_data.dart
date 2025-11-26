class UserData {
  final int studentId;
  final String fullName;
  final String groupName;
  final String photoPath;
  final List<Map<String, dynamic>> pointsInfo;
  final int position;

  UserData({
    required this.studentId,
    required this.fullName,
    required this.groupName,
    required this.photoPath,
    required this.position,
    required this.pointsInfo,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> pointsList = [];
    if (json['gaming_points'] is List) {
      pointsList = List<Map<String, dynamic>>.from(json['gaming_points']);
    }
    
    return UserData(
      studentId: json['student_id'],
      fullName: json['full_name'],
      groupName: json['group_name'],
      photoPath: json['photo'] ?? "",
      pointsInfo: pointsList,
      position: json['position'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'full_name': fullName,
      'group_name': groupName,
      'photo': photoPath,
      'position': position,
      'gaming_points': pointsInfo,
    };
  }
}