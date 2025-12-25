import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:journal_mobile/_database/database_facade.dart';
import 'package:journal_mobile/services/_notification/notification_service.dart';

import '../models/_system/schedule_note.dart';

class ScheduleNoteService {
  final DatabaseFacade _databaseFacade = DatabaseFacade();
  late final NotificationService _notificationService;
  
  static final ScheduleNoteService _instance = ScheduleNoteService._internal();
  factory ScheduleNoteService() => _instance;
  ScheduleNoteService._internal() {
    _notificationService = NotificationService();
  }
  
  Future<void> initialize() async {
    await _notificationService.initialize();
  }
  
  String? _currentAccountId;
  
  Future<void> _ensureAccountId() async {
    if (_currentAccountId == null) {
      final account = await _databaseFacade.getCurrentAccount();
      _currentAccountId = account?.id;
    }
  }
  
  Future<int> saveNote({
    required DateTime date,
    required String text,
    Color? color,
    DateTime? reminderTime,
    bool reminderEnabled = false,
  }) async {
    await _ensureAccountId();
    if (_currentAccountId == null) throw Exception('No account selected');
    
    // Нормализуем дату (убираем время)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    final note = ScheduleNote(
      accountId: _currentAccountId!,
      date: normalizedDate,
      noteText: text,
      noteColor: color,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
    );
    
    final noteId = await _databaseFacade.saveScheduleNote(note);
    
    if (reminderEnabled && reminderTime != null) {
      await _scheduleNoteReminder(note.copyWith(id: noteId));
    }
    
    print('✅ Заметка сохранена с ID: $noteId');
    return noteId;
  }
  
  Future<void> updateNoteReminder(int noteId, DateTime? reminderTime, bool enabled) async {
    await _ensureAccountId();
    if (_currentAccountId == null) return;
    
    final note = await _databaseFacade.getScheduleNoteById(noteId, _currentAccountId!);
    if (note == null) return;
    
    final updatedNote = note.copyWith(
      reminderTime: reminderTime,
      reminderEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    
    await _databaseFacade.saveScheduleNote(updatedNote);
    
    if (enabled && reminderTime != null) {
      await _scheduleNoteReminder(updatedNote);
    }
  }
  
  Future<void> _scheduleNoteReminder(ScheduleNote note) async {
    if (note.reminderTime == null || !note.reminderEnabled) return;
    
    final now = DateTime.now();
    if (note.reminderTime!.isBefore(now)) return;
    
    await _showNoteReminderNotification(note);
    
    print('📅 Напоминание запланировано на ${note.reminderTime} для заметки: ${note.noteText}');
  }
  
  Future<void> _showNoteReminderNotification(ScheduleNote note) async {
    final formattedDate = '${note.date.day}.${note.date.month}.${note.date.year}';
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'schedule_notes_channel',
      'Напоминания заметок',
      channelDescription: 'Уведомления о заметках к расписанию',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: Colors.blue,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    
    await _notificationService.notifications.show(
      note.id + 10000,
      '📝 Напоминание о заметке',
      '${note.noteText}\nДата: $formattedDate',
      details,
      payload: jsonEncode({
        'type': 'schedule_note_reminder',
        'note_id': note.id,
        'date': note.date.toIso8601String(),
      }),
    );
  }
  
  Future<void> checkAndTriggerReminders() async {
    await _ensureAccountId();
    if (_currentAccountId == null) return;
    
    final notesWithReminders = await _databaseFacade.getNotesWithReminders(_currentAccountId!);
    final now = DateTime.now();
    
    for (final note in notesWithReminders) {
      if (note.reminderTime != null && 
          note.reminderTime!.isBefore(now.add(const Duration(seconds: 30))) &&
          note.reminderTime!.isAfter(now.subtract(const Duration(seconds: 30)))) {
        
        await _showNoteReminderNotification(note);
        
        final updatedNote = note.copyWith(reminderEnabled: false);
        await _databaseFacade.saveScheduleNote(updatedNote);
      }
    }
  }
  
  Future<List<ScheduleNote>> getUpcomingReminders({int limit = 5}) async {
    await _ensureAccountId();
    if (_currentAccountId == null) return [];
    
    return await _databaseFacade.getUpcomingReminders(_currentAccountId!, limit: limit);
  }
  
  Future<List<ScheduleNote>> getNotesForDate(DateTime date) async {
    await _ensureAccountId();
    if (_currentAccountId == null) return [];
    
    return await _databaseFacade.getScheduleNotesForDate(_currentAccountId!, date);
  }
  
  Future<void> deleteNote(int noteId) async {
    await _ensureAccountId();
    if (_currentAccountId == null) return;
    
    await _databaseFacade.deleteScheduleNote(noteId, _currentAccountId!);
    print('🗑️ Заметка $noteId удалена');
  }

  Future<void> scheduleNoteRemindersForBackground() async {
    await _ensureAccountId();
    if (_currentAccountId == null) return;
    
    final notesWithReminders = await _databaseFacade.getNotesWithReminders(_currentAccountId!);
    final now = DateTime.now();
    
    print('🔔 Планирование напоминаний для ${notesWithReminders.length} заметок');
    
    for (final note in notesWithReminders) {
      if (note.reminderTime != null && note.reminderTime!.isAfter(now)) {
        await _scheduleBackgroundReminder(note);
      }
    }
  }

  Future<void> _scheduleBackgroundReminder(ScheduleNote note) async {
    if (note.reminderTime == null || !note.reminderEnabled) return;
    
    final now = DateTime.now();
    final delay = note.reminderTime!.difference(now);
    
    if (delay.inMinutes <= 15 && delay.inSeconds > 0) {
      await _showNoteReminderNotification(note);
    }
    
    print('⏰ Запланировано фоновое напоминание на ${note.reminderTime}');
  }
}