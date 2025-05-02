import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/schedule.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/api_config.dart';

class ScheduleService {
  // 중앙화된 API 설정 사용

  Future<List<Schedule>> getSchedules() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    final response = await http.get(
      Uri.parse(ApiConfig.schedulesEndpoint),
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
      Uri.parse(ApiConfig.schedulesEndpoint),
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

    // schedule ID 확인
    if (schedule.scheduleId == null) {
      throw Exception('일정 ID가 null입니다');
    }

    final idToken = await user.getIdToken(true);

    // ID를 문자열로 안전하게 변환
    final scheduleIdStr = schedule.scheduleId.toString();
    print('일정 수정 요청 - ID: $scheduleIdStr');

    final response = await http.put(
      Uri.parse(ApiConfig.scheduleById(scheduleIdStr)),
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

  // 일정 삭제 API
  Future<void> deleteSchedule(int scheduleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    // ID를 문자열로 안전하게 변환
    final scheduleIdStr = scheduleId.toString();
    print('일정 삭제 요청 - ID: $scheduleIdStr');

    final response = await http.delete(
      Uri.parse(ApiConfig.scheduleById(scheduleIdStr)),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      // 200 OK 또는 204 No Content는 모두 성공
      return;
    } else {
      throw Exception('일정 삭제 실패: ${response.statusCode} - ${response.body}');
    }
  }

  // 일정 검색 API
  Future<List<Schedule>> searchSchedules(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

    final idToken = await user.getIdToken(true);

    // 검색 API 엔드포인트에 쿼리 파라미터 추가
    final searchEndpoint = '${ApiConfig.schedulesEndpoint}/search?query=$query';

    final response = await http.get(
      Uri.parse(searchEndpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Schedule.fromJson(json)).toList();
    } else {
      // API가 구현되지 않았거나 오류가 발생한 경우 로컬 검색으로 대체
      print('서버 검색 API 사용 실패 (${response.statusCode}), 로컬 검색으로 대체합니다.');
      return _localSearchSchedules(query);
    }
  }

  // 로컬 검색 기능 (서버 검색 API가 구현되지 않은 경우 대체용)
  Future<List<Schedule>> _localSearchSchedules(String query) async {
    final allSchedules = await getSchedules();
    final lowerQuery = query.toLowerCase();
    
    return allSchedules.where((schedule) =>
      schedule.title.toLowerCase().contains(lowerQuery) ||
      (schedule.description != null && 
       schedule.description!.toLowerCase().contains(lowerQuery))
    ).toList();
  }
}
