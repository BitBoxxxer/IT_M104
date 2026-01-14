import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  static const String _logFileName = 'student_journal_logs.enc';
  // Ключ для теста - в реальном приложении должен храниться безопасно
  static const String _encryptionKeyStr = 'sodagrdp_it_top_college_2024_test_key';
  static late encrypt.Key _encryptionKey;
  static late encrypt.Encrypter _encrypter;
  
  File? _logFile;
  List<String> _logBuffer = [];
  
  // Инициализация
  Future<void> initialize() async {
    try {
      // Инициализация ключа шифрования
      final keyBytes = sha256.convert(utf8.encode(_encryptionKeyStr)).bytes;
      _encryptionKey = encrypt.Key(Uint8List.fromList(keyBytes));
      _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey, mode: encrypt.AESMode.cbc));
      
      // Получаем директорию для файлов
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/$_logFileName');
      
      // Создаем файл если его нет
      if (!await _logFile!.exists()) {
        await _logFile!.writeAsBytes([]);
      }
      
      // Записываем запись о запуске
      await logAction('APP_START', 'Приложение запущено', extraInfo: {
        'platform': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'app_version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Запускаем периодическую запись буфера
      _startBufferFlushTimer();
      
    } catch (e) {
      debugPrint('❌ Ошибка инициализации LoggingService: $e');
    }
  }
  
  // Таймер для периодической записи буфера
  void _startBufferFlushTimer() {
    Future.delayed(const Duration(seconds: 30), () async {
      if (_logBuffer.isNotEmpty) {
        await _flushBuffer();
      }
      _startBufferFlushTimer();
    });
  }
  
  // Запись действия
  Future<void> logAction(String actionType, String description, {Map<String, dynamic>? extraInfo}) async {
    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      
      String extraInfoStr = '';
      if (extraInfo != null) {
        extraInfoStr = ' || ${jsonEncode(extraInfo)}';
      }
      
      final logEntry = '($timestamp)_($actionType)_($description$extraInfoStr)';
      
      // Добавляем в буфер
      _logBuffer.add(logEntry);
      
      // Если буфер большой, записываем сразу
      if (_logBuffer.length >= 10) {
        await _flushBuffer();
      }
      
    } catch (e) {
      debugPrint('❌ Ошибка формирования лога: $e');
    }
  }
  
  // Запись ошибки
  Future<void> logError(String errorType, String errorMessage, StackTrace? stackTrace) async {
    await logAction('ERROR_$errorType', errorMessage, extraInfo: {
      'stack_trace': stackTrace?.toString() ?? 'No stack trace',
      'is_error': true,
      'severity': 'high',
    });
  }
  
  // Сброс буфера в файл
  Future<void> _flushBuffer() async {
    if (_logBuffer.isEmpty || _logFile == null) return;
    
    try {
      // Читаем существующие данные
      List<int> existingData = [];
      if (await _logFile!.exists()) {
        existingData = await _logFile!.readAsBytes();
      }
      
      // Дешифруем существующие данные
      List<String> allEntries = [];
      if (existingData.isNotEmpty) {
        try {
          final decrypted = _decryptAES(existingData);
          allEntries = decrypted.split('\n').where((e) => e.isNotEmpty).toList();
        } catch (e) {
          debugPrint('⚠️ Не удалось дешифровать старые логи: $e');
        }
      }
      
      // Добавляем новые записи
      allEntries.addAll(_logBuffer);
      
      // Ограничиваем размер (максимум 1000 записей)
      if (allEntries.length > 1000) {
        allEntries = allEntries.sublist(allEntries.length - 1000);
      }
      
      // Шифруем всё
      final dataToEncrypt = allEntries.join('\n');
      final encryptedData = _encryptAES(utf8.encode(dataToEncrypt));
      
      // Записываем
      await _logFile!.writeAsBytes(encryptedData);
      
      // Очищаем буфер
      _logBuffer.clear();
      
    } catch (e) {
      debugPrint('❌ Ошибка записи буфера логов: $e');
    }
  }
  
  // Шифрование AES-256-CBC
  List<int> _encryptAES(List<int> data) {
    try {
      // Генерируем случайный IV для каждого шифрования
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter.encryptBytes(data, iv: iv);
      
      // Сохраняем IV + зашифрованные данные
      return [...iv.bytes, ...encrypted.bytes];
    } catch (e) {
      debugPrint('❌ Ошибка шифрования: $e');
      // В случае ошибки возвращаем оригинал с меткой
      return [...utf8.encode('[UNENCRYPTED:${e.toString().substring(0, 50)}]'), ...data];
    }
  }
  
  // Дешифровка
  String _decryptAES(List<int> data) {
    try {
      if (data.length <= 16) throw Exception('Недостаточно данных для дешифровки');
      
      // Извлекаем IV (первые 16 байт)
      final ivBytes = data.sublist(0, 16);
      final encryptedBytes = data.sublist(16);
      
      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));
      
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Ошибка дешифровки: $e');
    }
  }
  
  // Экспорт файла
  Future<File?> exportLogFile() async {
    try {
      // Сначала сбрасываем буфер
      await _flushBuffer();
      
      if (_logFile == null || !await _logFile!.exists()) {
        return null;
      }
      
      return _logFile;
    } catch (e) {
      debugPrint('❌ Ошибка экспорта лога: $e');
      return null;
    }
  }
  
  // Создание читаемого отчета
  Future<File> createReadableReport() async {
    try {
      final directory = await getTemporaryDirectory();
      final reportFile = File('${directory.path}/error_report_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      // Получаем логи
      final logFile = await exportLogFile();
      if (logFile == null || !await logFile.exists()) {
        await reportFile.writeAsString('Логи не найдены\n');
        return reportFile;
      }
      
      final encryptedData = await logFile.readAsBytes();
      String decryptedLogs = 'Не удалось дешифровать логи\n';
      
      try {
        decryptedLogs = _decryptAES(encryptedData);
      } catch (e) {
        decryptedLogs = 'Ошибка дешифровки: $e\nДанные (base64): ${base64Encode(encryptedData)}';
      }
      
      // Создаем отчет
      final report = '''
=== ОТЧЕТ ОБ ОШИБКАХ IT TOP JOURNAL ===
Сгенерировано: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}
Приложение: Student Journal
Версия: 1.0.0
Устройство: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}
Email разработчика: sodagrdp@gmail.com

=== ПОСЛЕДНИЕ 50 ЗАПИСЕЙ ===
${decryptedLogs.split('\n').reversed.take(50).join('\n')}

=== ИНФОРМАЦИЯ ДЛЯ РАЗРАБОТЧИКА ===
Файл зашифрован: AES-256-CBC
Ключ: $_encryptionKeyStr
Размер файла: ${encryptedData.length} байт
Кол-во записей: ${decryptedLogs.split('\n').where((e) => e.isNotEmpty).length}

=== КОНЕЦ ОТЧЕТА ===
''';
      
      await reportFile.writeAsString(report);
      return reportFile;
      
    } catch (e) {
      debugPrint('❌ Ошибка создания отчета: $e');
      rethrow;
    }
  }
  
  // Очистка логов
  Future<void> clearLogs() async {
    try {
      await _flushBuffer();
      
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsBytes([]);
        await logAction('LOG_CLEAR', 'Логи очищены пользователем');
      }
    } catch (e) {
      debugPrint('❌ Ошибка очистки логов: $e');
    }
  }
  
  // Статистика
  Future<Map<String, dynamic>> getLogStats() async {
    try {
      await _flushBuffer();
      
      if (_logFile == null || !await _logFile!.exists()) {
        return {'size': 0, 'entries': 0, 'status': 'no_file'};
      }
      
      final file = await _logFile!.readAsBytes();
      String entryCount = 'N/A';
      
      try {
        if (file.isNotEmpty) {
          final decrypted = _decryptAES(file);
          entryCount = decrypted.split('\n').where((e) => e.isNotEmpty).length.toString();
        }
      } catch (e) {
        entryCount = 'зашифровано';
      }
      
      return {
        'size': file.length,
        'entries': entryCount,
        'status': 'encrypted',
        'path': _logFile!.path,
        'last_modified': (await _logFile!.lastModified()).toIso8601String(),
      };
    } catch (e) {
      return {'size': 0, 'entries': 0, 'error': e.toString()};
    }
  }
}