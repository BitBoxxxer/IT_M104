// models/leaderboard_user.dart
class LeaderboardUser {
  final int studentId;
  final String fullName;
  final String groupName;
  final String photoPath;
  final int position;
  final int points;
  final int? totalPoints;

  LeaderboardUser({
    required this.studentId,
    required this.fullName,
    required this.groupName,
    required this.photoPath,
    required this.position,
    required this.points,
    this.totalPoints,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      studentId: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      groupName: json['group_name'] ?? '',
      photoPath: json['photo'] ?? '',
      position: json['position'] ?? 0,
      points: json['amount'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
    );
  }
}