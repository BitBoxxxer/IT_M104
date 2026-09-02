import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi_web;

class SqfliteInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Для Android/iOS - sqflite (родной плагин, ничего настраивать не нужно)
    // Для desktop (Windows/Linux/macOS) - sqflite_common_ffi (нативный sqlite3)
    // Для Web - sqflite_common_ffi_web (sqlite3.wasm + IndexedDB через shared worker)
    if (kIsWeb) {
      // ВАЖНО: раньше здесь ничего не настраивалось (только print), из-за
      // чего обычный databaseFactory (заточенный под platform channels
      // Android/iOS) пытался открыть БД в браузере и падал в рантайме —
      // на вебе просто нет нативной реализации sqflite.
      //
      // Требует, чтобы в web/ лежали sqlite3.wasm и sqflite_sw.js — их
      // генерирует команда `dart run sqflite_common_ffi_web:setup`
      // (см. README пакета sqflite_common_ffi_web).
      databaseFactory = ffi_web.databaseFactoryFfiWeb;
      print('Sqflite: Web (sqflite_common_ffi_web)');
    } else if (defaultTargetPlatform == TargetPlatform.android || 
               defaultTargetPlatform == TargetPlatform.iOS) {
      print('Sqflite: Android/iOS (нативный плагин)');
    } else {
      
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
      print('Sqflite: Desktop (sqflite_common_ffi)');
    }
    
    _isInitialized = true;
  }

  static bool get isInitialized => _isInitialized;
}