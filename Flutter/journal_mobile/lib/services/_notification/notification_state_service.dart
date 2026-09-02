import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:journal_mobile/models/mark.dart';

class NotificationStateService {
  static const String _lastMarksKey = 'last_marks_for_notifications';
  static const String _lastAttendanceKey = 'last_attendance_for_notifications';
  
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  Future<void> saveNotificationState(List<Mark> marks) async {
    final marksJson = marks.map((m) => m.toJson()).toList();
    await _secureStorage.write(
      key: _lastMarksKey,
      value: jsonEncode(marksJson)
    );
    
    final attendanceData = _extractAttendanceData(marks);
    await _secureStorage.write(
      key: _lastAttendanceKey,
      value: jsonEncode(attendanceData)
    );
    
    print('✅ Notification state saved: ${marks.length} marks');
  }
  
  Future<List<Mark>> getLastMarksState() async {
    try {
      final data = await _secureStorage.read(key: _lastMarksKey);
      if (data == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => Mark.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error loading last marks state: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> getLastAttendanceState() async {
    try {
      final data = await _secureStorage.read(key: _lastAttendanceKey);
      if (data == null) return [];
      
      return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error loading last attendance state: $e');
      return [];
    }
  }
  
  List<Map<String, dynamic>> _extractAttendanceData(List<Mark> marks) {
    return marks.map((mark) => {
      'dateVisit': mark.dateVisit,
      'specName': mark.specName,
      'statusWas': mark.statusWas,
      'lessonTheme': mark.lessonTheme,
    }).toList();
  }
}