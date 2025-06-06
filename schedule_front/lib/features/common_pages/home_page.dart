import 'package:flutter/material.dart';
import 'package:schedule/features/common_widgets/add_button.dart';
import 'package:schedule/features/schedule/presentation/widgets/recurrence_delete_dialog.dart';
import '../schedule/domain/models/schedule.dart';
import '../schedule/domain/models/reminder.dart';
import '../schedule/domain/models/priority.dart';
import '../schedule/domain/models/Recurrence_option.Dart';
import '../schedule/domain/services/schedule_service.dart';
import '../schedule/domain/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/api_config.dart';
import '../schedule/presentation/pages/edit_reminder_page.dart';
import '../schedule/presentation/pages/edit_schedule_page.dart';
import '../schedule/presentation/pages/schedule_from_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScheduleService _scheduleService = ScheduleService();
  final ReminderService _reminderService = ReminderService();
  List<Schedule> _schedules = [];
  List<Schedule> _groupSchedules = [];
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _username = '';
  DateTime? _createdAt;
  int _daysSinceCreation = 0;
  
  // 체크박스 상태를 전역으로 관리
  Map<String, bool> _checkedState = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken(true);
        
        final response = await http.get(
          Uri.parse(ApiConfig.userEndpoint),
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        );

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          if (mounted) {
            setState(() {
              // 사용자 이름이 비어있으면 기본 이름 사용
              _username = userData['username'] ?? user.displayName ?? 'User';
              
              // 생성 날짜 기반으로 일차 계산
              if (userData['createdAt'] != null) {
                try {
                  print('원본 createdAt: ${userData['createdAt']}');
                  
                  // String 형태의 생성일자를 DateTime으로 변환
                  DateTime createdDate;
                  
                  try {
                    // 정확한 포맷 명시하여 파싱 시도
                    final dateStr = userData['createdAt'].toString();
                    
                    // 마이크로초 제거 (초 단위까지만 사용)
                    final simplifiedDateStr = dateStr.split('.')[0];
                    createdDate = DateTime.parse(simplifiedDateStr);
                    print('정제된 날짜 문자열: $simplifiedDateStr → $createdDate');
                  } catch (parseError) {
                    print('기본 파싱 실패, 대체 방법 시도: $parseError');
                    // 기본 파싱 시도
                    createdDate = DateTime.parse(userData['createdAt'].toString());
                  }
                  
                  // 날짜만 추출하여 비교 (시간 무시)
                  final createdDateOnly = DateTime(
                    createdDate.year,
                    createdDate.month,
                    createdDate.day
                  );
                  
                  final today = DateTime.now();
                  final todayOnly = DateTime(
                    today.year,
                    today.month,
                    today.day
                  );
                  
                  print('생성일: $createdDateOnly, 비교 날짜: $todayOnly');
                  // 날짜 차이 계산 (일수) - 현재 날짜와 생성 날짜 차이에 1을 더함 (당일 포함)
                  final dayDiff = todayOnly.difference(createdDateOnly).inDays;
                  _daysSinceCreation = dayDiff + 1;
                  print('일차 계산 결과: $dayDiff + 1 = $_daysSinceCreation');
                } catch (e) {
                  print('날짜 계산 오류: $e');
                  _daysSinceCreation = 1; // 오류 시 기본값
                }
              } else {
                _daysSinceCreation = 1; // 생성 날짜 없을 경우 기본값
              }
            });
          }
        } else {
          // API 응답 실패 시 기본값 설정
          if (mounted) {
            setState(() {
              _username = user.displayName ?? user.email?.split('@').first ?? 'User';
              _daysSinceCreation = 1;
            });
          }
        }
      }
    } catch (e) {
      // 사용자 정보 로드 실패 시 기본값 사용
      if (mounted) {
        setState(() {
          final user = FirebaseAuth.instance.currentUser;
          _username = user?.displayName ?? user?.email?.split('@').first ?? 'User';
          _daysSinceCreation = 1;
        });
      }
      print('사용자 정보 로드 오류: $e');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final schedules = await _scheduleService.getSchedules();
      final reminders = await _reminderService.getReminders();
      final groupSchedules = await _loadGroupSchedules();

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _reminders = reminders;
        _groupSchedules = groupSchedules;
        _isLoading = false;
        
        // 체크박스 상태 초기화 - 개선된 방식
        _checkedState.clear(); // 기존 상태 초기화
        for (var reminder in _reminders) {
          if (reminder.reminderId != null) {
            // 서버에서 가져온 상태 사용 (checkedDate가 존재하고 오늘 날짜이면 체크된 상태)
            bool isChecked = false;
            if (reminder.checkedDate != null) {
              final today = DateTime.now();
              final checkedDay = DateTime(
                reminder.checkedDate!.year,
                reminder.checkedDate!.month,
                reminder.checkedDate!.day,
              );
              final todayDay = DateTime(today.year, today.month, today.day);
              
              // 오늘 체크된 항목이면 체크 상태로 표시
              isChecked = checkedDay.isAtSameMomentAs(todayDay);
              print('리마인더 ${reminder.reminder_title} - 체크날짜: ${reminder.checkedDate}, 체크상태: $isChecked');
            }
            _checkedState[reminder.reminderId!.toString()] = isChecked;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 로드 실패: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<List<Schedule>> _loadGroupSchedules() async {
    try {
      // ScheduleService를 사용하여 그룹 일정을 가져옴
      final schedules = await _scheduleService.getGroupSchedules();
      return schedules;
    } catch (e) {
      print('모임일정 로드 실패: $e');
      return [];
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      // 날짜가 변경되면 데이터 다시 로드
      _loadData();
    }
  }

  String _getFormattedDate() {
    final weekdayKorean = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayIndex = _selectedDate.weekday - 1; // 1(월) ~ 7(일) -> 0 ~ 6
    return '${DateFormat('yyyy/MM/dd').format(_selectedDate)}(${weekdayKorean[weekdayIndex]})';
  }

  // 체크박스 상태 변경 핸들러
  void _handleCheckboxChange(Reminder reminder, bool? value) async {
    if (reminder.reminderId == null) {
      print('리마인더 ID가 null입니다: $reminder');
      return;
    }
    
    final reminderId = reminder.reminderId.toString();
    final isChecked = value ?? false;
    
    // 체크박스 상태 로컬 업데이트 
    setState(() {
      _checkedState[reminderId] = isChecked;
      
      // 체크한 리마인더가 UI에서 바로 사라지지 않도록 데이터 모델도 수정
      // 여기서는 isActive를 true로 유지하고 checkedDate만 업데이트
      for (int i = 0; i < _reminders.length; i++) {
        if (_reminders[i].reminderId == reminder.reminderId) {
          _reminders[i] = _reminders[i].copyWith(
            checkedDate: isChecked ? DateTime.now() : null,
            isActive: true, // isActive는 항상 true로 유지
          );
          break;
        }
      }
    });
    
    try {
      // 현재 날짜/시간 정보
      final now = DateTime.now();
      
      // 새로운 토글 체크 API 엔드포인트 호출하기
      final response = await http.put(
        Uri.parse('${ApiConfig.remindersEndpoint}/$reminderId/toggle-check'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await FirebaseAuth.instance.currentUser!.getIdToken()}'
        },
        body: json.encode({
          'isChecked': isChecked
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
      
      print('리마인더 체크 상태 업데이트 성공: $isChecked');
      
      // 백엔드 응답에서 업데이트된 리마인더 정보를 받아 저장
      final updatedReminder = Reminder.fromJson(jsonDecode(response.body));
      
      // 로컬 상태 업데이트 (체크 날짜 정보)
      setState(() {
        for (int i = 0; i < _reminders.length; i++) {
          if (_reminders[i].reminderId == reminder.reminderId) {
            _reminders[i] = updatedReminder;
            break;
          }
        }
      });
    } catch (e) {
      print('리마인더 업데이트 실패: $e');
      // 실패 시 체크 상태 원복
      if (mounted) {
        setState(() {
          _checkedState[reminderId] = !isChecked;
          
          // 원래 상태로 복원
          for (int i = 0; i < _reminders.length; i++) {
            if (_reminders[i].reminderId == reminder.reminderId) {
              _reminders[i] = _reminders[i].copyWith(
                checkedDate: !isChecked ? DateTime.now() : null,
              );
              break;
            }
          }
        });
      }
    }
  }
  
  // 리마인더 리스트를 가져오는 메서드를 완전히 변경
  List<Reminder> _getActiveReminders() {
    // 오늘 날짜 (시스템 시간 기준)
    final todayDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    
    // 필터링된 리마인더 목록
    List<Reminder> filteredReminders = [];
    
    for (var reminder in _reminders) {
      // 비활성화된 리마인더는 포함하지 않음
      if (reminder.isActive != true) continue;
      
      final reminderId = reminder.reminderId?.toString() ?? '';
      
      // 체크 상태 확인 - 서버에서 가져온 checkedDate 기준으로 판단
      bool isChecked = false;
      if (reminder.checkedDate != null) {
        final checkedDay = DateTime(
          reminder.checkedDate!.year,
          reminder.checkedDate!.month,
          reminder.checkedDate!.day,
        );
        
        // 체크된 날짜가 오늘이면 체크된 상태로 표시
        isChecked = checkedDay.isAtSameMomentAs(todayDate);
        
        // 체크된 날짜가 어제 이전이면 (= 체크 후 00시가 지났으면) 목록에서 제외
        if (checkedDay.isBefore(todayDate)) {
          continue; // 다음 항목으로
        }
      }
      
      // 체크박스 상태 로컬 상태 업데이트
      _checkedState[reminderId] = isChecked;
      
      // 반복 리마인더 처리
      if (reminder.recurrenceDays != null && reminder.recurrenceDays.contains('1')) {
        // 시스템 시간 기준 오늘 요일
        final todayWeekday = DateTime.now().weekday; // 1(월) ~ 7(일)
        final dayIndex = todayWeekday - 1; // 0부터 시작하는 인덱스로 변환
        
        final recurrenceDays = reminder.recurrenceDays.split(',');
        
        // 오늘 요일이 반복 패턴에 있는지 확인
        bool shouldShowToday = recurrenceDays.length > dayIndex && recurrenceDays[dayIndex] == '1';
        
        // 반복 기간 확인
        if (reminder.recurrenceStartDate != null) {
          final startDateOnly = DateTime(
            reminder.recurrenceStartDate!.year,
            reminder.recurrenceStartDate!.month,
            reminder.recurrenceStartDate!.day,
          );
          if (todayDate.isBefore(startDateOnly)) {
            shouldShowToday = false;
          }
        }
        
        if (reminder.recurrenceEndDate != null) {
          final endDateOnly = DateTime(
            reminder.recurrenceEndDate!.year,
            reminder.recurrenceEndDate!.month,
            reminder.recurrenceEndDate!.day,
          );
          if (todayDate.isAfter(endDateOnly)) {
            shouldShowToday = false;
          }
        }
        
        // 제외된 날짜 확인
        if (reminder.excludedDates != null && reminder.excludedDates!.isNotEmpty) {
          final todayStr = '${todayDate.year}-'
              '${todayDate.month.toString().padLeft(2, '0')}-'
              '${todayDate.day.toString().padLeft(2, '0')}';
          
          final excludedDatesList = reminder.excludedDates!.split(',');
          if (excludedDatesList.contains(todayStr)) {
            shouldShowToday = false;
          }
        }
        
        // 반복 패턴에 오늘이 포함되면 리마인더 추가
        if (shouldShowToday) {
          filteredReminders.add(reminder);
        }
      } else {
        // 일반 리마인더의 경우 그냥 추가
        filteredReminders.add(reminder);
      }
    }
    
    // 체크 상태에 따라 정렬 - 체크되지 않은 항목이 먼저 오고, 체크된 항목은 뒤에 배치
    filteredReminders.sort((a, b) {
      final aId = a.reminderId?.toString() ?? '';
      final bId = b.reminderId?.toString() ?? '';
      
      final aChecked = _checkedState[aId] ?? false;
      final bChecked = _checkedState[bId] ?? false;
      
      // 체크 상태 비교 (false가 먼저, true가 나중에)
      if (aChecked != bChecked) {
        return aChecked ? 1 : -1;
      }
      
      // 체크 상태가 같으면 ID 기준으로 정렬
      return aId.compareTo(bId);
    });
    
    return filteredReminders;
  }

  // 선택된 날짜에 해당하는 일정만 필터링
  List<Schedule> _getSchedulesForSelectedDate() {
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    
    // 필터링된 일정 목록
    List<Schedule> filteredSchedules = [];
    
    print('\n[${_selectedDate.toString().split(' ')[0]} 일정 필터링]');
    
    for (var schedule in _schedules) {
      // 모임 일정은 제외
      if (schedule.scheduleType == 'MEETING') {
        continue;
      }
      
      // 1. 일반 일정: 시작 날짜가 선택한 날짜와 일치하는 경우
      final scheduleDate = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      
      if (scheduleDate.isAtSameMomentAs(selectedDateOnly)) {
        print('일반 일정 추가: ${schedule.title} (${schedule.startTime})');
        filteredSchedules.add(schedule);
        continue; // 이미 추가된 일정은 반복 체크 무시
      }
      
      // 2. 반복 일정: recurrenceDays 설정이 있는 경우
      if (schedule.recurrenceDays != null && schedule.recurrenceDays!.isNotEmpty) {
        // 디버그 출력 - 모든 일정 정보 확인
        print('반복 일정 검토 중: ${schedule.title}');
        print('  선택 날짜: $_selectedDate');
        print('  반복 패턴: ${schedule.recurrenceDays}');
        print('  반복 기간: ${schedule.recurrenceStartDate} ~ ${schedule.recurrenceEndDate}');
        
        // 반복 요일 패턴 파싱 (0,0,0,0,0,0,0 형식)
        final List<String> recurrenceDaysList = schedule.recurrenceDays!.split(',');
        
        // 반복 일정이 아닌 경우 건너뛰기 (모든 값이 0)
        if (!schedule.recurrenceDays!.contains("1")) {
          print('  반복 패턴 없음 (모두 0)');
          continue;
        }
        
        // *** 반복 기간 체크 (시작일/종료일이 설정된 경우) ***
        // 시작일 체크를 가장 먼저 수행 - 시작일 이전에는 무조건 표시하지 않음
        if (schedule.recurrenceStartDate != null) {
          // 선택된 날짜가 반복 시작일보다 이전이면 표시하지 않음
          final startDateOnly = DateTime(
            schedule.recurrenceStartDate!.year,
            schedule.recurrenceStartDate!.month,
            schedule.recurrenceStartDate!.day,
          );
          
          print('  시작일 비교: 선택일($selectedDateOnly) vs 시작일($startDateOnly)');
          if (selectedDateOnly.isBefore(startDateOnly)) {
            print('  반복 기간 체크: 선택일이 시작일보다 이전임 -> 표시 안함');
            continue; // 시작일 이전이면 즉시 다음 일정으로 넘어감
          }
        }
        
        // 종료일 체크
        bool isWithinRecurrencePeriod = true;
        if (schedule.recurrenceEndDate != null) {
          // 선택된 날짜가 반복 종료일보다 이후면 표시하지 않음
          final endDateOnly = DateTime(
            schedule.recurrenceEndDate!.year,
            schedule.recurrenceEndDate!.month,
            schedule.recurrenceEndDate!.day,
          );
          
          print('  종료일 비교: 선택일($selectedDateOnly) vs 종료일($endDateOnly)');
          if (selectedDateOnly.isAfter(endDateOnly)) {
            isWithinRecurrencePeriod = false;
            print('  반복 기간 체크: 선택일이 종료일보다 이후임 -> 표시 안함');
          }
        }
        
        if (!isWithinRecurrencePeriod) {
          continue; // 종료일 이후면 다음 일정으로 넘어감
        }
        
        // 제외된 날짜 확인 (excludedDates 필드가 있는 경우)
        bool isExcludedDate = false;
        if (schedule.excludedDates != null && schedule.excludedDates!.isNotEmpty) {
          // yyyy-MM-dd 형식으로 날짜 변환 (월과 일이 한 자리인 경우 앞에 0 추가)
          final year = selectedDateOnly.year.toString();
          final month = selectedDateOnly.month.toString().padLeft(2, '0');
          final day = selectedDateOnly.day.toString().padLeft(2, '0');
          final selectedDateStr = '$year-$month-$day';
          
          final excludedDatesList = schedule.excludedDates!.split(',');
          isExcludedDate = excludedDatesList.contains(selectedDateStr);
          
          if (isExcludedDate) {
            print('  제외된 날짜임: $selectedDateStr');
            continue; // 제외된 날짜면 다음 일정으로 넘어감
          }
        }
        
        // 오류 가능성이 있는 부분 - 요일 인덱스 변환
        // Dart의 weekday: 1(월요일)~7(일요일)
        // 백엔드 recurrenceDays: [월,화,수,목,금,토,일] 순서로 1~7 인덱스 사용 (1=월요일, 7=일요일)
        
        // 선택된 요일을 백엔드 인덱스로 변환 - 새로운 백엔드는 Dart와 동일한 인덱스 사용
        int dayIndex = selectedDateOnly.weekday - 1; // 배열 인덱스는 0부터 시작하므로 1을 빼줌
        
        // 요일별 처리 추가
        String dayName = '';
        switch(selectedDateOnly.weekday) {
          case 1: dayName = '월요일'; break;
          case 2: dayName = '화요일'; break;
          case 3: dayName = '수요일'; break;
          case 4: dayName = '목요일'; break;
          case 5: dayName = '금요일'; break;
          case 6: dayName = '토요일'; break;
          case 7: dayName = '일요일'; break;
        }
        
        // 디버그 출력
        print('  현재 요일: $dayName (dart: ${selectedDateOnly.weekday}, 배열 인덱스: $dayIndex)');
        
        bool patternMatch = false;
        if (recurrenceDaysList.length == 7) {
          patternMatch = recurrenceDaysList[dayIndex] == "1";
          print('  패턴 일치 여부: $patternMatch (인덱스 $dayIndex의 값: ${recurrenceDaysList[dayIndex]})');
          
          // 모든 패턴 요소 출력
          for (int i = 0; i < recurrenceDaysList.length; i++) {
            String dayText = '';
            switch(i) {
              case 0: dayText = '월요일'; break;
              case 1: dayText = '화요일'; break;
              case 2: dayText = '수요일'; break;
              case 3: dayText = '목요일'; break;
              case 4: dayText = '금요일'; break;
              case 5: dayText = '토요일'; break;
              case 6: dayText = '일요일'; break;
            }
            print('    인덱스 $i ($dayText): ${recurrenceDaysList[i]}');
          }
        } else {
          print('  패턴 길이 오류: ${recurrenceDaysList.length}');
        }
        
        print('  반복 기간 내? $isWithinRecurrencePeriod');
        
        // 해당 요일이 반복 패턴에 포함되는지, 반복 기간 내인지, 제외 날짜가 아닌지 확인
        if (recurrenceDaysList.length == 7 && 
            recurrenceDaysList[dayIndex] == "1" && 
            isWithinRecurrencePeriod && 
            !isExcludedDate) {
          
          print('*** 반복 일정 표시 성공 ***');
          print('  일정: ${schedule.title}');
          print('  날짜: $_selectedDate ($dayName, 요일번호: ${selectedDateOnly.weekday})');
          print('  요일 인덱스: $dayIndex -> 값: ${recurrenceDaysList[dayIndex]}');
          print('  반복 범위: ${schedule.recurrenceStartDate} ~ ${schedule.recurrenceEndDate}');
          
          // 일정 복사본 생성 (시작/종료 시간을 선택한 날짜로 조정)
          Schedule recurrentSchedule = Schedule(
            id: schedule.id,
            title: schedule.title,
            description: schedule.description,
            categoryId: schedule.categoryId,
            startTime: DateTime(
              selectedDateOnly.year,
              selectedDateOnly.month,
              selectedDateOnly.day,
              schedule.startTime.hour,
              schedule.startTime.minute,
            ),
            endTime: DateTime(
              selectedDateOnly.year,
              selectedDateOnly.month,
              selectedDateOnly.day,
              schedule.endTime.hour,
              schedule.endTime.minute,
            ),
            recurrenceDays: schedule.recurrenceDays,
            recurrenceStartDate: schedule.recurrenceStartDate,
            recurrenceEndDate: schedule.recurrenceEndDate,
            excludedDates: schedule.excludedDates,
            reminderMinutesBefore: schedule.reminderMinutesBefore,
            reminderTime: schedule.reminderTime,
            priority: schedule.priority,
            displayOnCalendar: schedule.displayOnCalendar,
          );
          
          filteredSchedules.add(recurrentSchedule);
        } else {
          print('  반복 일정 표시 조건 불만족 - 표시 안함');
        }
      }
    }
    
    // 시작 시간 순으로 정렬
    filteredSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // 총 표시할 일정 수 출력
    print('표시할 총 일정 수: ${filteredSchedules.length}개\n');
    
    return filteredSchedules;
  }

  // 선택된 날짜에 해당하는 모임일정만 필터링
  List<Schedule> _getGroupSchedulesForSelectedDate() {
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    
    // 필터링된 모임일정 목록
    List<Schedule> filteredGroupSchedules = [];
    
    for (var schedule in _groupSchedules) {
      // 시작 날짜가 선택한 날짜와 일치하는 경우
      final scheduleDate = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      
      if (scheduleDate.isAtSameMomentAs(selectedDateOnly)) {
        filteredGroupSchedules.add(schedule);
      }
      
      // 반복 일정 처리 - 개인 일정과 동일한 로직 적용
      if (schedule.recurrenceDays != null && schedule.recurrenceDays!.isNotEmpty) {
        // 반복 요일 패턴 파싱
        final List<String> recurrenceDaysList = schedule.recurrenceDays!.split(',');
        
        // 반복 일정이 아닌 경우 건너뛰기 (모든 값이 0)
        if (!schedule.recurrenceDays!.contains("1")) {
          continue;
        }
        
        // 반복 기간 체크
        if (schedule.recurrenceStartDate != null) {
          final startDateOnly = DateTime(
            schedule.recurrenceStartDate!.year,
            schedule.recurrenceStartDate!.month,
            schedule.recurrenceStartDate!.day,
          );
          
          if (selectedDateOnly.isBefore(startDateOnly)) {
            continue;
          }
        }
        
        // 종료일 체크
        bool isWithinRecurrencePeriod = true;
        if (schedule.recurrenceEndDate != null) {
          final endDateOnly = DateTime(
            schedule.recurrenceEndDate!.year,
            schedule.recurrenceEndDate!.month,
            schedule.recurrenceEndDate!.day,
          );
          
          if (selectedDateOnly.isAfter(endDateOnly)) {
            isWithinRecurrencePeriod = false;
          }
        }
        
        if (!isWithinRecurrencePeriod) {
          continue;
        }
        
        // 제외된 날짜 확인
        bool isExcludedDate = false;
        if (schedule.excludedDates != null && schedule.excludedDates!.isNotEmpty) {
          final year = selectedDateOnly.year.toString();
          final month = selectedDateOnly.month.toString().padLeft(2, '0');
          final day = selectedDateOnly.day.toString().padLeft(2, '0');
          final selectedDateStr = '$year-$month-$day';
          
          final excludedDatesList = schedule.excludedDates!.split(',');
          isExcludedDate = excludedDatesList.contains(selectedDateStr);
          
          if (isExcludedDate) {
            continue;
          }
        }
        
        // 요일 인덱스 변환
        int dayIndex = selectedDateOnly.weekday - 1;
        
        if (recurrenceDaysList.length == 7 && 
            recurrenceDaysList[dayIndex] == "1" && 
            isWithinRecurrencePeriod && 
            !isExcludedDate) {
          
          // 일정 복사본 생성 (시작/종료 시간을 선택한 날짜로 조정)
          Schedule recurrentSchedule = Schedule(
            id: schedule.id,
            title: schedule.title,
            description: schedule.description,
            categoryId: schedule.categoryId,
            startTime: DateTime(
              selectedDateOnly.year,
              selectedDateOnly.month,
              selectedDateOnly.day,
              schedule.startTime.hour,
              schedule.startTime.minute,
            ),
            endTime: DateTime(
              selectedDateOnly.year,
              selectedDateOnly.month,
              selectedDateOnly.day,
              schedule.endTime.hour,
              schedule.endTime.minute,
            ),
            recurrenceDays: schedule.recurrenceDays,
            recurrenceStartDate: schedule.recurrenceStartDate,
            recurrenceEndDate: schedule.recurrenceEndDate,
            excludedDates: schedule.excludedDates,
            reminderMinutesBefore: schedule.reminderMinutesBefore,
            reminderTime: schedule.reminderTime,
            priority: schedule.priority,
            displayOnCalendar: schedule.displayOnCalendar,
          );
          
          filteredGroupSchedules.add(recurrentSchedule);
        }
      }
    }
    
    // 시작 시간 순으로 정렬
    filteredGroupSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return filteredGroupSchedules;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: null,
      body: Column(
        children: [
          // 상단 흰색 배경 확장 (상태바까지)
          Container(
            color: Colors.white,
            width: double.infinity,
            child: Column(
              children: [
                // 상단 마진 44픽셀
                SizedBox(height: 44),
                // 커스텀 상단 프레임 (높이 50)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 왼쪽: 날짜 표시
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Text(
                          _getFormattedDate(),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w400, // Regular
                            height: 1.4, // 140% line height
                            letterSpacing: -0.4, // -2.5% letter spacing (16 * -0.025 = -0.4)
                            color: Color(0xFF0062FF), // 0062FF 색상
                          ),
                        ),
                      ),
                      // 오른쪽: 사용자 정보
                      Row(
                        children: [
                          Text(
                            '$_username님, $_daysSinceCreation일차',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w400, // Regular
                              height: 1.4, // 140% line height
                              letterSpacing: -0.4,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/images/userpage.png',
                            width: 28,
                            height: 28,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 메인 콘텐츠
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('오류: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 리마인더 섹션 (날짜 프레임과 거리 20)
                                const SizedBox(height: 20),
                                // 리마인더 제목
                                const Text(
                                  '리마인더',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600, // SemiBold
                                    height: 1.4,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF0062FF),
                                  ),
                                ),
                                // 리마인더 제목과 박스 사이 거리 10
                                const SizedBox(height: 10),
                                // 리마인더 박스
                                if (_reminders.isEmpty)
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(0), // 패딩 제거
                                    height: 100, // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(0), // 패딩 제거
                                      child: Center(
                                        child: Text(
                                          '등록된 리마인더가 없습니다',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            letterSpacing: -0.4,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (_getActiveReminders().isEmpty)
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(0), // 패딩 제거
                                    height: 100, // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(0), // 패딩 제거
                                      child: Center(
                                        child: Text(
                                          '활성화된 리마인더가 없습니다',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            letterSpacing: -0.4,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.symmetric(vertical: 15), // 상하단 여백 15픽셀
                                    constraints: const BoxConstraints(minHeight: 100), // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _getActiveReminders().length,
                                      padding: EdgeInsets.zero, // 패딩 제거
                                      separatorBuilder: (context, index) => const SizedBox(height: 5), // 아이템 간 간격 5픽셀
                                      itemBuilder: (context, index) {
                                        final reminder = _getActiveReminders()[index];
                                        // 리마인더 ID와 체크 상태 가져오기
                                        final reminderId = reminder.reminderId?.toString() ?? '';
                                        final isChecked = _checkedState[reminderId] ?? false;
                                        
                                        return Container(
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(horizontal: 5),
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: isChecked,
                                                onChanged: (value) {
                                                  _handleCheckboxChange(reminder, value);
                                                },
                                                activeColor: const Color(0xFF0062FF),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    context.push('/edit-reminder/${reminder.reminderId}', extra: reminder).then((value) {
                                                      // 편집 페이지에서 돌아오면 항상 데이터 새로고침
                                                      _loadData();
                                                    });
                                                  },
                                                  onLongPress: () {
                                                    _showReminderOptionsDialog(reminder);
                                                  },
                                                  child: Text(
                                                    reminder.reminder_title,
                                                    style: TextStyle(
                                                      fontFamily: 'Pretendard',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w400,
                                                      height: 1.4,
                                                      letterSpacing: -0.4,
                                                      color: isChecked 
                                                          ? const Color(0xFF767676)
                                                          : Colors.black,
                                                      decoration: isChecked 
                                                          ? TextDecoration.lineThrough 
                                                          : TextDecoration.none,
                                                      decorationColor: const Color(0xFF767676),
                                                      decorationThickness: 2,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                
                                // 일정 섹션
                                const SizedBox(height: 15), // 상단 여백 축소
                                const Text(
                                  '일정',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600, // SemiBold
                                    height: 1.4,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF0062FF),
                                  ),
                                ),
                                const SizedBox(height: 8), // 여백 축소
                                
                                if (_schedules.isEmpty)
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(5),
                                    height: 100, // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Center(
                                        child: Text(
                                          '등록된 일정이 없습니다',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            letterSpacing: -0.4,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (_getSchedulesForSelectedDate().isEmpty)
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(0), // 패딩 제거
                                    height: 100, // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(0), // 패딩 제거
                                      child: Center(
                                        child: Text(
                                          '선택된 날짜의 일정이 없습니다',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            letterSpacing: -0.4,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.symmetric(vertical: 15), // 상하단 여백 15픽셀
                                    constraints: const BoxConstraints(minHeight: 100), // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _getSchedulesForSelectedDate().length,
                                      padding: EdgeInsets.zero, // 패딩 제거
                                      separatorBuilder: (context, index) => const SizedBox(height: 5), // 아이템 간 간격 5픽셀
                                      itemBuilder: (context, index) {
                                        final schedule = _getSchedulesForSelectedDate()[index];
                                        // 우선순위에 따른 색상 설정
                                        Color priorityColor;
                                        switch(schedule.priority) {
                                          case 1:
                                            priorityColor = const Color(0xFFFF9E99); // 변경된 높음 (빨강)
                                            break;
                                          case 2:
                                            priorityColor = const Color(0xFFFFEE8C); // 변경된 중간 (노랑)
                                            break;
                                          case 3:
                                            priorityColor = const Color(0xFFADEBB3); // 변경된 낮음 (초록)
                                            break;
                                          default:
                                            priorityColor = const Color(0xFFB8B4A3); // 변경된 없음 (베이지)
                                        }
                                        
                                        final startTimeStr = DateFormat('HH:mm').format(schedule.startTime);
                                        final endTimeStr = DateFormat('HH:mm').format(schedule.endTime);
                                        
                                        return Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey.shade100),
                                            ),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              context.push('/edit-schedule/${schedule.scheduleId}', extra: schedule).then((value) {
                                                // 일정 편집 페이지에서 돌아오면 항상 데이터 새로고침
                                                _loadData();
                                              });
                                            },
                                            onLongPress: () {
                                              _showScheduleOptionsDialog(schedule);
                                            },
                                            behavior: HitTestBehavior.opaque, // 전체 영역을 터치 가능하도록 설정
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // 왼쪽: 시간 정보
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      startTimeStr,
                                                      style: const TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w400,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '~$endTimeStr',
                                                      style: const TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w400,
                                                        color: Color(0xFF767676),
                                                      ),
                                  ),
                              ],
                            ),
                                                const SizedBox(width: 8),
                                                // 우선순위 색상 표시
                                                Container(
                                                  width: 4,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: priorityColor,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // 오른쪽: 제목과 메모
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        schedule.title,
                                                        style: const TextStyle(
                                                          fontFamily: 'Pretendard',
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w400,
                                                          color: Colors.black,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                      if (schedule.description != null && schedule.description!.isNotEmpty)
                                                        Text(
                                                          schedule.description!,
                                                          style: const TextStyle(
                                                            fontFamily: 'Pretendard',
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w400,
                                                            color: Color(0xFF767676),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                // 모임일정 섹션 추가
                                const SizedBox(height: 15),
                                const Text(
                                  '모임일정',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600, // SemiBold
                                    height: 1.4,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF0062FF),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                if (_groupSchedules.isEmpty)
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(5),
                                    height: 100, // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Center(
                                        child: Text(
                                          '등록된 모임일정이 없습니다',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            letterSpacing: -0.4,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (_getGroupSchedulesForSelectedDate().isEmpty)
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.all(0), // 패딩 제거
                                    height: 100, // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(0), // 패딩 제거
                                      child: Center(
                                        child: Text(
                                          '선택된 날짜의 모임일정이 없습니다',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            letterSpacing: -0.4,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.9, // 너비 조정
                                    padding: const EdgeInsets.symmetric(vertical: 15), // 상하단 여백 15픽셀
                                    constraints: const BoxConstraints(minHeight: 100), // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _getGroupSchedulesForSelectedDate().length,
                                      padding: EdgeInsets.zero, // 패딩 제거
                                      separatorBuilder: (context, index) => const SizedBox(height: 5), // 아이템 간 간격 5픽셀
                                      itemBuilder: (context, index) {
                                        final schedule = _getGroupSchedulesForSelectedDate()[index];
                                        
                                        final startTimeStr = DateFormat('HH:mm').format(schedule.startTime);
                                        final endTimeStr = DateFormat('HH:mm').format(schedule.endTime);
                                        
                                        return Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey.shade100),
                                            ),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              context.push('/edit-schedule/${schedule.scheduleId}', extra: schedule).then((value) {
                                                _loadData();
                                              });
                                            },
                                            behavior: HitTestBehavior.opaque, // 전체 영역을 터치 가능하도록 설정
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // 왼쪽: 시간 정보
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      startTimeStr,
                                                      style: const TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w400,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '~$endTimeStr',
                                                      style: const TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w400,
                                                        color: Color(0xFF767676),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 8),
                                                // 모임일정 표시 아이콘
                                                Container(
                                                  width: 4,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0062FF), // 모임일정은 파란색으로 통일
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // 오른쪽: 제목과 메모
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.group,
                                                            size: 16,
                                                            color: Color(0xFF0062FF),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              schedule.title,
                                                              style: const TextStyle(
                                                                fontFamily: 'Pretendard',
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w400,
                                                                color: Colors.black,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (schedule.description != null && schedule.description!.isNotEmpty)
                                                        Text(
                                                          schedule.description!,
                                                          style: const TextStyle(
                                                            fontFamily: 'Pretendard',
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w400,
                                                            color: Color(0xFF767676),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),                               
                                
                                // 추가 공간
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: AddButton(
        items: [
          AddButtonItem(
            label: '사진으로 일정 추가',
            iconPath: 'assets/images/image.png',
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              
              if (image != null) {
                context.push('/schedule-from-image', extra: File(image.path));
              }
            },
          ),
          AddButtonItem(
            label: '리마인더 추가',
            iconPath: 'assets/images/reminder.png',
            onPressed: () {
              context.push('/add-reminder').then((value) {
                // 리마인더 추가 페이지에서 돌아오면 항상 데이터 새로고침
                _loadData();
              });
            },
          ),
          AddButtonItem(
            label: '일정 추가',
            iconPath: 'assets/images/schedule.png',
            onPressed: () {
              context.push('/add-schedule').then((value) {
                // 일정 추가 페이지에서 돌아오면 항상 데이터 새로고침
                _loadData();
              });
            },
          ),
        ],
        onItemSelected: () {
          // ... existing code ...
        },
      ),
    );
  }

  // 리마인더 삭제 메서드
  void _showReminderOptionsDialog(Reminder reminder) {
    // 반복 일정인지 확인
    bool isRecurrent = reminder.recurrenceDays.isNotEmpty && 
                      reminder.recurrenceDays != "0,0,0,0,0,0,0" && 
                      reminder.recurrenceDays.contains("1");
                      
    if (isRecurrent) {
      // 반복 일정인 경우 - 반복 리마인더 삭제 다이얼로그를 직접 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '반복 리마인더 삭제',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '이 반복 리마인더를 어떻게 삭제하시겠습니까?',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // 이 리마인더만 삭제 버튼
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  // 직접 API 호출하여 삭제 처리 - RecurrenceDeleteMode.SINGLE
                  _deleteRecurringReminder(reminder, RecurrenceDeleteMode.SINGLE);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '이 리마인더만 삭제',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // 전체 시리즈 삭제 버튼
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  // 직접 API 호출하여 삭제 처리 - RecurrenceDeleteMode.ALL
                  _deleteRecurringReminder(reminder, RecurrenceDeleteMode.ALL);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '전체 시리즈 삭제',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // 일반 리마인더 - 확인 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('리마인더 삭제'),
          content: const Text('이 리마인더를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteReminder(reminder);
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }
  
  // 통합된 리마인더 삭제 메서드 (반복 리마인더용)
  Future<void> _deleteRecurringReminder(Reminder reminder, RecurrenceDeleteMode mode) async {
    try {
      final reminderId = reminder.reminderId;
      if (reminderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리마인더 ID가 없습니다')),
        );
        return;
      }
      
      String successMessage = '';
      switch (mode) {
        case RecurrenceDeleteMode.SINGLE:
          successMessage = '해당 리마인더만 삭제되었습니다';
          break;
        case RecurrenceDeleteMode.ALL:
          successMessage = '전체 반복 리마인더가 삭제되었습니다';
          break;
        default:
          // FUTURE 또는 기타 케이스 (사용하지 않음)
          successMessage = '리마인더가 삭제되었습니다';
          break;
      }
      
      await _reminderService.deleteRecurringReminder(reminderId.toString(), mode);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      
      // 리마인더 다시 로드
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리마인더 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
  
  // 통합된 리마인더 삭제 메서드 (일반 리마인더용)
  Future<void> _deleteReminder(Reminder reminder) async {
    try {
      final reminderId = reminder.reminderId;
      if (reminderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리마인더 ID가 없습니다')),
        );
        return;
      }
      
      await _reminderService.deleteReminder(reminderId.toString());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리마인더가 삭제되었습니다')),
      );
      
      // 리마인더 다시 로드
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리마인더 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
  
  // 일정 삭제 확인 다이얼로그를 표시합니다.
  Future<void> _showDeleteConfirmationDialog(Schedule schedule) async {
    // schedule.id가 null인지 확인
    if (schedule.id == null) {
      _showSnackBar('일정 ID가 없습니다');
      return;
    }
    
    // 반복 일정인지 확인
    bool isRecurring = schedule.recurrenceDays != null && 
                      schedule.recurrenceDays!.isNotEmpty &&
                      schedule.recurrenceDays != '0,0,0,0,0,0,0';
    
    if (!isRecurring) {
      // 반복 아닌 일정 - 바로 삭제 확인
      bool confirmed = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('일정 삭제'),
            content: const Text('이 일정을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('삭제'),
              ),
            ],
          );
        },
      ) ?? false;
      
      if (confirmed) {
        // 일반 일정 삭제
        try {
          await _scheduleService.deleteSchedule(schedule.id!);
          _loadData();
          _showSnackBar('일정이 삭제되었습니다.');
        } catch (e) {
          _showSnackBar('일정 삭제 중 오류가 발생했습니다: $e');
        }
      }
      return;
    }
    
    // 반복 일정 - 삭제 옵션 선택 다이얼로그
    final result = await showDialog(
      context: context,
      builder: (context) => RecurrenceDeleteDialog(isRecurring: isRecurring),
    );
    
    if (result == null) {
      // 취소됨
      return;
    }
    
    try {
      // 현재 선택된 날짜를 발생일자로 사용 
      DateTime? occurrenceDate;
      String option = 'ALL';
      
      if (result is bool && result == true) {
        // 일회성 일정이거나 단순 확인에서 '삭제' 선택한 경우
        option = 'ALL';
      } else if (result is RecurrenceDeleteMode) {
        // 반복 일정의 경우 선택한 모드에 따라 처리
        switch (result) {
          case RecurrenceDeleteMode.SINGLE:
            option = 'SINGLE';
            occurrenceDate = _selectedDate;
            break;
          case RecurrenceDeleteMode.FUTURE:
            option = 'FUTURE';
            occurrenceDate = _selectedDate;
            break;
          case RecurrenceDeleteMode.ALL:
            option = 'ALL';
            break;
        }
      }
      
      await _scheduleService.deleteSchedule(
        schedule.id!, 
        option: option,
        occurrenceDate: occurrenceDate,
      );
      
      String successMessage = '일정이 삭제되었습니다';
      if (isRecurring && result is RecurrenceDeleteMode) {
        switch (result) {
          case RecurrenceDeleteMode.SINGLE:
            successMessage = '해당 일정만 삭제되었습니다';
            break;
          case RecurrenceDeleteMode.FUTURE:
            successMessage = '이 일정 및 향후 일정이 삭제되었습니다';
            break;
          case RecurrenceDeleteMode.ALL:
            successMessage = '전체 반복 일정이 삭제되었습니다';
            break;
        }
      }
      
      _loadData();
      _showSnackBar(successMessage);
    } catch (e) {
      _showSnackBar('일정 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 스낵바를 표시합니다.
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  
  // 일정 미루기 대화상자
  void _showPostponeDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '미루기 옵션',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 내일
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _postponeSchedule(schedule, '1일후', null);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: const Text(
                  '내일',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 일주일 후
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _postponeSchedule(schedule, '7일후', null);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: const Text(
                  '일주일 후',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 직접 설정
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showDateTimePicker(schedule);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  '직접 설정',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 날짜/시간 선택기
  void _showDateTimePicker(Schedule schedule) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null && mounted) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null && mounted) {
        final DateTime customDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        
        _postponeSchedule(schedule, '직접설정', customDateTime);
      }
    }
  }

  // 일정 미루기 API 호출
  Future<void> _postponeSchedule(Schedule schedule, String mode, DateTime? customDateTime) async {
    try {
      final scheduleId = schedule.scheduleId;
      if (scheduleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 ID가 없습니다')),
        );
        return;
      }

      // 백엔드 API 호출로 미루기 처리
      await _scheduleService.postponeSchedule(
        scheduleId,
        mode,
        custom: customDateTime,
        occurrenceDate: schedule.startTime, // 해당 일정의 시작 시간을 발생일로 설정
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정이 성공적으로 미뤄졌습니다')),
        );
        _loadData(); // 데이터 새로고침
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 미루기 실패: $e')),
        );
      }
    }
  }

  // 일정 옵션 다이얼로그 (삭제, 미루기 포함)
  void _showScheduleOptionsDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '일정 옵션',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 미루기 버튼
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showPostponeDialog(schedule);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: const Text(
                  '미루기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 삭제 버튼
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(schedule);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  '삭제',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddSchedule() {
    context.go('/add-schedule');
  }

  void _navigateToAddReminder() {
    context.go('/add-reminder');
  }

  void _navigateToEditSchedule(Schedule schedule) {
    context.go('/edit-schedule/${schedule.scheduleId}', extra: schedule);
  }

  void _navigateToEditReminder(Reminder reminder) {
    context.go('/edit-reminder/${reminder.reminderId}', extra: reminder);
  }
}
