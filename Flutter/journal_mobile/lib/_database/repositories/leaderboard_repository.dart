// lib/services/_database/repositories/leaderboard_repository.dart
import 'package:journal_mobile/models/leaderboard_user.dart';
import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../database_config.dart';

class LeaderboardRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> saveGroupLeaders(List<LeaderboardUser> leaders, String accountId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Удаляем старые данные
      await txn.delete(
        DatabaseConfig.tableGroupLeaders,  // Используем правильное имя
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      // Вставляем новых лидеров группы
      for (final leader in leaders) {
        await txn.insert(DatabaseConfig.tableGroupLeaders, {  // Используем правильное имя
          'account_id': accountId,
          'student_id': leader.studentId,
          'full_name': leader.fullName,
          'group_name': leader.groupName,
          'photo_path': leader.photoPath,
          'position': leader.position,
          'points': leader.points,
        }, conflictAlgorithm: ConflictAlgorithm.replace,);
      }
    });
  }

  Future<List<LeaderboardUser>> getGroupLeaders(String accountId) async {
    final leadersData = await _dbService.query(
      DatabaseConfig.tableGroupLeaders,  // Используем правильное имя
      where: 'account_id = ?',
      whereArgs: [accountId],
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

  Future<void> saveStreamLeaders(List<LeaderboardUser> leaders, String accountId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Удаляем старые данные
      await txn.delete(
        DatabaseConfig.tableStreamLeaders,  // Используем правильное имя
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      // Вставляем новых лидеров потока
      for (final leader in leaders) {
        await txn.insert(DatabaseConfig.tableStreamLeaders, {  // Используем правильное имя
          'account_id': accountId,
          'student_id': leader.studentId,
          'full_name': leader.fullName,
          'group_name': leader.groupName,
          'photo_path': leader.photoPath,
          'position': leader.position,
          'points': leader.points,
        }, conflictAlgorithm: ConflictAlgorithm.replace,);
      }
    });
  }

  Future<List<LeaderboardUser>> getStreamLeaders(String accountId) async {
    final leadersData = await _dbService.query(
      DatabaseConfig.tableStreamLeaders,  // Используем правильное имя
      where: 'account_id = ?',
      whereArgs: [accountId],
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

  Future<int> getLeadersCount(String accountId, bool isGroupLeaders) async {
    final tableName = isGroupLeaders 
      ? DatabaseConfig.tableGroupLeaders
      : DatabaseConfig.tableStreamLeaders;

    final result = await _dbService.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE account_id = ?',
      [accountId],
    );
    
    if (result.isEmpty) return 0;
    return result.first['count'] as int;
  }

  // Добавим дополнительные полезные методы
  Future<List<LeaderboardUser>> searchLeaders(String accountId, String searchQuery, bool isGroupLeaders) async {
    final tableName = isGroupLeaders 
      ? DatabaseConfig.tableGroupLeaders
      : DatabaseConfig.tableStreamLeaders;

    final leadersData = await _dbService.query(
      tableName,
      where: 'account_id = ? AND (full_name LIKE ? OR group_name LIKE ?)',
      whereArgs: [accountId, '%$searchQuery%', '%$searchQuery%'],
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
    final tableName = isGroupLeaders 
      ? DatabaseConfig.tableGroupLeaders
      : DatabaseConfig.tableStreamLeaders;

    final leadersData = await _dbService.query(
      tableName,
      where: 'account_id = ? AND student_id = ?',
      whereArgs: [accountId, studentId],
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
    final tableName = isGroupLeaders 
      ? DatabaseConfig.tableGroupLeaders
      : DatabaseConfig.tableStreamLeaders;

    await _dbService.delete(
      tableName,
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }
}