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

    // 반복 설정이 있는지 확인
    bool hasRecurrence = schedule.recurrenceDays != null && 
                         schedule.recurrenceDays!.isNotEmpty && 
                         schedule.recurrenceDays != "0,0,0,0,0,0,0" &&
                         schedule.recurrenceDays!.contains("1");
    
    // JSON 변환
    Map<String, dynamic> jsonSchedule = {
      'title': schedule.title,
      'description': schedule.description,
      'startTime': schedule.startTime.toIso8601String(),
      'endTime': schedule.endTime.toIso8601String(),
      'categoryId': schedule.categoryId,
      'priority': schedule.priority ?? 4,
      'displayOnCalendar': schedule.displayOnCalendar,
      'reminderMinutesBefore': schedule.reminderMinutesBefore,
      'recurrenceDays': schedule.recurrenceDays ?? "0,0,0,0,0,0,0",
    };
    
    // 반복 설정이 있을 경우에만 시작일과 종료일 추가
    if (hasRecurrence) {
      // 시작일이 없으면 현재 일정의 시작 날짜를 사용
      if (schedule.recurrenceStartDate != null) {
        jsonSchedule['recurrenceStartDate'] = schedule.recurrenceStartDate!.toIso8601String();
      } else {
        // 시작일이 없으면 현재 일정의 시작 날짜를 사용
        final startDate = DateTime(
          schedule.startTime.year, 
          schedule.startTime.month, 
          schedule.startTime.day
        );
        jsonSchedule['recurrenceStartDate'] = startDate.toIso8601String();
      }
      
      // 종료일이 있으면 추가
      if (schedule.recurrenceEndDate != null) {
        jsonSchedule['recurrenceEndDate'] = schedule.recurrenceEndDate!.toIso8601String();
      }
    }

    final response = await http.post(
      Uri.parse(ApiConfig.schedulesEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(jsonSchedule),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('일정 생성 실패: ${response.statusCode}');
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
    
    // 반복 설정이 있는지 확인
    bool hasRecurrence = schedule.recurrenceDays != null && 
                         schedule.recurrenceDays!.isNotEmpty && 
                         schedule.recurrenceDays != "0,0,0,0,0,0,0" &&
                         schedule.recurrenceDays!.contains("1");
    
    // JSON 변환
    Map<String, dynamic> jsonSchedule = {
      'id': schedule.scheduleId,
      'title': schedule.title,
      'description': schedule.description,
      'startTime': schedule.startTime.toIso8601String(),
      'endTime': schedule.endTime.toIso8601String(),
      'categoryId': schedule.categoryId,
      'priority': schedule.priority ?? 4,
      'displayOnCalendar': schedule.displayOnCalendar,
      'reminderMinutesBefore': schedule.reminderMinutesBefore,
      'recurrenceDays': schedule.recurrenceDays ?? "0,0,0,0,0,0,0",
    };
    
    // excludedDates가 있으면 추가 (제외 날짜)
    if (schedule.excludedDates != null && schedule.excludedDates!.isNotEmpty) {
      jsonSchedule['excludedDates'] = schedule.excludedDates;
      print('제외 날짜 업데이트: ${schedule.excludedDates}');
    }
    
    // 반복 설정이 있을 경우에만 시작일과 종료일 추가
    if (hasRecurrence) {
      // 시작일이 설정된 경우
      if (schedule.recurrenceStartDate != null) {
        jsonSchedule['recurrenceStartDate'] = schedule.recurrenceStartDate!.toIso8601String();
        print('반복 시작일 설정: ${schedule.recurrenceStartDate!.toIso8601String()}');
      }
      
      // 종료일이 설정된 경우
      if (schedule.recurrenceEndDate != null) {
        jsonSchedule['recurrenceEndDate'] = schedule.recurrenceEndDate!.toIso8601String();
        print('반복 종료일 설정: ${schedule.recurrenceEndDate!.toIso8601String()}');
      } else {
        print('반복 종료일이 null입니다!');
      }
    }
    
    print('서버에 전송할 JSON 데이터: ${json.encode(jsonSchedule)}');

    final response = await http.put(
      Uri.parse(ApiConfig.scheduleById(scheduleIdStr)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(jsonSchedule),
    );

    print('일정 업데이트 응답 코드: ${response.statusCode}');
    print('일정 업데이트 응답 내용: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 응답 데이터 확인 (JSON 형식이면 파싱)
      try {
        final responseJson = json.decode(response.body);
        print('서버 응답 데이터: $responseJson');
        
        // excludedDates 필드 존재 여부 확인
        if (responseJson is Map && responseJson.containsKey('excludedDates')) {
          print('서버에서 반환된 excludedDates: ${responseJson['excludedDates']}');
        } else {
          print('서버 응답에 excludedDates 필드가 없습니다');
        }
      } catch (e) {
        print('응답 데이터 파싱 실패: $e');
      }
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
