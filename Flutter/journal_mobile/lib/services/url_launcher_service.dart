import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:io';

class UrlLauncherService {
  static final UrlLauncherService _instance = UrlLauncherService._internal();
  
  factory UrlLauncherService() {
    return _instance;
  }
  
  UrlLauncherService._internal();

  /// Запускает URL во внешнем приложении/браузере [url_launcher_service]
  Future<void> launchUrl(String url) async {
    try {
      print('🔗 Launching URL: $url');
      
      if (kIsWeb) {
        html.window.open(url, '_blank');
        return;
      }
      
      if (Platform.isAndroid) {
        await _launchUrlAndroid(url);
      } else if (Platform.isIOS) {
        await _launchUrlIOS(url);
      } else if (Platform.isWindows) {
        await _launchUrlDesktop(url);
      } else if (Platform.isLinux) {
        await _launchUrlDesktop(url);
      } else if (Platform.isMacOS) {
        await _launchUrlDesktop(url);
      } else {
        await _launchUrlUniversal(url);
      }
      
      print('URL launched successfully');
    } catch (e) {
      print('Error launching URL: $e');
      await _launchUrlUniversal(url);
    }
  }

  /// Специфичный метод для Android [url_launcher_service]
  Future<void> _launchUrlAndroid(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      final bool launched = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
      
      if (!launched) {
        await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      print('Android URL launch failed: $e');
      rethrow;
    }
  }

  /// Специфичный метод для iOS [url_launcher_service]
  Future<void> _launchUrlIOS(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } catch (e) {
      print('iOS URL launch failed: $e');
      rethrow;
    }
  }

  /// Метод для десктопных платформ [url_launcher_service]
  Future<void> _launchUrlDesktop(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url], runInShell: true);
      } else {
        throw Exception('Unsupported platform');
      }
    } catch (e) {
      throw Exception('Desktop URL launch failed: $e');
    }
  }

  /// Универсальный метод как запасной вариант [url_launcher_service]
  Future<void> _launchUrlUniversal(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await url_launcher.launchUrl(uri);
    } catch (e) {
      print('Universal URL launch also failed: $e');
    }
  }

  /// Проверяет, можно ли запустить URL (приватный метод для Uri) [url_launcher_service]
  Future<bool> _canLaunchUri(Uri uri) async {
    try {
      return await url_launcher.canLaunchUrl(uri);
    } catch (e) {
      print('UrlLauncherService: Error checking URL: $e');
      return false;
    }
  }

  /// Проверяет, можно ли запустить URL (публичный метод для String) [url_launcher_service]
  Future<bool> canLaunchUrl(String url) async {
    try {
      if (kIsWeb) {
        return true;
      }
      
      final Uri uri = Uri.parse(url);
      return await _canLaunchUri(uri);
    } catch (e) {
      print('UrlLauncherService: Error checking URL: $e');
      return false;
    }
  }

  /// Открывает email клиент [url_launcher_service]
  Future<void> launchEmail(String email, {String? subject, String? body}) async {
    final String emailUrl = _buildEmailUrl(email, subject: subject, body: body);
    await launchUrl(emailUrl);
  }

  // Приватные метод для построения URL email [url_launcher_service]
  String _buildEmailUrl(String email, {String? subject, String? body}) {
    final params = <String>[];
    if (subject != null) params.add('subject=${Uri.encodeComponent(subject)}');
    if (body != null) params.add('body=${Uri.encodeComponent(body)}');
    
    final paramsString = params.isNotEmpty ? '?${params.join('&')}' : '';
    return 'mailto:$email$paramsString';
  }
}