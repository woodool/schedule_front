import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/reminder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/api_config.dart';

class ReminderService {
  // 중앙화된 API 설정 사용

  Future<List<Reminder>> getReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    final response = await http.get(
      Uri.parse(ApiConfig.remindersEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw Exception('리마인더 로드 실패: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> saveReminder(Reminder reminder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    final response = await http.post(
      Uri.parse(ApiConfig.remindersEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(reminder.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 200 OK 또는 201 Created 둘 다 성공
      return;
    } else {
      throw Exception('리마인더 저장 실패: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    // reminderId가 null이면 예외 발생
    if (reminder.reminderId == null) {
      throw Exception('리마인더 ID가 없습니다');
    }

    final idToken = await user.getIdToken(true);

    final response = await http.put(
      Uri.parse(ApiConfig.reminderById(reminder.reminderId.toString())),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(reminder.toJson()),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('리마인더 수정 실패: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    final response = await http.delete(
      Uri.parse(ApiConfig.reminderById(reminderId)),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('리마인더 삭제 실패: ${response.statusCode} - ${response.body}');
    }
  }
}
