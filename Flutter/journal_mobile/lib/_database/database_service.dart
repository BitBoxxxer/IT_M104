import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:async';

import 'database_config.dart';
import 'database_migrations.dart';
import './sqflite_init.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static Completer<Database>? _databaseCompleter;

  static Future<void> clearDatabaseCache() async {
    _database = null;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (_databaseCompleter != null) {
      return await _databaseCompleter!.future;
    }
    
    _databaseCompleter = Completer<Database>();
    
    try {
      if (!SqfliteInitializer.isInitialized) {
        await SqfliteInitializer.initialize();
      }
      
      _database = await _initDatabase();
      _databaseCompleter!.complete(_database);
      return _database!;
    } catch (e) {
      _databaseCompleter!.completeError(e);
      rethrow;
    } finally {
      _databaseCompleter = null;
    }
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), DatabaseConfig.databaseName);
    
    print('Путь БД: $path');
    
    return await openDatabase(
      path,
      version: DatabaseConfig.databaseVersion,
      onCreate: (Database db, int version) async {
        print('БД createtable');
        await DatabaseMigrations.createTables(db, version);
      },
      onUpgrade: DatabaseMigrations.upgradeDatabase,
      onDowngrade: (Database db, int oldVersion, int newVersion) async {
        print('Даунгрейд БД');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableMarks}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableUsers}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableSchedule}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableAccounts}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableNotifications}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableExams}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableActivityRecords}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableFeedbackReviews}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableHomeworks}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableHomeworkCounters}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableGroupLeaders}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableStreamLeaders}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.tableCache}');
        
        await DatabaseMigrations.createTables(db, newVersion);
      },
    );
  }

  // CRUDD 18.12.25


  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> clearTable(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> clearAllForAccount(String accountId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseConfig.tableMarks, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableUsers, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableSchedule, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableNotifications, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableExams, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableActivityRecords, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableFeedbackReviews, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableHomeworks, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableHomeworkCounters, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableGroupLeaders, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableStreamLeaders, where: 'account_id = ?', whereArgs: [accountId]);
      await txn.delete(DatabaseConfig.tableCache, where: 'account_id = ?', whereArgs: [accountId]);

      await txn.rawDelete('DELETE FROM sqlite_sequence');
    });
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<void> deleteDatabase() async {
    final path = join(await getDatabasesPath(), DatabaseConfig.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final stats = <String, int>{};

    final tables = [
      DatabaseConfig.tableMarks,
      DatabaseConfig.tableUsers,
      DatabaseConfig.tableSchedule,
      DatabaseConfig.tableAccounts,
      DatabaseConfig.tableNotifications,
      DatabaseConfig.tableExams,
      DatabaseConfig.tableActivityRecords,
      DatabaseConfig.tableFeedbackReviews,
      DatabaseConfig.tableHomeworks,
      DatabaseConfig.tableHomeworkCounters,
      DatabaseConfig.tableGroupLeaders,
      DatabaseConfig.tableStreamLeaders,
      DatabaseConfig.tableCache,
    ];

    for (var table in tables) {
      try {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $table')
        ) ?? 0;
        stats[table] = count;
      } catch (e) {
        stats[table] = 0;
      }
    }

    return stats;
  }
}