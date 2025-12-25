import 'package:journal_mobile/models/leaderboard_user.dart';
import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../database_config.dart';

class LeaderboardRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveLeaders(List<LeaderboardUser> leaders, String accountId, int leaderboardType) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Удаляем старые данные для данного типа
      await txn.delete(
        DatabaseConfig.tableLeaders,
        where: 'account_id = ? AND leaderboard_type = ?',
        whereArgs: [accountId, leaderboardType],
      );

      // Вставляем новых лидеров
      for (final leader in leaders) {
        await txn.insert(DatabaseConfig.tableLeaders, {
          'account_id': accountId,
          'student_id': leader.studentId,
          'full_name': leader.fullName,
          'group_name': leader.groupName,
          'photo_path': leader.photoPath,
          'position': leader.position,
          'points': leader.points,
          'leaderboard_type': leaderboardType,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<LeaderboardUser>> getLeaders(String accountId, int leaderboardType) async {
    final leadersData = await _dbService.query(
      DatabaseConfig.tableLeaders,
      where: 'account_id = ? AND leaderboard_type = ?',
      whereArgs: [accountId, leaderboardType],
      orderBy: 'position ASC',
    );

    return leadersData.map((data) => LeaderboardUser.fromJson({
      'id': data['student_id'],
      'full_name': data['full_name'],
      'group_name': data['group_name'],
      'photo_path': data['photo_path'],
      'position': data['position'],
      'amount': data['points'],
    })).toList();
  }

  // Методы для обратной совместимости
  Future<void> saveGroupLeaders(List<LeaderboardUser> leaders, String accountId) async {
    await saveLeaders(leaders, accountId, DatabaseConfig.leaderboardTypeGroup);
  }

  Future<List<LeaderboardUser>> getGroupLeaders(String accountId) async {
    return await getLeaders(accountId, DatabaseConfig.leaderboardTypeGroup);
  }

  Future<void> saveStreamLeaders(List<LeaderboardUser> leaders, String accountId) async {
    await saveLeaders(leaders, accountId, DatabaseConfig.leaderboardTypeStream);
  }

  Future<List<LeaderboardUser>> getStreamLeaders(String accountId) async {
    return await getLeaders(accountId, DatabaseConfig.leaderboardTypeStream);
  }

  // Остальные методы обновляем аналогично
  Future<int> getLeadersCount(String accountId, bool isGroupLeaders) async {
    final leaderboardType = isGroupLeaders 
      ? DatabaseConfig.leaderboardTypeGroup
      : DatabaseConfig.leaderboardTypeStream;

    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableLeaders} WHERE account_id = ? AND leaderboard_type = ?',
      [accountId, leaderboardType],
    );
    
    if (result.isEmpty) return 0;
    return result.first['count'] as int;
  }

  Future<List<LeaderboardUser>> searchLeaders(String accountId, String searchQuery, bool isGroupLeaders) async {
    final leaderboardType = isGroupLeaders 
      ? DatabaseConfig.leaderboardTypeGroup
      : DatabaseConfig.leaderboardTypeStream;

    final leadersData = await _dbService.query(
      DatabaseConfig.tableLeaders,
      where: 'account_id = ? AND leaderboard_type = ? AND (full_name LIKE ? OR group_name LIKE ?)',
      whereArgs: [accountId, leaderboardType, '%$searchQuery%', '%$searchQuery%'],
      orderBy: 'position ASC',
    );

    return leadersData.map((data) => LeaderboardUser.fromJson({
      'id': data['student_id'],
      'full_name': data['full_name'],
      'group_name': data['group_name'],
      'photo_path': data['photo_path'],
      'position': data['position'],
      'amount': data['points'],
    })).toList();
  }

  Future<LeaderboardUser?> getUserPosition(String accountId, int studentId, bool isGroupLeaders) async {
    final leaderboardType = isGroupLeaders 
      ? DatabaseConfig.leaderboardTypeGroup
      : DatabaseConfig.leaderboardTypeStream;

    final leadersData = await _dbService.query(
      DatabaseConfig.tableLeaders,
      where: 'account_id = ? AND student_id = ? AND leaderboard_type = ?',
      whereArgs: [accountId, studentId, leaderboardType],
      limit: 1,
    );

    if (leadersData.isEmpty) return null;

    final data = leadersData.first;
    return LeaderboardUser.fromJson({
      'id': data['student_id'],
      'full_name': data['full_name'],
      'group_name': data['group_name'],
      'photo_path': data['photo_path'],
      'position': data['position'],
      'amount': data['points'],
    });
  }

  Future<void> clearLeaders(String accountId, bool isGroupLeaders) async {
    final leaderboardType = isGroupLeaders 
      ? DatabaseConfig.leaderboardTypeGroup
      : DatabaseConfig.leaderboardTypeStream;

    await _dbService.delete(
      DatabaseConfig.tableLeaders,
      where: 'account_id = ? AND leaderboard_type = ?',
      whereArgs: [accountId, leaderboardType],
    );
  }
}