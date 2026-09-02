import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:glassmorphic_ui/glassmorphic_ui.dart';
import 'package:intl/intl.dart';
import 'package:journal_mobile/services/schedule_note_service.dart';

import '../_system/schedule_note.dart';
import '../_system/futuristic_theme.dart';

class NoteDialog extends StatefulWidget {
  final DateTime date;
  final ScheduleNote? existingNote;
  final VoidCallback? onNoteSaved;
  
  const NoteDialog({
    super.key,
    required this.date,
    this.existingNote,
    this.onNoteSaved,
  });
  
  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _noteService = ScheduleNoteService();
  final _textController = TextEditingController();
  final _reminderTimeController = TextEditingController();
  
  Color _selectedColor = Colors.blue;
  bool _reminderEnabled = false;
  DateTime? _reminderTime;
  
  @override
  void initState() {
    super.initState();
    
    // Если редактируем существующую заметку
    if (widget.existingNote != null) {
      _textController.text = widget.existingNote!.noteText;
      _selectedColor = widget.existingNote!.noteColor ?? Colors.blue;
      _reminderEnabled = widget.existingNote!.reminderEnabled;
      _reminderTime = widget.existingNote!.reminderTime;
      
      if (_reminderTime != null) {
        _reminderTimeController.text = DateFormat('HH:mm').format(_reminderTime!);
      }
    }
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _reminderTimeController.dispose();
    super.dispose();
  }
  
  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _reminderTime = DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          picked.hour,
          picked.minute,
        );
        _reminderTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _reminderEnabled = true;
      });
    }
  }
  
  Future<void> _saveNote() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст заметки')),
      );
      return;
    }
    
    try {
      if (widget.existingNote != null) {
        final DateTime? reminderTime = _reminderEnabled ? _reminderTime : null;
        
        await _noteService.saveNote(
          noteId: widget.existingNote!.id,
          date: widget.date,
          text: _textController.text,
          color: _selectedColor,
          reminderTime: reminderTime,
          reminderEnabled: _reminderEnabled,
        );
      } else {
        final DateTime? reminderTime = _reminderEnabled ? _reminderTime : null;
        
        await _noteService.saveNote(
          date: widget.date,
          text: _textController.text,
          color: _selectedColor,
          reminderTime: reminderTime,
          reminderEnabled: _reminderEnabled,
        );
      }
      
      if (widget.onNoteSaved != null) {
        widget.onNoteSaved!();
      }
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingNote != null 
              ? 'Заметка обновлена'
              : 'Заметка сохранена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteNote() async {
    if (widget.existingNote == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Вы уверены, что хотите удалить эту заметку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _noteService.deleteNote(widget.existingNote!.id);
        
        if (widget.onNoteSaved != null) {
          widget.onNoteSaved!();
        }
        
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заметка удалена'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: GlassContainer(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        tintColor: isDark ? FuturisticColors.cyan : const Color(0xFF087F9B),
        tintOpacity: isDark ? 0.12 : 0.08,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.existingNote != null ? 'Редактировать заметку' : 'Новая заметка',
                    style: futTitle.copyWith(fontSize: 19),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('dd.MM.yyyy (EEEE)', 'ru_RU').format(widget.date),
                style: futMuted,
              ),
            ),
            const SizedBox(height: 16),
            
            // Выбор цвета
            Row(
              children: [
                Text('Цвет заметки:', style: futHeading.copyWith(fontSize: 14)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Выберите цвет'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: _selectedColor,
                            onColorChanged: (color) {
                              setState(() => _selectedColor = color);
                            },
                            showLabel: true,
                            pickerAreaHeightPercent: 0.7,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Готово'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Текст заметки
            GlassTextField(
              controller: _textController,
              maxLines: 4,
              hintText: 'Текст заметки...',
              prefixIcon: Icons.notes,
            ),
            const SizedBox(height: 16),
            
            // Напоминание
            Row(
              children: [
                Checkbox(
                  value: _reminderEnabled,
                  onChanged: (value) {
                    setState(() => _reminderEnabled = value ?? false);
                  },
                ),
                Text('Напоминание', style: futHeading.copyWith(fontSize: 14)),
              ],
            ),
            
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reminderTimeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Время напоминания',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: _selectReminderTime,
                        ),
                      ),
                      onTap: _selectReminderTime,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.existingNote != null) ...[
                  TextButton(
                    onPressed: _deleteNote,
                    child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                GlassButton(
                  onPressed: _saveNote,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}