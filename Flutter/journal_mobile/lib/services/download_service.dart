import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class DownloadService {
  static final Dio _dio = Dio();

  static Future<File?> downloadFile({
    required String url,
    required String fileName,
    required String token,
    Function(int, int)? onProgress,
  }) async {
    try {
      print('Starting download: $fileName');
      print('Download URL: $url');

      final response = await _dio.head(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': '*/*',
            'Referer': 'https://journal.top-academy.ru',
          },
        ),
      );

      final String actualFileName = await _getFileName(url, fileName, response);

      Directory directory = await getDownloadDirectory();
      print('Download directory: ${directory.path}');

      String safeFileName = _sanitizeFileName(actualFileName);
      String filePath = '${directory.path}/$safeFileName';

      print('Final file path: $filePath');

      await _dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': '*/*',
            'Referer': 'https://journal.top-academy.ru',
          },
        ),
        onReceiveProgress: onProgress,
      );

      final file = File(filePath);
      
      if (await file.exists()) {
        final fileSize = await file.length();
        print('File downloaded successfully: ${file.path}');
        print('File size: $fileSize bytes');
        print('File name: $safeFileName');
        return file;
      } else {
        throw Exception('File was not created at path: $filePath');
      }
    } catch (e) {
      print('Download error: $e');
      rethrow;
    }
  }

  /// Получает подходящую директорию для скачивания
  static Future<Directory> getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        try {
          Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Для Android создает папку Download - Ди
            Directory downloadDir = Directory('${externalDir.path}/Download');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            print('Using external storage: ${downloadDir.path}');
            return downloadDir;
          }
        } catch (e) {
          print('External storage not available: $e');
        }

        try {
          Directory? downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            print('Using downloads directory: ${downloadsDir.path}');
            return downloadsDir;
          }
        } catch (e) {
          print('Downloads directory not available: $e');
        }
      }
      
      // Fallback на documents directory - Ди
      Directory documentsDir = await getApplicationDocumentsDirectory();
      Directory downloadDir = Directory('${documentsDir.path}/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      print('Using documents directory: ${downloadDir.path}');
      return downloadDir;
    } catch (e) {
      print('Error getting download directory: $e');
      // Ultimate fallback - Ди
      Directory documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir;
    }
  }

  /// Открывает скачанный файл
  static Future<void> openDownloadedFile(File file) async {
    try {
      print('Opening file: ${file.path}');
      final result = await OpenFile.open(file.path);
      print('Open file result: ${result.type} - ${result.message}');
    } catch (e) {
      print('Error opening file: $e');
      rethrow;
    }
  }

  /// Проверяет, существует ли файл
  static Future<bool> fileExists(String fileName) async {
    try {
      Directory directory = await getDownloadDirectory();
      String safeFileName = _sanitizeFileName(fileName);
      String filePath = '${directory.path}/$safeFileName';
      
      bool exists = await File(filePath).exists();
      print('File exists check: $filePath - $exists');
      return exists;
    } catch (e) {
      print('Error checking file existence: $e');
      return false;
    }
  }

  /// Очищает имя файла от недопустимых символов
  static String _sanitizeFileName(String fileName) {
    // Базовое очищение
    String cleanName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    if (cleanName.contains('.')) {
      List<String> parts = cleanName.split('.');
      String extension = parts.last;
      String nameWithoutExt = parts.sublist(0, parts.length - 1).join('.');
      
      if (nameWithoutExt.length > 50) {
        nameWithoutExt = nameWithoutExt.substring(0, 50);
      }
      
      return '${nameWithoutExt}_$timestamp.$extension';
    } else {
      if (cleanName.length > 50) {
        cleanName = cleanName.substring(0, 50);
      }
      return '${cleanName}_$timestamp';
    }
  }

  /// Получает список скачанных файлов
  static Future<List<File>> getDownloadedFiles() async {
    try {
      Directory directory = await getDownloadDirectory();
      List<FileSystemEntity> files = await directory.list().toList();
      
      return files.whereType<File>().toList();
    } catch (e) {
      print('Error getting downloaded files: $e');
      return [];
    }
  }

  /// Получает правильное имя файла из URL или заголовков
static Future<String> _getFileName(String url, String fallbackName, Response response) async {
  try {
    String? contentDisposition = response.headers.value('content-disposition');
    if (contentDisposition != null && contentDisposition.contains('filename=')) {
      final regex = RegExp(r'filename=("?)(.*?)\1(?:;|$)');
      final match = regex.firstMatch(contentDisposition);
      if (match != null && match.group(2) != null) {
        String filename = match.group(2)!;
        // Декодирует URL-encoded имена
        if (filename.contains('%')) {
          filename = Uri.decodeComponent(filename);
        }
        return filename;
      }
    }

    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      String lastSegment = pathSegments.last;
      if (lastSegment.contains('.') && lastSegment.length > 3) {
        return lastSegment;
      }
    }

    return _ensureFileExtension(fallbackName, response);
  } catch (e) {
    print('Error getting filename: $e');
    return fallbackName;
  }
}

/// Обеспечивает правильное расширение файла
static String _ensureFileExtension(String fileName, Response response) {
  if (fileName.contains('.')) {
    return fileName;
  }

  // Определяем расширение по Content-Type (TODO: Посмотреть какие форматы еще могут быть отправлены.)
  String? contentType = response.headers.value('content-type');
  String extension = '.bin'; // дефолтное расширение.

  if (contentType != null) {
    switch (contentType) {
      case 'application/pdf':
        extension = '.pdf';
        break;
      case 'application/zip':
        extension = '.zip';
        break;
      case 'application/msword':
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        extension = '.docx';
        break;
      case 'image/jpeg':
        extension = '.jpg';
        break;
      case 'image/png':
        extension = '.png';
        break;
      case 'text/plain':
        extension = '.txt';
        break;
    }
  }

  return '$fileName$extension';
}
}