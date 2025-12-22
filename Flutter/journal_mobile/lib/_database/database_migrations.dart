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
        student_id INTEGER,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
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
        sync_timestamp INTEGER DEFAULT (strftime('%s', 'now')),
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
        sync_timestamp INTEGER DEFAULT (strftime('%s', 'now')),
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
        sync_timestamp INTEGER DEFAULT (strftime('%s', 'now')),
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
        sync_timestamp INTEGER DEFAULT (strftime('%s', 'now')),
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
        lesson_subject TEXT,
        lesson_theme TEXT,
        sync_timestamp INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableFeedbackReviews} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        teacher_name TEXT NOT NULL,
        subject TEXT NOT NULL,
        feedback_text TEXT NOT NULL,
        date TEXT,
        sync_timestamp INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableHomeworks} (
        id INTEGER PRIMARY KEY,
        account_id TEXT NOT NULL,
        teacher_work_id INTEGER,
        subject_name TEXT NOT NULL,
        theme TEXT NOT NULL,
        description TEXT,
        creation_time INTEGER NOT NULL,
        completion_time INTEGER NOT NULL,
        overdue_time INTEGER,
        filename TEXT,
        file_path TEXT,
        comment TEXT,
        status INTEGER DEFAULT 0,
        common_status INTEGER DEFAULT 0,
        cover_image TEXT,
        teacher_name TEXT,
        material_type INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        
        -- Поля HomeworkStud
        homework_stud_id INTEGER,
        homework_stud_filename TEXT,
        homework_stud_answer_text TEXT,
        homework_stud_file_path TEXT,
        homework_stud_tmpfile TEXT,
        homework_stud_mark REAL,
        homework_stud_auto_mark INTEGER DEFAULT 0,
        homework_stud_creation_time INTEGER,
        
        -- Поля HomeworkComment
        homework_comment_text TEXT,
        homework_comment_attachment TEXT,
        homework_comment_attachment_path TEXT,
        homework_comment_date_updated INTEGER,
        
        sync_timestamp INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableHomeworkCounters} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        type INTEGER DEFAULT 0,
        group_id INTEGER,
        spec_id INTEGER,
        status INTEGER DEFAULT 0,
        count INTEGER DEFAULT 0,
        sync_timestamp INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableGroupLeaders} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        student_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        group_name TEXT NOT NULL,
        photo_path TEXT,
        position INTEGER NOT NULL,
        points INTEGER NOT NULL,
        total_points INTEGER,
        sync_timestamp INTEGER NOT NULL,
        UNIQUE(account_id, student_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConfig.tableStreamLeaders} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        student_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        group_name TEXT NOT NULL,
        photo_path TEXT,
        position INTEGER NOT NULL,
        points INTEGER NOT NULL,
        total_points INTEGER,
        sync_timestamp INTEGER NOT NULL,
        UNIQUE(account_id, student_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tableCache} (
        key TEXT PRIMARY KEY,
        account_id TEXT,
        value TEXT NOT NULL,
        expiry INTEGER,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (account_id) REFERENCES ${DatabaseConfig.tableAccounts}(id) ON DELETE CASCADE
      )
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
         // Будущие версии миграций можно добавить здесь
         /* case 2:
           await _migrateToVersion2(db);
           break; */
      }
    }
  }
}