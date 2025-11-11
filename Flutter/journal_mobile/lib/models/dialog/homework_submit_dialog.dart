import 'package:flutter/material.dart';
import 'dart:io';

import 'package:journal_mobile/services/file_service.dart';
import 'package:journal_mobile/models/homework.dart';


class HomeworkSubmitDialog extends StatefulWidget {
  final Homework homework;
  final String token;
  final VoidCallback onSubmitted;

  const HomeworkSubmitDialog({
    super.key,
    required this.homework,
    required this.token,
    required this.onSubmitted,
  });

  @override
  State<HomeworkSubmitDialog> createState() => _HomeworkSubmitDialogState();
}

class _HomeworkSubmitDialogState extends State<HomeworkSubmitDialog> {
  final FileService _fileService = FileService();
  final TextEditingController _answerController = TextEditingController();
  File? _selectedFile;
  int _spentTimeHour = 0;
  int _spentTimeMin = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Сдать работу: ${widget.homework.theme}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Текстовый ответ (опционально)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Часы',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _spentTimeHour = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Минуты',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _spentTimeMin = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _selectedFile != null
                ? ListTile(
                    leading: Icon(Icons.attach_file),
                    title: Text(_selectedFile!.path.split('/').last),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                        });
                      },
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(Icons.attach_file),
                    label: Text('Прикрепить файл'),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting 
              ? CircularProgressIndicator()
              : Text('Сдать работу'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final file = await _fileService.pickFile();
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null && _answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Добавьте файл или текстовый ответ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _fileService.uploadHomeworkFile(
        homeworkId: widget.homework.id,
        file: _selectedFile!,
        answerText: _answerController.text,
        spentTimeHour: _spentTimeHour,
        spentTimeMin: _spentTimeMin,
        token: widget.token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Работа успешно сдана'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSubmitted();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сдаче работы: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}