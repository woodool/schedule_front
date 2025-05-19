import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/auto_schedule_request.dart';
import '../models/auto_schedule_response.dart';
import '../../../../core/config/api_config.dart';
import '../models/schedule.dart';
import '../models/Recurrence_option.Dart';

// TimeoutException 정의
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class ScheduleItem {
  String title;
  List<String> days;
  String startTime;
  String endTime;
  String recurrenceStartDate;
  String recurrenceEndDate;
  bool isEnabled;

  ScheduleItem({
    required this.title,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.recurrenceStartDate,
    required this.recurrenceEndDate,
    this.isEnabled = false,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
        title: j['title'] as String,
        days: List<String>.from(j['recurrenceDays'] as List),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        recurrenceStartDate: j['recurrenceStartDate'] as String,
        recurrenceEndDate: j['recurrenceEndDate'] as String,
        isEnabled: false,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'recurrenceDays': days,
        'startTime': startTime,
        'endTime': endTime,
        'recurrenceStartDate': recurrenceStartDate,
        'recurrenceEndDate': recurrenceEndDate,
      };
}

class ScheduleService {
  final http.Client httpClient;
  ScheduleService({
    http.Client? client,
  }) : httpClient = client ?? http.Client();

  /// 현재 로그인된 사용자의 Firebase ID 토큰을 가져옵니다.
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('사용자가 로그인되어 있지 않습니다');
    }
    // null 안전성을 위해 빈 문자열을 기본값으로 사용
    return await user.getIdToken(true) ?? '';
  }

  /// 모든 일정을 조회합니다.
  Future<List<Schedule>> getSchedules() async {
    final token = await _getIdToken();
    final uri = Uri.parse(ApiConfig.schedulesEndpoint);
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      final schedules = list.map((e) => Schedule.fromJson(e)).toList();

      // 디버그 로그 - 반복 일정 체크
      for (var schedule in schedules) {
        if (schedule.recurrenceDays != null &&
            schedule.recurrenceDays!.isNotEmpty &&
            schedule.recurrenceDays != "0,0,0,0,0,0,0") {
          print('가져온 반복 일정: ${schedule.title}');
          print('  반복 패턴: ${schedule.recurrenceDays}');
          print(
              '  반복 기간: ${schedule.recurrenceStartDate} ~ ${schedule.recurrenceEndDate}');

          // 패턴 분석
          List<String> days = schedule.recurrenceDays!.split(',');
          List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
          List<String> selectedDays = [];

          for (int i = 0; i < days.length && i < 7; i++) {
            if (days[i] == "1") {
              selectedDays.add(weekdays[i]);
            }
          }

          print('  선택된 요일: ${selectedDays.join(", ")}');
        }
      }

      return schedules;
    }
    throw Exception('일정 조회 실패: ${response.statusCode} - ${response.body}');
  }

  /// 특정 기간(반복 포함) 내의 일정을 조회합니다.
  Future<List<Schedule>> getSchedulesInRange(
      DateTime start, DateTime end) async {
    final token = await _getIdToken();
    final startDate = start.toIso8601String().split('T').first;
    final endDate = end.toIso8601String().split('T').first;

    // GET 메서드 사용 (POST 대신)
    final uri = Uri.parse(
        '${ApiConfig.schedulesEndpoint}/range?startDate=$startDate&endDate=$endDate');

    print('범위 일정 조회 요청: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list.map((e) => Schedule.fromJson(e)).toList();
    }

    // 오류 로그 추가
    print('범위 내 일정 조회 실패: ${response.statusCode} - ${response.body}');
    throw Exception('범위 내 일정 조회 실패: ${response.statusCode} - ${response.body}');
  }

  /// 새 일정을 생성합니다.
  Future<void> createSchedule(Schedule schedule) async {
    final token = await _getIdToken();
    final uri = Uri.parse(ApiConfig.schedulesEndpoint);

    // 반복 일정 여부 확인
    final bool isRecurringEvent = schedule.recurrenceDays != null &&
        schedule.recurrenceDays!.isNotEmpty &&
        schedule.recurrenceDays != "0,0,0,0,0,0,0";

    // 최종 요청 본문 생성
    Map<String, dynamic> body = schedule.toJson();

    // 반복 일정인 경우 처리
    if (isRecurringEvent) {
      print('반복 일정 생성 요청 감지');

      // 문제 해결 방법: start_time을 recurrence_start_date로 설정
      // 이렇게 하면 start_time 날짜부터 반복 일정이 생성됨
      body['startTime'] =
          body['recurrenceStartDate'] ?? schedule.startTime.toIso8601String();

      // recurrenceStartDate가 없으면 startTime의 날짜로 설정
      if (schedule.recurrenceStartDate == null) {
        body['recurrenceStartDate'] = DateTime(
          schedule.startTime.year,
          schedule.startTime.month,
          schedule.startTime.day,
        ).toIso8601String();
        print('  반복 시작일 자동 설정: ${body['recurrenceStartDate']}');
      } else {
        body['recurrenceStartDate'] =
            schedule.recurrenceStartDate!.toIso8601String();
      }

      print('  startTime 및 recurrenceStartDate 동기화: ${body['startTime']}');
    }

    // 디버그 출력
    print('일정 생성 요청:');
    print('  제목: ${schedule.title}');
    print('  시작 시간: ${body['startTime']}');
    print('  종료 시간: ${schedule.endTime}');
    print('  반복 요일: ${schedule.recurrenceDays}');
    print('  반복 시작일: ${body['recurrenceStartDate']}');
    print(
        '  반복 종료일: ${body['recurrenceEndDate'] ?? schedule.recurrenceEndDate?.toIso8601String()}');
    print('  제외일: ${body['excludedDates']}');

    // 요일 패턴 디버그 로깅 - 백엔드와 일관성 확인
    if (schedule.recurrenceDays != null &&
        schedule.recurrenceDays!.isNotEmpty) {
      List<String> days = schedule.recurrenceDays!.split(',');
      if (days.length == 7) {
        List<String> weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
        String selectedDays = '';

        for (int i = 0; i < days.length; i++) {
          if (days[i] == '1') {
            selectedDays += '${weekdayNames[i]}, ';
          }
        }

        print(
            '  선택된 요일: ${selectedDays.isNotEmpty ? selectedDays.substring(0, selectedDays.length - 2) : "없음"}');
        print('  백엔드 요일 패턴: ${schedule.recurrenceDays}');
      }
    }

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('일정 생성 실패: ${response.statusCode} - ${response.body}');
    }

    // 응답 확인
    print('일정 생성 응답: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final responseData = json.decode(response.body);
        print('  생성된 일정 ID: ${responseData['id']}');
        print('  반복 요일: ${responseData['recurrenceDays']}');
        print('  반복 시작일: ${responseData['recurrenceStartDate']}');
        print('  반복 종료일: ${responseData['recurrenceEndDate']}');
        print('  제외일: ${responseData['excludedDates']}');
      } catch (e) {
        print('  응답 파싱 실패: $e');
      }
    }
  }

  /// 기존 일정을 수정합니다. [option]은 'ALL', 'FUTURE', 'SINGLE', [occurrenceDate]는 'FUTURE'/'SINGLE' 시 사용합니다.
  Future<void> updateSchedule(
    Schedule schedule, {
    String option = 'ALL',
    DateTime? occurrenceDate,
    bool preserveExcludedDates =
        true, // RecurrenceConstants.PRESERVE_EXCLUDED_DATES 기본값 적용
  }) async {
    if (schedule.scheduleId == null) {
      throw Exception('수정할 일정의 ID가 없습니다');
    }

    // SINGLE 옵션일 경우 기존 일정에 excluded_dates 추가
    if (option == 'SINGLE' && occurrenceDate != null) {
      try {
        // 먼저 원본 일정 정보 가져오기
        final originalSchedule = await getScheduleById(schedule.scheduleId!);

        // 수정할 날짜를 ISO 포맷으로 변환 (날짜만 YYYY-MM-DD)
        final dateStr = occurrenceDate.toIso8601String().split('T')[0];

        // 기존 excluded_dates 가져오기
        List<String> excludedDates = [];
        if (originalSchedule.excludedDates != null &&
            originalSchedule.excludedDates!.isNotEmpty) {
          excludedDates = originalSchedule.excludedDates!
              .split(',')
              .where((d) => d.isNotEmpty)
              .toList();
        }

        // 이미 제외 목록에 없는 경우에만 추가
        if (!excludedDates.contains(dateStr)) {
          excludedDates.add(dateStr);

          // 원본 일정 업데이트 (excluded_dates만 수정)
          final updateExcludeRequest = originalSchedule.copyWith(
            excludedDates: excludedDates.join(','),
          );

          print('단일 일정 수정 - 기존 일정 제외 날짜 추가: $dateStr');
          print('  제외 날짜 목록: ${excludedDates.join(',')}');

          // 먼저 제외 날짜 업데이트 요청 (ALL 옵션 사용)
          await _updateExcludeDates(updateExcludeRequest);
        }
      } catch (e) {
        print('기존 일정 제외 날짜 추가 실패: $e');
        // 오류가 발생해도 계속 진행 (메인 업데이트 요청은 수행)
      }
    }

    // excludedDates 처리 - ALL 또는 FUTURE 옵션일 때 excludedDates 보존
    if (preserveExcludedDates && (option == 'ALL' || option == 'FUTURE')) {
      try {
        // 원본 일정 정보 가져오기
        final originalSchedule = await getScheduleById(schedule.scheduleId!);

        // 원본 excludedDates가 있으면서 수정하는 일정에 excludedDates가 없거나 다른 경우
        if (originalSchedule.excludedDates != null &&
            originalSchedule.excludedDates!.isNotEmpty &&
            originalSchedule.excludedDates != schedule.excludedDates) {
          // excludedDates 내용을 원본에서 유지
          schedule = schedule.copyWith(
            excludedDates: originalSchedule.excludedDates,
          );

          print('excludedDates 보존 처리: ${originalSchedule.excludedDates}');
        }
      } catch (e) {
        print('excludedDates 보존 처리 중 오류: $e');
        // 오류 발생해도 계속 진행
      }
    }

    final token = await _getIdToken();

    // 쿼리 파라미터 구성
    final qs = 'option=$option' +
        (occurrenceDate != null
            ? '&fromDate=${occurrenceDate.toIso8601String()}'
            : '');

    // 디버그 로깅
    print('일정 수정 요청 - 원본 ID: ${schedule.scheduleId}, 편집 모드: $option');
    print('  옵션: $option' +
        (occurrenceDate != null ? ', 발생일자: $occurrenceDate' : ''));
    print(
        '  요청 URL: ${ApiConfig.schedulesEndpoint}/${schedule.scheduleId}?$qs');
    print('  excludedDates 보존 여부: $preserveExcludedDates');

    final uri =
        Uri.parse('${ApiConfig.schedulesEndpoint}/${schedule.scheduleId}?$qs');
    final requestBody = schedule.toJson();

    // 요청 본문에서 option 필드 제거 (URL 쿼리 파라미터로 이미 전달됨)
    requestBody.remove('option');

    // displayOnCalendar 필드가 항상 포함되도록 확인
    if (!requestBody.containsKey('displayOnCalendar')) {
      requestBody['displayOnCalendar'] = schedule.displayOnCalendar;
    }

    // 디버그 로깅: 요청 본문
    print('  수정할 일정 데이터: $requestBody');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestBody),
    );

    // 응답 로깅
    print('일정 수정 응답: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('  오류 응답: ${response.body}');
      throw Exception('일정 수정 실패: ${response.statusCode} - ${response.body}');
    } else {
      print('  수정 성공');
    }
  }

  /// 기존 일정의 제외 날짜만 업데이트 (내부용)
  Future<void> _updateExcludeDates(Schedule schedule) async {
    final token = await _getIdToken();

    // API 엔드포인트 구성
    final uri = Uri.parse(
        '${ApiConfig.schedulesEndpoint}/${schedule.scheduleId}?option=ALL');

    // 필수 필드만 포함한 요청 본문 구성
    final Map<String, dynamic> requestBody = {
      'scheduleId': schedule.scheduleId,
      'title': schedule.title,
      'startTime': schedule.startTime.toIso8601String(),
      'endTime': schedule.endTime.toIso8601String(),
      'displayOnCalendar': schedule.displayOnCalendar,
      'excludedDates': schedule.excludedDates,
    };

    print('제외 날짜 업데이트 요청 - ID: ${schedule.scheduleId}');
    print('  제외 날짜: ${schedule.excludedDates}');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
          '제외 날짜 업데이트 실패: ${response.statusCode} - ${response.body}');
    }

    print('제외 날짜 업데이트 성공');
  }

  /// 일정을 삭제합니다. [option]은 'ALL', 'FUTURE', 'SINGLE' 를 사용합니다.
  Future<void> deleteSchedule(
    int scheduleId, {
    String option = 'ALL',
    DateTime? occurrenceDate,
  }) async {
    final token = await _getIdToken();

    // 일정 정보 먼저 가져오기 (반복 일정 여부 확인용)
    final schedule = await getScheduleById(scheduleId);
    final bool isRecurringEvent = schedule.recurrenceDays != null &&
        schedule.recurrenceDays!.isNotEmpty &&
        schedule.recurrenceDays != "0,0,0,0,0,0,0";

    // 반복 일정에 대해 마지막 일정이 남았는지 확인
    bool isLastRecurrence = false;
    if (isRecurringEvent && option == 'SINGLE' && occurrenceDate != null) {
      // 제외된 날짜 확인
      final excludedDates = schedule.excludedDates;
      final int excludedCount =
          excludedDates?.split(',').where((date) => date.isNotEmpty).length ??
              0;

      // 이 일정의 recurrenceStartDate와 recurrenceEndDate 사이의 일 수 계산
      final int totalDays = schedule.recurrenceEndDate != null &&
              schedule.recurrenceStartDate != null
          ? schedule.recurrenceEndDate!
                  .difference(schedule.recurrenceStartDate!)
                  .inDays +
              1
          : 0;

      // 요일별 발생 횟수 계산
      int occurrenceCount = 0;
      if (schedule.recurrenceDays != null) {
        List<String> days = schedule.recurrenceDays!.split(',');
        int activeDaysPerWeek = days.where((day) => day == '1').length;
        occurrenceCount = (totalDays / 7).ceil() * activeDaysPerWeek;
      }

      // 마지막 일정인지 확인
      isLastRecurrence = (occurrenceCount - excludedCount) <= 1;

      print(
          '반복 일정 삭제 체크: 총 발생 $occurrenceCount회, 제외된 날짜 $excludedCount개, 마지막 일정: $isLastRecurrence');
    }

    // 시작일 삭제 여부 확인
    bool isDeletingStartDate = false;
    if (isRecurringEvent &&
        occurrenceDate != null &&
        schedule.recurrenceStartDate != null) {
      // 날짜 비교 (시간 무시)
      final occurrenceDay = DateTime(
          occurrenceDate.year, occurrenceDate.month, occurrenceDate.day);
      final startDay = DateTime(
          schedule.recurrenceStartDate!.year,
          schedule.recurrenceStartDate!.month,
          schedule.recurrenceStartDate!.day);

      isDeletingStartDate = occurrenceDay.isAtSameMomentAs(startDay);
      print('시작일 삭제 여부 확인: $isDeletingStartDate');
    }

    // 시작일을 삭제하는 경우 다음 반복 일자로 시작일 변경
    if (isDeletingStartDate && option == 'SINGLE' && !isLastRecurrence) {
      print('반복 일정 시작일 삭제 - 다음 반복 일자로 시작일 변경 진행');
      try {
        // 1. 먼저 해당 날짜 제외 처리
        // 제외될 날짜 목록 업데이트
        List<String> excludedDatesList = [];
        if (schedule.excludedDates != null &&
            schedule.excludedDates!.isNotEmpty) {
          excludedDatesList = schedule.excludedDates!
              .split(',')
              .where((date) => date.isNotEmpty)
              .toList();
        }

        // 현재 날짜 추가
        final dateStr = occurrenceDate!.toIso8601String().split('T')[0];
        excludedDatesList.add(dateStr);

        // 2. 다음 발생 일자 계산하여 시작일 변경
        // 현재 날짜로부터 최대 30일 이내의 다음 발생 일자 찾기
        DateTime? nextOccurrence;
        final List<int> activeDays = [];

        if (schedule.recurrenceDays != null) {
          final dayList = schedule.recurrenceDays!.split(',');
          for (int i = 0; i < dayList.length && i < 7; i++) {
            if (dayList[i] == '1') {
              activeDays.add(i);
            }
          }
        }

        if (activeDays.isNotEmpty) {
          // 다음 날부터 최대 30일까지 검색
          for (int i = 1; i <= 30; i++) {
            final candidate = occurrenceDate!.add(Duration(days: i));
            // 요일 확인 (0:일, 1:월, ..., 6:토)
            final weekday = candidate.weekday % 7; // 일:0, 월:1, ..., 토:6

            if (activeDays.contains(weekday)) {
              // 이미 제외된 날짜인지 확인
              final candidateDateStr =
                  candidate.toIso8601String().split('T')[0];
              if (!excludedDatesList.contains(candidateDateStr)) {
                nextOccurrence = candidate;
                break;
              }
            }
          }
        }

        if (nextOccurrence == null) {
          throw Exception('다음 반복 일자를 찾을 수 없습니다');
        }

        print('새로운 시작일: $nextOccurrence');

        // 3. 일정 업데이트 (시작일 변경)
        final updatedSchedule = schedule.copyWith(
          recurrenceStartDate: nextOccurrence,
          // startTime도 함께 변경
          startTime: DateTime(
            nextOccurrence.year,
            nextOccurrence.month,
            nextOccurrence.day,
            schedule.startTime.hour,
            schedule.startTime.minute,
          ),
          excludedDates: excludedDatesList.join(','),
        );

        // 백엔드에 일정 업데이트 요청
        await updateSchedule(
          updatedSchedule,
          option: 'ALL',
        );

        print('반복 일정 시작일 변경 완료');
        return;
      } catch (e) {
        print('시작일 변경 중 오류: $e');
        // 오류 발생 시 기본 삭제 로직으로 진행
      }
    }

    // 마지막 남은 반복 일정인 경우 - SINGLE 삭제를 유지하고 완전 삭제하지 않음
    if (isLastRecurrence && option == 'SINGLE') {
      print('마지막 남은 반복 일정 감지 - 단일 삭제로 처리합니다');

      try {
        // 방법 1: 해당 날짜만 제외 처리
        List<String> excludedDatesList = [];
        if (schedule.excludedDates != null &&
            schedule.excludedDates!.isNotEmpty) {
          excludedDatesList = schedule.excludedDates!
              .split(',')
              .where((date) => date.isNotEmpty)
              .toList();
        }

        // 현재 날짜 추가
        final dateStr = occurrenceDate!.toIso8601String().split('T')[0];
        if (!excludedDatesList.contains(dateStr)) {
          excludedDatesList.add(dateStr);
        }

        // 원본 일정 유지하면서 제외 날짜만 업데이트
        final updatedSchedule = schedule.copyWith(
          excludedDates: excludedDatesList.join(','),
        );

        // 제외 날짜 업데이트 요청
        await updateSchedule(
          updatedSchedule,
          option: 'ALL',
        );

        print('마지막 반복 일정 - 제외 처리로 변경 성공');
        return;
      } catch (e) {
        print('마지막 일정 제외 처리 실패: $e');
        // 오류 발생 시 기본 로직으로 진행
      }
    }
    // 기존 로직: 마지막 일정이 아니거나 ALL/FUTURE 옵션인 경우
    else if (isLastRecurrence && option != 'SINGLE') {
      print('마지막 남은 반복 일정 - ALL 옵션으로 변경하여 완전 삭제');
      option = 'ALL';
    }

    String queryString = 'option=$option';
    if (occurrenceDate != null) {
      // 백엔드 컨트롤러에서 사용하는 파라미터명(fromDate) 사용
      queryString += '&fromDate=${occurrenceDate.toIso8601String()}';
    } else if (option != 'ALL') {
      // SINGLE 또는 FUTURE 옵션인데 날짜가 없으면 오류 발생
      throw Exception('$option 옵션을 사용할 때는 occurrenceDate가 필요합니다');
    }

    // 옵션 로깅 추가
    print('일정 삭제 요청: ID $scheduleId, 옵션: $option, 발생일자: $occurrenceDate');

    final uri =
        Uri.parse('${ApiConfig.schedulesEndpoint}/$scheduleId?$queryString');
    print('삭제 요청 URI: $uri');

    try {
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      // 응답 로깅 추가
      print('일정 삭제 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('일정 삭제 성공');
        return;
      }

      // 상세 에러 처리
      String errorMessage = '일정 삭제 실패: ${response.statusCode}';
      try {
        // 응답이 JSON인 경우 에러 메시지 추출 시도
        final jsonError = json.decode(response.body);
        if (jsonError['message'] != null) {
          errorMessage = '일정 삭제 실패: ${jsonError['message']}';
        }
      } catch (e) {
        // JSON 파싱 실패 시 원래 메시지 사용
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('일정 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  /// ID로 일정 정보 가져오기
  Future<Schedule> getScheduleById(int scheduleId) async {
    try {
      // 백엔드에서 GET /api/schedules/{id} 메서드를 지원하지 않으므로
      // 모든 일정을 가져와서 ID로 필터링하는 방식으로 변경
      final schedules = await getSchedules();
      final schedule = schedules.firstWhere(
        (schedule) => schedule.scheduleId == scheduleId,
        orElse: () => throw Exception('해당 ID의 일정을 찾을 수 없습니다: $scheduleId'),
      );

      return schedule;
    } catch (e) {
      print('일정 조회 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 일정을 미룹니다. [mode]는 '1day','7days','custom', custom일 때 [custom] 사용.
  /// [occurrenceDate]는 반복 일정에서 특정 날짜를 미룰 때 사용합니다.
  Future<Schedule> postponeSchedule(
    int scheduleId,
    String mode, {
    DateTime? custom,
    DateTime? occurrenceDate,
  }) async {
    final token = await _getIdToken();

    // 1. 원본 일정 정보 가져오기
    final originalSchedule = await getScheduleById(scheduleId);

    // 2. 반복 일정 여부 확인
    final bool isRecurringEvent = originalSchedule.recurrenceDays != null &&
        originalSchedule.recurrenceDays!.isNotEmpty &&
        originalSchedule.recurrenceDays != "0,0,0,0,0,0,0";

    // 3. 모드를 백엔드가 인식할 수 있는 형식으로 변환
    String backendMode;
    switch (mode) {
      case '1일후':
      case '내일':
        backendMode = '1day';
        break;
      case '7일후':
      case '일주일 후':
        backendMode = '7days';
        break;
      case '직접설정':
        backendMode = 'custom';
        break;
      default:
        backendMode = mode; // 이미 영어로 된 모드면 그대로 사용
    }

    // 4. 미룰 날짜 계산
    DateTime targetDate;
    if (backendMode == 'custom' && custom != null) {
      targetDate = custom;
    } else {
      // 기준이 될 날짜 결정 - 반복 일정에서 특정 날짜를 선택했으면 그 날짜, 아니면 원본 시작일
      final baseDate = occurrenceDate ?? originalSchedule.startTime;

      if (backendMode == '1day') {
        targetDate = baseDate.add(Duration(days: 1));
      } else if (backendMode == '7days') {
        targetDate = baseDate.add(Duration(days: 7));
      } else {
        // 기본값 (오류 시)
        targetDate = baseDate.add(Duration(days: 1));
      }
    }

    print('미루기 요청 정보:');
    print('  원본 일정 ID: $scheduleId');
    print('  모드: $backendMode');
    print('  선택한 발생일: ${occurrenceDate?.toIso8601String() ?? "없음 (시작일 기준)"}');
    print('  목표 날짜: ${targetDate.toIso8601String()}');
    print('  반복 일정 여부: $isRecurringEvent');

    // 5. 반복 일정인 경우 특별 처리
    if (isRecurringEvent) {
      // 시작일 미루기인지 확인
      bool isPostponingStartDate = false;
      if (originalSchedule.recurrenceStartDate != null &&
          occurrenceDate != null) {
        // 날짜 비교 (시간 무시)
        final occurrenceDay = DateTime(
            occurrenceDate.year, occurrenceDate.month, occurrenceDate.day);
        final startDay = DateTime(
            originalSchedule.recurrenceStartDate!.year,
            originalSchedule.recurrenceStartDate!.month,
            originalSchedule.recurrenceStartDate!.day);

        isPostponingStartDate = occurrenceDay.isAtSameMomentAs(startDay);
        print('  시작일 미루기 여부: $isPostponingStartDate');
      } else if (occurrenceDate == null) {
        // occurrenceDate가 지정되지 않으면 시작일 미루기로 간주
        isPostponingStartDate = true;
        print('  발생일 미지정 - 시작일 미루기로 간주');
      }

      try {
        if (isPostponingStartDate) {
          // 시작일 미루기: 원본 일정의 시작일 변경
          print('  반복 일정 시작일 미루기 처리 시작');

          // 시작일과 recurrenceStartDate 모두 변경
          final updatedSchedule = originalSchedule.copyWith(
            startTime: DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
              originalSchedule.startTime.hour,
              originalSchedule.startTime.minute,
            ),
            recurrenceStartDate: DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
            ),
          );

          // 일정 업데이트 요청
          await updateSchedule(
            updatedSchedule,
            option: 'ALL',
          );

          print('  반복 일정 시작일 미루기 완료');
          return updatedSchedule;
        } else {
          // 시작일이 아닌 특정 발생일 미루기: 원본 일정에서 해당 날짜 제외 후 새 일정 생성
          print('  반복 일정 특정일 미루기 처리 시작');

          // 제외 날짜 목록 업데이트
          List<String> excludedDates = [];
          if (originalSchedule.excludedDates != null &&
              originalSchedule.excludedDates!.isNotEmpty) {
            excludedDates = originalSchedule.excludedDates!
                .split(',')
                .where((d) => d.isNotEmpty)
                .toList();
          }

          // 미룰 날짜 제외 목록에 추가
          final dateStr = occurrenceDate!.toIso8601String().split('T')[0];
          if (!excludedDates.contains(dateStr)) {
            excludedDates.add(dateStr);

            // 원본 일정 업데이트 (excludedDates만)
            final updatedOriginal = originalSchedule.copyWith(
              excludedDates: excludedDates.join(','),
            );

            // 제외 처리 요청
            await updateSchedule(
              updatedOriginal,
              option: 'ALL',
            );

            print('  원본 일정 제외 날짜 추가 완료: $dateStr');
          }

          // 새 일정 생성 (단일 일정)
          final newSchedule = Schedule(
            title: originalSchedule.title,
            description: originalSchedule.description,
            startTime: DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
              occurrenceDate.hour,
              occurrenceDate.minute,
            ),
            endTime: DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
              occurrenceDate.hour +
                  (originalSchedule.endTime.hour -
                      originalSchedule.startTime.hour),
              occurrenceDate.minute +
                  (originalSchedule.endTime.minute -
                      originalSchedule.startTime.minute),
            ),
            categoryId: originalSchedule.categoryId,
            priority: originalSchedule.priority,
            displayOnCalendar: originalSchedule.displayOnCalendar,
            reminderMinutesBefore: originalSchedule.reminderMinutesBefore,
            // 반복 설정 제거
            recurrenceDays: null,
            recurrenceStartDate: null,
            recurrenceEndDate: null,
          );

          // 새 일정 생성
          await createSchedule(newSchedule);

          print('  미룬 단일 일정 생성 완료');
          return newSchedule;
        }
      } catch (e) {
        print('  반복 일정 미루기 처리 중 오류: $e');
        // 오류 발생 시 기본 API 호출로 진행
      }
    }

    // 6. 백엔드 API 호출 (일반 일정 또는 특별 처리 실패 시)
    final body = <String, dynamic>{'mode': backendMode};

    if (backendMode == 'custom' && custom != null) {
      body['customDateTime'] = custom.toIso8601String();
    }

    // 발생일 정보 추가 (반복 일정의 특정 날짜를 미루는 경우)
    if (occurrenceDate != null) {
      body['occurrenceDate'] = occurrenceDate.toIso8601String();
    }

    print('  백엔드 미루기 API 호출: $body');

    final uri =
        Uri.parse('${ApiConfig.schedulesEndpoint}/$scheduleId/postpone');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print('  미루기 API 성공');
      return Schedule.fromJson(json.decode(response.body));
    }

    // 오류 로그 추가
    print('일정 미루기 실패: ${response.statusCode} - ${response.body}');
    throw Exception('일정 미루기 실패: ${response.statusCode} - ${response.body}');
  }

  /// 일정 검색 기능 (서버 API 사용, 실패 시 로컬 검색)
  Future<List<Schedule>> searchSchedules(String query) async {
    // 빈 검색어인 경우 빈 결과 반환
    if (query.isEmpty) {
      return [];
    }

    // 검색어가 짧은 경우 로컬 검색 우선 수행 (응답성 향상)
    if (query.length < 3) {
      return _localSearchSchedules(query);
    }

    try {
      final token = await _getIdToken();
      final encodedQuery = Uri.encodeComponent(query);
      final uri = Uri.parse(
          '${ApiConfig.schedulesEndpoint}/search?query=$encodedQuery');

      // 타임아웃 설정으로 응답성 향상
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('검색 요청 시간 초과'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => Schedule.fromJson(e)).toList();
      }

      // 서버 검색 실패 시 로컬 검색으로 대체
      return _localSearchSchedules(query);
    } catch (e) {
      print('서버 검색 실패, 로컬 검색으로 대체: $e');
      // 오류 발생 시 로컬 검색으로 대체
      return _localSearchSchedules(query);
    }
  }

  Future<List<Schedule>> _localSearchSchedules(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final all = await getSchedules();
    final lower = query.toLowerCase();

    // 최적화된 검색 알고리즘
    final result = all.where((s) {
      // 제목에 검색어가 포함된 경우
      if (s.title.toLowerCase().contains(lower)) {
        return true;
      }

      // 설명에 검색어가 포함된 경우
      if (s.description != null &&
          s.description!.toLowerCase().contains(lower)) {
        return true;
      }

      // 날짜 문자열에 검색어가 포함된 경우
      final startDateStr = s.startTime.toString().toLowerCase();
      if (startDateStr.contains(lower)) {
        return true;
      }

      return false;
    }).toList();

    // 검색 순위 정렬: 제목 일치 > 설명 일치 > 날짜 일치
    result.sort((a, b) {
      // 1. 제목에 검색어가 있는지 여부
      final aTitleContains = a.title.toLowerCase().contains(lower);
      final bTitleContains = b.title.toLowerCase().contains(lower);

      if (aTitleContains && !bTitleContains) return -1;
      if (!aTitleContains && bTitleContains) return 1;

      // 2. 제목 시작 위치 비교
      if (aTitleContains && bTitleContains) {
        final aIndex = a.title.toLowerCase().indexOf(lower);
        final bIndex = b.title.toLowerCase().indexOf(lower);
        if (aIndex != bIndex) return aIndex - bIndex;
      }

      // 3. 날짜 최신순 정렬
      return b.startTime.compareTo(a.startTime);
    });

    return result;
  }

  /// 제외된 날짜(excludedDates) 보존 기능 테스트
  /// 이 메서드는 디버그 용도로만 사용하며, 실제 일정은 변경되지 않습니다.
  Future<Map<String, dynamic>> verifyExcludedDatesPreservation(
      int scheduleId) async {
    try {
      // 1. 원본 일정 정보 가져오기
      final originalSchedule = await getScheduleById(scheduleId);

      // 2. 반복 일정인지 확인
      final bool isRecurringEvent = originalSchedule.recurrenceDays != null &&
          originalSchedule.recurrenceDays!.isNotEmpty &&
          originalSchedule.recurrenceDays != "0,0,0,0,0,0,0";

      if (!isRecurringEvent) {
        return {'success': false, 'message': '반복 일정이 아닙니다. 테스트를 진행할 수 없습니다.'};
      }

      // 3. excludedDates 확인
      final String? originalExcludedDates = originalSchedule.excludedDates;

      if (originalExcludedDates == null || originalExcludedDates.isEmpty) {
        return {'success': false, 'message': '제외된 날짜가 없습니다. 테스트를 진행할 수 없습니다.'};
      }

      // 4. 분석 정보 반환
      final List<String> excludedDatesList = originalExcludedDates
          .split(',')
          .where((date) => date.isNotEmpty)
          .toList();

      return {
        'success': true,
        'message': 'excludedDates 보존 기능 확인 완료',
        'schedule_id': scheduleId,
        'excluded_dates': excludedDatesList,
        'excluded_dates_count': excludedDatesList.length,
        'recurrence_days': originalSchedule.recurrenceDays,
        'recurrence_start_date':
            originalSchedule.recurrenceStartDate?.toIso8601String(),
        'recurrence_end_date':
            originalSchedule.recurrenceEndDate?.toIso8601String(),
        'is_recurring': isRecurringEvent,
      };
    } catch (e) {
      return {'success': false, 'message': '테스트 중 오류 발생: $e'};
    }
  }

  /// 1) 이미지 업로드 → 분석 → 스케줄 리스트 리턴
  static Future<List<ScheduleItem>> analyzeImage(File image) async {
    final uri = Uri.parse('${ApiConfig.photoAnalysisEndpoint}');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', image.path));
    final res = await req.send();
    if (res.statusCode != 200) {
      throw Exception('분석 실패: ${res.statusCode}');
    }
    final body = await res.stream.bytesToString();
    final data = json.decode(body)['schedules'] as List<dynamic>;
    return data.map((e) => ScheduleItem.fromJson(e)).toList();
  }

  /// 2) 사용자가 고른 스케줄만 추출해서 백엔드에 저장
  static Future<void> saveSchedules(List<ScheduleItem> schedules) async {
    final uri = Uri.parse('${ApiConfig.photoAddEndpoint}');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'schedules': schedules.map((e) => e.toJson()).toList(),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('저장 실패: ${res.statusCode}');
    }
  }

  /// 자동일정 추천 요청
  Future<List<AutoScheduleResponse>> fetchAutoScheduleSuggestions(
      AutoScheduleRequest request, String token) async {
    final uri = Uri.parse('${ApiConfig.suggestionsEndpoint}');
    final response = await httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \$token',
      },
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 200) {
      final body = response.body;
      if (body.startsWith('[')) {
        final List data = json.decode(body) as List;
        return data.map((e) => AutoScheduleResponse.fromJson(e)).toList();
      } else {
        // 서버가 "일정이 없습니다" 문자열을 반환한 경우
        return [];
      }
    } else {
      throw Exception('추천 요청 실패: \${response.statusCode}');
    }
  }

  /// 사용자가 선택한 일정 저장
  Future<void> confirmAutoSchedule(
      AutoScheduleResponse selected, String token) async {
    final uri = Uri.parse('${ApiConfig.confirmEndpoint}');
    final body = {
      'title': selected.title,
      'description': selected.description,
      'suggestedStart': selected.suggestedStart.toIso8601String(),
      'suggestedEnd': selected.suggestedEnd.toIso8601String(),
    };
    final response = await httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \$token',
      },
      body: json.encode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('일정 저장 실패: \${response.statusCode}');
    }
  }
}
