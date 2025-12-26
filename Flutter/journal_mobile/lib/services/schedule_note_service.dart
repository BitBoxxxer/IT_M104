import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:journal_mobile/_database/database_facade.dart';
import 'package:journal_mobile/services/_notification/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../models/_system/schedule_note.dart';

class ScheduleNoteService {
  final DatabaseFacade _databaseFacade = DatabaseFacade();
  NotificationService? _notificationService;
  
  static final ScheduleNoteService _instance = ScheduleNoteService._internal();
  factory ScheduleNoteService() => _instance;
  ScheduleNoteService._internal() {
    tz.initializeTimeZones();
  }
  
  Future<void> initialize() async {
    if (_notificationService == null) {
      _notificationService = NotificationService();
      await _notificationService!.initialize();
    }
  }
  
  String? _currentAccountId;
  
  Future<void> _ensureAccountId() async {
    if (_currentAccountId == null) {
      final account = await _databaseFacade.getCurrentAccount();
      _currentAccountId = account?.id;
    }
  }

  NotificationService get _safeNotificationService {
    if (_notificationService == null) {
      print('⚠️ NotificationService не инициализирован, создаем экземпляр');
      _notificationService = NotificationService();
      _notificationService!.initialize();
    }
    return _notificationService!;
  }
  
  Future<void> _showNoteReminderNotification(ScheduleNote note) async {
    await initialize();
    
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
    
    await _safeNotificationService.notifications.show(
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

  Future<void> _scheduleNoteReminder(ScheduleNote note) async {
    if (note.reminderTime == null || !note.reminderEnabled) return;
    
    final now = DateTime.now();
    if (note.reminderTime!.isBefore(now)) return;
    
    await _scheduleExactReminder(note);
    
    print('📅 Напоминание запланировано на ${note.reminderTime} для заметки: ${note.noteText}');
  }

  Future<void> _scheduleExactReminder(ScheduleNote note) async {
    await initialize();
    
    final androidDetails = const AndroidNotificationDetails(
      'schedule_notes_channel',
      'Напоминания заметок',
      channelDescription: 'Уведомления о заметках к расписанию',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: Colors.blue,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
    );
    
    final formattedDate = '${note.date.day}.${note.date.month}.${note.date.year}';
    
    await _safeNotificationService.notifications.zonedSchedule(
      note.id,
      'Напоминание о заметке',
      '${note.noteText}\nДата: $formattedDate',
      _scheduleReminderTime(note.reminderTime!),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'type': 'schedule_note_reminder',
        'note_id': note.id,
        'date': note.date.toIso8601String(),
      }),
    );
  }

  tz.TZDateTime _scheduleReminderTime(DateTime reminderTime) {
    // часовой пояс устройства из новой библиотеки [timezone]
    return tz.TZDateTime.from(reminderTime, tz.local);
  }

  Future<int> saveNote({
    required DateTime date,
    required String text,
    Color? color,
    DateTime? reminderTime,
    bool reminderEnabled = false,
    int? noteId,
  }) async {
    await _ensureAccountId();
    if (_currentAccountId == null) throw Exception('No account selected');
    
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    final note = ScheduleNote(
      id: noteId ?? 0,
      accountId: _currentAccountId!,
      date: normalizedDate,
      noteText: text,
      noteColor: color,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
    );
    
    final savedNoteId = await _databaseFacade.saveScheduleNote(note);
    
    if (reminderEnabled && reminderTime != null) {
      await _cancelScheduledReminder(savedNoteId);
      await _scheduleNoteReminder(note.copyWith(id: savedNoteId));
    }
    
    print('✅ Заметка ${noteId != null ? 'обновлена' : 'сохранена'} с ID: $savedNoteId');
    return savedNoteId;
  }

  Future<void> _cancelScheduledReminder(int noteId) async {
    try {
      await _safeNotificationService.notifications.cancel(noteId + 10000);
    } catch (e) {
      print('⚠️ Не удалось отменить напоминание для заметки $noteId: $e');
    }
  }

  Future<void> updateNoteReminder(int noteId, DateTime? reminderTime, bool enabled) async {
    await _ensureAccountId();
    if (_currentAccountId == null) return;
    
    final note = await _databaseFacade.getScheduleNoteById(noteId, _currentAccountId!);
    if (note == null) return;
    
    // отменить старое напоминание
    await _cancelScheduledReminder(noteId);
    
    final DateTime? finalReminderTime = enabled ? reminderTime : null;
    
    final updatedNote = note.copyWith(
      reminderTime: finalReminderTime,
      reminderEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    
    await _databaseFacade.saveScheduleNote(updatedNote);
    
    if (enabled && reminderTime != null) {
      await _scheduleNoteReminder(updatedNote);
    }
  }

  Future<void> deleteNote(int noteId) async {
    await _ensureAccountId();
    if (_currentAccountId == null) return;
    
    // отменить напоминание перед удалением
    await _cancelScheduledReminder(noteId);
    
    await _databaseFacade.deleteScheduleNote(noteId, _currentAccountId!);
    print('🗑️ Заметка $noteId удалена');
  }

  Future<void> scheduleAllReminders() async {
    await _ensureAccountId();
    if (_currentAccountId == null) return;
    
    final allNotes = await _databaseFacade.getAllScheduleNotes(_currentAccountId!);
    final now = DateTime.now();
    
    for (final note in allNotes) {
      if (note.reminderEnabled && 
          note.reminderTime != null && 
          note.reminderTime!.isAfter(now)) {
        
        await _cancelScheduledReminder(note.id);
        await _scheduleNoteReminder(note);
      }
    }
    
    print('✅ Все активные напоминания перепланированы');
  }

  /// метод для проверки и отправки просроченных напоминаний
  Future<void> checkOverdueReminders() async {
    await _ensureAccountId();
    if (_currentAccountId == null) return;
    
    final allNotes = await _databaseFacade.getAllScheduleNotes(_currentAccountId!);
    final now = DateTime.now();
    
    for (final note in allNotes) {
      if (note.reminderEnabled && 
          note.reminderTime != null && 
          note.reminderTime!.isBefore(now) &&
          note.reminderTime!.isAfter(now.subtract(Duration(days: 1)))) { // Только за последние 24 часа
        
        await _showNoteReminderNotification(note);
        // выполненное
        final updatedNote = note.copyWith(reminderEnabled: false);
        await _databaseFacade.saveScheduleNote(updatedNote);
      }
    }
  }

  Future<List<ScheduleNote>> getScheduledReminders() async {
    await _ensureAccountId();
    if (_currentAccountId == null) return [];
    
    final allNotes = await _databaseFacade.getAllScheduleNotes(_currentAccountId!);
    final now = DateTime.now();
    
    // Фильтруем только те, у которых есть будущие напоминания
    return allNotes.where((note) => 
      note.reminderEnabled && 
      note.reminderTime != null && 
      note.reminderTime!.isAfter(now)
    ).toList();
  }
}