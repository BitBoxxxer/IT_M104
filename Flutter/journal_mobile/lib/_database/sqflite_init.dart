import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class SqfliteInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Для Android/iOS - sqflite
    // Для desktop (Windows/Linux/macOS) - FFI
    if (kIsWeb) {
      // Для Web
      print('Sqflite 1 ПК');
    } else if (defaultTargetPlatform == TargetPlatform.android || 
               defaultTargetPlatform == TargetPlatform.iOS) {
      print('Sqflite 2 android, IOS');
    } else {
      
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
      print('Sqflite 3');
    }
    
    _isInitialized = true;
  }

  static bool get isInitialized => _isInitialized;
}