import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/reminder.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderService {
  // static const String baseUrl = 'http://192.168.219.101:8080/api/reminders'; // 기숙사
  static const String baseUrl = 'http://172.16.7.130:8080/api/reminders'; // 303호

  Future<List<Reminder>> getReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    final response = await http.get(
      Uri.parse(baseUrl),
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
      Uri.parse(baseUrl),
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

    final idToken = await user.getIdToken(true);

    final response = await http.put(
      Uri.parse('$baseUrl/${reminder.reminderId}'),
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
      Uri.parse('$baseUrl/$reminderId'),
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
