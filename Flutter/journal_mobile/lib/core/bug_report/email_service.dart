import 'package:flutter/material.dart';
import 'package:mailto/mailto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import 'logging_service.dart';

class EmailService {
  static const String developerEmail = 'sodagrdp@gmail.com';
  static const String appName = 'IT Top College Journal';
  
  // Отправка логов через email
  static Future<void> sendLogsByEmail(File logFile, {String? additionalMessage}) async {
    try {
      // Создаем mailto ссылку
      final mailtoLink = Mailto(
        to: [developerEmail],
        subject: '[$appName] Отчет об ошибках',
        body: '''
Приветствую, разработчик!

Пользователь отправил отчет об ошибках из приложения $appName.

${additionalMessage ?? ''}

---
Дополнительная информация:
- Время отправки: ${DateTime.now().toString()}
- Файл логов прикреплен (зашифрован AES-256-CBC)
- Ключ для дешифровки: sodagrdp_it_top_college_2024_test_key
- Формат: (Время)_(Тип_Действия)_(Описание действия || JSON доп. информация)

Пожалуйста, проверьте вложения.
''',
      );
      
      // Пытаемся открыть почтовый клиент
      final uri = Uri.parse(mailtoLink.toString());
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        // Для Android/iOS можно использовать share для прикрепления файла
        if (Platform.isAndroid || Platform.isIOS) {
          await _shareFileWithEmail(logFile);
        }
      } else {
        throw Exception('Не удалось открыть почтовый клиент');
      }
      
    } catch (e) {
      debugPrint('❌ Ошибка отправки email: $e');
      rethrow;
    }
  }
  
  // Альтернативный метод через share (для мобильных устройств)
  static Future<void> _shareFileWithEmail(File file) async {
    try {
      final files = [XFile(file.path)];
      
      await Share.shareXFiles(
        files,
        text: 'Отчет об ошибках IT Top College Journal',
        subject: '[$appName] Отчет об ошибках',
      );
    } catch (e) {
      debugPrint('❌ Ошибка share файла: $e');
    }
  }
  
  // Создание отчета с возможностью добавления комментария
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
                'Будет отправлено на: $developerEmail',
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
      final additionalMessage = comment.isNotEmpty 
          ? 'Комментарий пользователя:\n$comment\n\n'
          : 'Пользователь не оставил комментарий.\n\n';
      
      try {
        await sendLogsByEmail(logFile, additionalMessage: additionalMessage);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Отчет отправлен разработчику!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Логируем отправку
        final loggingService = LoggingService();
        await loggingService.logAction('REPORT_SENT', 'Отчет отправлен разработчику', extraInfo: {
          'has_comment': comment.isNotEmpty,
          'comment_length': comment.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}