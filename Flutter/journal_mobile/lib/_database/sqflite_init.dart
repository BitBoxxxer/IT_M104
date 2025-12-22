import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SqfliteInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    sqfliteFfiInit();
    
    databaseFactory = databaseFactoryFfi;
    
    _isInitialized = true;
    print('✅ Sqflite инициализирован с FFI фабрикой');
  }

  static bool get isInitialized => _isInitialized;
}