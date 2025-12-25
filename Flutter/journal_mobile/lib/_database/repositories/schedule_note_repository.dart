import 'dart:async';
import 'dart:ui';
import 'package:sqflite/sqflite.dart';
import '../../models/_system/schedule_note.dart';
import '../database_service.dart';
import '../database_config.dart';

class ScheduleNoteRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<int> saveNote(ScheduleNote note) async {
    final db = await _dbService.database;
    
    // НЕ ПЕРЕДАВАЙТЕ ID, если он 0 или null - база сама сгенерирует
    final data = note.toJson();
    
    if (note.id == 0) {
      // УДАЛИТЕ id из данных перед вставкой
      data.remove('id');
      
      final insertedId = await db.insert(
        DatabaseConfig.tableScheduleNotes,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return insertedId;
    } else {
      await db.update(
        DatabaseConfig.tableScheduleNotes,
        data,
        where: 'id = ? AND account_id = ?',
        whereArgs: [note.id, note.accountId],
      );
      return note.id;
    }
  }

  Future<int> saveNewNote(String accountId, DateTime date, String text, {Color? color}) async {
    final note = ScheduleNote(
      accountId: accountId,
      date: date,
      noteText: text,
      noteColor: color,
    );
    
    return await saveNote(note);
  }

  Future<List<ScheduleNote>> getNotesForDate(String accountId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    
    final notesData = await _dbService.query(
      DatabaseConfig.tableScheduleNotes,
      where: 'account_id = ? AND date = ?',
      whereArgs: [accountId, dateStr],
      orderBy: 'created_at DESC',
    );

    return notesData.map((data) => ScheduleNote.fromJson(data)).toList();
  }

  Future<List<ScheduleNote>> getAllNotes(String accountId) async {
    final notesData = await _dbService.query(
      DatabaseConfig.tableScheduleNotes,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC, created_at DESC',
    );

    return notesData.map((data) => ScheduleNote.fromJson(data)).toList();
  }

  Future<ScheduleNote?> getNoteById(int noteId, String accountId) async {
    final notesData = await _dbService.query(
      DatabaseConfig.tableScheduleNotes,
      where: 'id = ? AND account_id = ?',
      whereArgs: [noteId, accountId],
      limit: 1,
    );

    if (notesData.isEmpty) return null;
    return ScheduleNote.fromJson(notesData.first);
  }

  Future<List<ScheduleNote>> getNotesWithReminders(String accountId) async {
    final now = DateTime.now().toIso8601String();
    
    final notesData = await _dbService.rawQuery('''
      SELECT * FROM ${DatabaseConfig.tableScheduleNotes}
      WHERE account_id = ? 
        AND reminder_enabled = 1 
        AND reminder_time > ?
      ORDER BY reminder_time ASC
    ''', [accountId, now]);

    return notesData.map((data) => ScheduleNote.fromJson(data)).toList();
  }

  Future<List<ScheduleNote>> getUpcomingReminders(String accountId, {int limit = 10}) async {
    final now = DateTime.now().toIso8601String();
    
    final notesData = await _dbService.rawQuery('''
      SELECT * FROM ${DatabaseConfig.tableScheduleNotes}
      WHERE account_id = ? 
        AND reminder_enabled = 1 
        AND reminder_time > ?
      ORDER BY reminder_time ASC
      LIMIT ?
    ''', [accountId, now, limit]);

    return notesData.map((data) => ScheduleNote.fromJson(data)).toList();
  }

  Future<int> deleteNote(int noteId, String accountId) async {
    return await _dbService.delete(
      DatabaseConfig.tableScheduleNotes,
      where: 'id = ? AND account_id = ?',
      whereArgs: [noteId, accountId],
    );
  }

  Future<int> deleteNotesForDate(String accountId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    
    return await _dbService.delete(
      DatabaseConfig.tableScheduleNotes,
      where: 'account_id = ? AND date = ?',
      whereArgs: [accountId, dateStr],
    );
  }

  Future<int> clearAllNotes(String accountId) async {
    return await _dbService.delete(
      DatabaseConfig.tableScheduleNotes,
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  Stream<List<ScheduleNote>> watchNotesForDate(String accountId, DateTime date) {
    final controller = StreamController<List<ScheduleNote>>.broadcast();
    
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      final notes = await getNotesForDate(accountId, date);
      controller.add(notes);
    });
    
    return controller.stream;
  }
}