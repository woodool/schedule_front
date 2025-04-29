import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/schedule.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleService {
  // static const String baseUrl = 'http://192.168.219.101:8080/api/schedules'; // 기숙사
  static const String baseUrl = 'http://172.16.7.130:8080/api/schedules'; // 303호

  Future<List<Schedule>> getSchedules() async {
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
      return jsonList.map((json) => Schedule.fromJson(json)).toList();
    } else {
      throw Exception('스케줄 로드 실패: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> createSchedule(Schedule schedule) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(schedule.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 200 OK 또는 201 Created 둘 다 성공
      return;
    } else {
      throw Exception('일정 생성 실패: ${response.statusCode} - ${response.body}');
    }
  }
  Future<void> updateSchedule(Schedule schedule) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    final response = await http.put(
      Uri.parse('$baseUrl/${schedule.scheduleId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(schedule.toJson()), // Schedule을 JSON 변환
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
    return;
    } else {
    throw Exception('일정 수정 실패: ${response.statusCode} - ${response.body}');
    }
  }
}
