import 'dart:math';

class AccountIdGenerator {
  static String generateAccountId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final randomPart = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return 'acc_${timestamp}_$randomPart';
  }
  
  static bool isValidAccountId(String id) {
    return id.startsWith('acc_') && id.contains('_') && id.length > 20;
  }
  
  static int? extractTimestamp(String id) {
    try {
      if (isValidAccountId(id)) {
        final parts = id.split('_');
        if (parts.length >= 2) {
          return int.tryParse(parts[1]);
        }
      }
    } catch (e) {
      print('❌ Ошибка извлечения timestamp: $e');
    }
    return null;
  }
}