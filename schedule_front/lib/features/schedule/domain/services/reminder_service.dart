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
    
    // 반복 설정이 있는지 확인
    bool hasRecurrence = reminder.recurrenceDays.isNotEmpty && 
                         reminder.recurrenceDays != "0,0,0,0,0,0,0" &&
                         reminder.recurrenceDays.contains("1");
    
    // JSON 변환
    Map<String, dynamic> jsonReminder = {
      'reminderTitle': reminder.reminder_title,
      'recurrenceDays': reminder.recurrenceDays,
      'reminderMinutesBefore': reminder.reminderMinutesBefore,
    };
    
    // 반복 설정이 있을 경우에만 시작일과 종료일 추가
    if (hasRecurrence) {
      // 시작일 설정
      if (reminder.recurrenceStartDate != null) {
        jsonReminder['recurrenceStartDate'] = reminder.recurrenceStartDate!.toIso8601String();
      } else {
        // 시작일이 없으면 오늘 날짜를 사용
        final today = DateTime.now();
        final startDate = DateTime(today.year, today.month, today.day);
        jsonReminder['recurrenceStartDate'] = startDate.toIso8601String();
      }
      
      // 종료일이 있으면 추가
      if (reminder.recurrenceEndDate != null) {
        jsonReminder['recurrenceEndDate'] = reminder.recurrenceEndDate!.toIso8601String();
      }
    }

    final response = await http.post(
      Uri.parse(ApiConfig.remindersEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(jsonReminder),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('리마인더 생성 실패: ${response.statusCode}');
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
    
    // 반복 설정이 있는지 확인
    bool hasRecurrence = reminder.recurrenceDays.isNotEmpty && 
                         reminder.recurrenceDays != "0,0,0,0,0,0,0" &&
                         reminder.recurrenceDays.contains("1");
    
    // JSON 변환
    Map<String, dynamic> jsonReminder = {
      'id': reminder.reminderId,
      'reminderTitle': reminder.reminder_title,
      'recurrenceDays': reminder.recurrenceDays,
      'reminderMinutesBefore': reminder.reminderMinutesBefore,
      'isActive': reminder.isActive,
      'date': reminder.date,
    };
    
    // checkedDate 필드 추가
    if (reminder.checkedDate != null) {
      jsonReminder['checkedDate'] = reminder.checkedDate!.toIso8601String();
    }
    
    // excludedDates 필드 추가
    if (reminder.excludedDates != null && reminder.excludedDates!.isNotEmpty) {
      jsonReminder['excludedDates'] = reminder.excludedDates;
    }
    
    // 반복 설정이 있을 경우에만 시작일과 종료일 추가
    if (hasRecurrence) {
      // 시작일 설정
      if (reminder.recurrenceStartDate != null) {
        jsonReminder['recurrenceStartDate'] = reminder.recurrenceStartDate!.toIso8601String();
      }
      
      // 종료일 설정
      if (reminder.recurrenceEndDate != null) {
        jsonReminder['recurrenceEndDate'] = reminder.recurrenceEndDate!.toIso8601String();
      }
    }

    final response = await http.put(
      Uri.parse(ApiConfig.reminderById(reminder.reminderId.toString())),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(jsonReminder),
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
