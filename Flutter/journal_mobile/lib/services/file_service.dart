import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import '../models/homework.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// Скачивание файла задания
Future<File?> downloadHomeworkFile(String token, Homework homework) async {
  try {
    if (homework.downloadUrl == null || homework.downloadUrl!.isEmpty) {
      throw Exception('URL файла недоступен');
    }

    var client = http.Client();
    
    try {
      final response = await client.get(
        Uri.parse(homework.downloadUrl!),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': '*/*',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        Directory directory;
        try {
          directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }

        String fileName = getFileName(homework, response);

        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);
        
        print('Файл загружен: $fileName');
        print('Путь: ${file.path}');
        print('Content-Type: ${response.headers['content-type']}');
        print('Content-Disposition: ${response.headers['content-disposition']}');
        
        return file;
      } else {
        throw Exception('Ошибка загрузки файла: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  } catch (e) {
    print('Ошибка при скачивании файла: $e');
    rethrow;
  }
}

String getFileName(Homework homework, http.Response response) {
  String? contentDisposition = response.headers['content-disposition'];
  if (contentDisposition != null) {
    int filenameIndex = contentDisposition.toLowerCase().indexOf('filename=');
    if (filenameIndex != -1) {
      String filenamePart = contentDisposition.substring(filenameIndex + 9);
      
      if (filenamePart.startsWith('"') || filenamePart.startsWith("'")) {
        filenamePart = filenamePart.substring(1);
      }
      
      int endIndex = filenamePart.indexOf(';');
      if (endIndex == -1) {
        endIndex = filenamePart.length;
      }
      
      String filename = filenamePart.substring(0, endIndex);
      
      if (filename.endsWith('"') || filename.endsWith("'")) {
        filename = filename.substring(0, filename.length - 1);
      }
      
      if (filename.contains('%')) {
        try {
          filename = Uri.decodeComponent(filename);
        } catch (e) {
          print('Ошибка декодирования filename: $e');
        }
      }
      
      if (filename.isNotEmpty) {
        return filename.trim();
      }
    }
  }
  
  String fileName = homework.filename ?? 'homework_${homework.id}';
  
  List<int> bytes = response.bodyBytes;
  String extension = _detectFileExtension(bytes);
  
  if (!fileName.contains('.')) {
    fileName = '$fileName$extension';
  }
  
  return fileName;
}

String _detectFileExtension(List<int> bytes) {
  if (bytes.length < 4) return '.bin';
  
  // сигнатуры файлов
  if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
    return '.pdf';
  } else if (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
    return '.zip'; // ZIP (также для DOCX, XLSX и т.д.)
  } else if (bytes[0] == 0xD0 && bytes[1] == 0xCF && bytes[2] == 0x11 && bytes[3] == 0xE0) {
    return '.doc';
  } else if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return '.jpg'; // JPEG
  } else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
    return '.png';
  } else if (bytes[0] == 0x52 && bytes[1] == 0x61 && bytes[2] == 0x72 && bytes[3] == 0x21) {
    return '.rar';
  }
  
  if (_isTextFile(bytes)) {
    return '.txt';
  }
  
  return '.bin';
}

bool _isTextFile(List<int> bytes) {
  int checkLength = bytes.length > 1000 ? 1000 : bytes.length;
  for (int i = 0; i < checkLength; i++) {
    int byte = bytes[i];
    if (byte < 9 || (byte > 13 && byte < 32) || byte > 126) {
      return false;
    }
  }
  return true;
}

  Future<void> uploadHomeworkFile({
    required int homeworkId,
    required File file,
    required String answerText,
    required int spentTimeHour,
    required int spentTimeMin,
    required String token,
    Function(int, int)? onProgress,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://msapi.top-academy.ru/api/v2/homework/operations/create'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['id'] = homeworkId.toString();
      request.fields['spentTimeHour'] = spentTimeHour.toString();
      request.fields['spentTimeMin'] = spentTimeMin.toString();
      
      if (answerText.isNotEmpty) {
        request.fields['answerText'] = answerText;
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.path.split('/').last,
      ));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        print('Файл успешно загружен');
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка загрузки файла: $e');
      rethrow;
    }
  }

  Future<File?> pickFile() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Documents',
        extensions: <String>[
          'pdf', 'doc', 'docx', 'txt', 'rtf',
          'jpg', 'jpeg', 'png', 'gif',
          'zip', 'rar', '7z'
        ],
      );
      
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      
      if (file != null) {
        return File(file.path);
      }
      return null;
    } catch (e) {
      print('Ошибка выбора файла: $e');
      return null;
    }
  }
}