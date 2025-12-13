class Account {
  final String id;
  final String username;
  final String fullName;
  final String groupName;
  final String photoPath;
  final String token;
  final DateTime lastLogin;
  final bool isActive;
  final int studentId;

  Account({
    required this.id,
    required this.username,
    required this.fullName,
    required this.groupName,
    required this.photoPath,
    required this.token,
    required this.lastLogin,
    required this.isActive,
    required this.studentId,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      groupName: json['groupName'] ?? '',
      photoPath: json['photoPath'] ?? '',
      token: json['token'] ?? '',
      lastLogin: DateTime.parse(json['lastLogin'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? false,
      studentId: json['studentId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'groupName': groupName,
      'photoPath': photoPath,
      'token': token,
      'lastLogin': lastLogin.toIso8601String(),
      'isActive': isActive,
      'studentId': studentId,
    };
  }

  Account copyWith({
    String? id,
    String? username,
    String? fullName,
    String? groupName,
    String? photoPath,
    String? token,
    DateTime? lastLogin,
    bool? isActive,
    int? studentId,
  }) {
    return Account(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      groupName: groupName ?? this.groupName,
      photoPath: photoPath ?? this.photoPath,
      token: token ?? this.token,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      studentId: studentId ?? this.studentId,
    );
  }

  @override
  String toString() {
    return 'Account(username: $username, fullName: $fullName, group: $groupName, active: $isActive)';
  }
}