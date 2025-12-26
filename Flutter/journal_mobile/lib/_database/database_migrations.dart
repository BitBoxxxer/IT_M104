import 'package:sqflite/sqflite.dart';

import 'database_config.dart';

/// создания таблиц [DBMigration] create table
class DatabaseMigrations {
  static Future<void> createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableAccounts} (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        full_name TEXT,
        group_name TEXT,
        photo_path TEXT,
        token TEXT NOT NULL,
        last_login TEXT,
        is_active INTEGER DEFAULT 0,
        student_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableMarks} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        spec_name TEXT NOT NULL,
        lesson_theme TEXT,
        date_visit TEXT,
        home_work_mark INTEGER,
        control_work_mark INTEGER,
        lab_work_mark INTEGER,
        class_work_mark INTEGER,
        practical_work_mark INTEGER,
        final_work_mark INTEGER,
        status_was INTEGER,
        UNIQUE(account_id, spec_name, lesson_theme, date_visit),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableUsers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        student_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        group_name TEXT NOT NULL,
        photo_path TEXT,
        position INTEGER DEFAULT 0,
        points_info TEXT,
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableSchedule} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        date TEXT NOT NULL,
        started_at TEXT NOT NULL,
        finished_at TEXT NOT NULL,
        lesson INTEGER NOT NULL,
        room_name TEXT,
        subject_name TEXT NOT NULL,
        teacher_name TEXT,
        UNIQUE(account_id, started_at, date),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableNotifications} (
        id INTEGER PRIMARY KEY,
        account_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        payload TEXT,
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableExams} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        spec TEXT NOT NULL,
        mark TEXT,
        date TEXT,
        teacher TEXT,
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableActivityRecords} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        date TEXT NOT NULL,
        action INTEGER DEFAULT 0,
        current_point INTEGER DEFAULT 0,
        point_types_id INTEGER DEFAULT 0,
        point_types_name TEXT,
        achievements_id INTEGER,
        achievements_name TEXT,
        achievements_type INTEGER,
        badge INTEGER DEFAULT 0,
        old_competition INTEGER DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableFeedbackReviews} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        teacher TEXT NOT NULL,
        spec TEXT NOT NULL,
        message TEXT NOT NULL,
        date TEXT,
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableHomeworks} (
        id INTEGER PRIMARY KEY,
        account_id TEXT NOT NULL,
        teacher_work_id INTEGER,
        teacher_name TEXT,
        subject_name TEXT NOT NULL,
        theme TEXT NOT NULL,
        description TEXT,
        creation_time INTEGER NOT NULL,
        completion_time INTEGER NOT NULL,
        overdue_time INTEGER,
        file_path TEXT,
        comment TEXT,
        status INTEGER DEFAULT 0,
        common_status INTEGER DEFAULT 0,
        homework_stud TEXT,
        homework_comment TEXT,
        cover_image TEXT,
        material_type INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        UNIQUE(account_id, teacher_work_id, file_path, material_type),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableHomeworkCounters} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        counter_type INTEGER DEFAULT 0,
        group_id INTEGER,
        spec_id INTEGER,
        status INTEGER DEFAULT 0,
        counter INTEGER DEFAULT 0,
        UNIQUE(account_id, counter_type, status),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableLeaders} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        student_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        group_name TEXT NOT NULL,
        photo_path TEXT,
        position INTEGER NOT NULL,
        points INTEGER NOT NULL,
        leaderboard_type INTEGER NOT NULL DEFAULT 0, -- 0 = группа, 1 = поток
        UNIQUE(account_id, student_id, leaderboard_type),
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableCache} (
        key TEXT PRIMARY KEY,
        account_id TEXT,
        value TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    // практика
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableScheduleNotes} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        date TEXT NOT NULL,
        note_text TEXT NOT NULL,
        note_color INTEGER,
        reminder_time TEXT,
        reminder_enabled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_schedule_notes_account_date 
      ON ${DatabaseConfig.tableScheduleNotes}(account_id, date);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_marks_account ON ${DatabaseConfig.tableMarks}(account_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_marks_date ON ${DatabaseConfig.tableMarks}(date_visit);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_schedule_account_date ON ${DatabaseConfig.tableSchedule}(account_id, date);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_account_timestamp ON ${DatabaseConfig.tableNotifications}(account_id, timestamp DESC);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_homeworks_account_type ON ${DatabaseConfig.tableHomeworks}(account_id, material_type);
    ''');
  }

  static Future<void> upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 1:
          await createTables(db, version);
          break;
      }
    }
  }
}