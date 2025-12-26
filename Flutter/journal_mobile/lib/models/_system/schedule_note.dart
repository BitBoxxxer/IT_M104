import 'package:flutter/material.dart';

class ScheduleNote {
  final int id;
  final String accountId;
  final DateTime date;
  final String noteText;
  final Color? noteColor;
  final DateTime? reminderTime;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleNote({
    this.id = 0,
    required this.accountId,
    required this.date,
    required this.noteText,
    this.noteColor,
    this.reminderTime,
    this.reminderEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'account_id': accountId,
    'date': date.toIso8601String(),
    'note_text': noteText,
    'note_color': noteColor?.value,
    'reminder_time': reminderTime?.toIso8601String(),
    'reminder_enabled': reminderEnabled ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ScheduleNote.fromJson(Map<String, dynamic> json) {
    return ScheduleNote(
      id: json['id'] as int,
      accountId: json['account_id'] as String,
      date: DateTime.parse(json['date']),
      noteText: json['note_text'] as String,
      noteColor: json['note_color'] != null 
          ? Color(json['note_color'] as int) 
          : null,
      reminderTime: json['reminder_time'] != null 
          ? DateTime.parse(json['reminder_time']) 
          : null,
      reminderEnabled: (json['reminder_enabled'] as int) == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  ScheduleNote copyWith({
    int? id,
    String? accountId,
    DateTime? date,
    String? noteText,
    Color? noteColor,
    DateTime? reminderTime,
    bool? reminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleNote(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      noteText: noteText ?? this.noteText,
      noteColor: noteColor ?? this.noteColor,
      reminderTime: (reminderEnabled ?? this.reminderEnabled) ? 
          (reminderTime ?? this.reminderTime) : null,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}