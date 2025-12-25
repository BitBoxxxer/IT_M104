class DatabaseConfig {
  static const String databaseName = 'app_database.db';
  static const int databaseVersion = 1;

  static const SyncStrategy syncStrategy = SyncStrategy.merge;
  static const bool cleanupMissingItems = false;

  static const int leaderboardTypeGroup = 0;
  static const int leaderboardTypeStream = 1;
  
  // Названия таблиц - константы (Help me plz... im dying)
  static const String tableMarks = 'marks';
  static const String tableUsers = 'users';
  static const String tableSchedule = 'schedule';
  static const String tableAccounts = 'accounts';
  static const String tableNotifications = 'notifications';
  static const String tableExams = 'exams';
  static const String tableActivityRecords = 'activity_records';
  static const String tableFeedbackReviews = 'feedback_reviews';
  static const String tableHomeworks = 'homeworks';
  static const String tableHomeworkCounters = 'homework_counters';
  static const String tableLeaders = 'leaders';
  static const String tableCache = 'cache';
  static const String tableScheduleNotes = 'schedule_notes'; // практика
}

/// утилита для выбора стратегии поведения миграций БД
enum SyncStrategy {
  replace,   // Удалить всё и вставить новое
  merge,     // Объединить существующие и новые записи
  append,    // Добавить новые записи
}