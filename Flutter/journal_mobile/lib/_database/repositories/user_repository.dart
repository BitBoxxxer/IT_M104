import 'package:journal_mobile/models/user_data.dart';
import 'dart:convert';
import '../database_service.dart';
import '../database_config.dart';

class UserRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveUserData(UserData user, String accountId) async {
    await _dbService.delete(
      DatabaseConfig.tableUsers,
      where: 'account_id = ?',
      whereArgs: [accountId],
    );

    await _dbService.insert(DatabaseConfig.tableUsers, {
      'account_id': accountId,
      'student_id': user.studentId,
      'full_name': user.fullName,
      'group_name': user.groupName,
      'photo_path': user.photoPath,
      'position': user.position,
      'points_info': jsonEncode(user.pointsInfo),
      'sync_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<UserData?> getUserData(String accountId) async {
    final userData = await _dbService.query(
      DatabaseConfig.tableUsers,
      where: 'account_id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (userData.isEmpty) return null;

    final data = userData.first;
    return UserData.fromJson({
      'student_id': data['student_id'],
      'full_name': data['full_name'],
      'group_name': data['group_name'],
      'photo': data['photo_path'],
      'position': data['position'],
      'gaming_points': jsonDecode(data['points_info'] as String? ?? '[]'),
    });
  }
}