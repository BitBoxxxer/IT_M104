import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'logging_service.dart';

class EmailService {
  static const String developerEmail = 'sodagrdp@gmail.com';
  static const String appName = 'IT Top College Journal';

  /// метод отправки отчёта
  static Future<void> sendReport({
    required BuildContext context,
    required File logFile,
    String? userComment,
  }) async {
    try {
      final body = '''
Приветствую, разработчик!

Пользователь отправил отчет об ошибках из приложения $appName.

${userComment != null && userComment.isNotEmpty ? 'Комментарий пользователя:\n$userComment\n\n' : 'Пользователь не оставил комментария.\n\n'}
---
Дополнительная информация:
- Время отправки: ${DateTime.now().toString()}
- Файл логов прикреплён (зашифрован AES‑256‑CBC)
- Ключ для дешифровки: sodagrdp_it_top_college_2024_test_key
- Формат записей: (Время)_(Тип_Действия)_(Описание действия || JSON доп. информация)

Пожалуйста, проверьте вложение.
''';

      // объект Email
      final Email email = Email(
        body: body,
        subject: '[$appName] Отчёт об ошибках',
        recipients: [developerEmail],
        attachmentPaths: [logFile.path],
        isHTML: false,
      );

      // письмо
      await FlutterEmailSender.send(email);

      // отправка
      final loggingService = LoggingService();
      await loggingService.logAction('REPORT_SENT', 'Отчёт отправлен через flutter_email_sender', extraInfo: {
        'has_comment': userComment != null && userComment.isNotEmpty,
        'comment_length': userComment?.length ?? 0,
      });

      // подтверждение
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Отчёт отправлен разработчику!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final loggingService = LoggingService();
      await loggingService.logError('EMAIL_SEND_ERROR', 'Ошибка отправки отчёта: $e', null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось отправить письмо: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
  static Future<void> sendReportWithComment(BuildContext context, File logFile) async {
    final TextEditingController commentController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Отправить отчет'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Опишите проблему, которую вы обнаружили:'),
              SizedBox(height: 10),
              TextField(
                controller: commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Например: "Приложение вылетает при открытии расписания..."',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Письмо будет отправлено на: $developerEmail',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Отправить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
    
    if (result == true && context.mounted) {
      final comment = commentController.text.trim();
      await sendReport(
        context: context,
        logFile: logFile,
        userComment: comment,
      );
    }
  }
}