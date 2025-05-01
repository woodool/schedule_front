import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/reminder.dart';
import '../../domain/models/priority.dart';
import '../../domain/services/schedule_service.dart';
import '../../domain/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';
import 'edit_reminder_page.dart';
import 'edit_schedule_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScheduleService _scheduleService = ScheduleService();
  final ReminderService _reminderService = ReminderService();
  List<Schedule> _schedules = [];
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
                  // String 형태의 생성일자를 DateTime으로 변환
                  final createdDate = DateTime.parse(userData['createdAt']);
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

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _reminders = reminders;
        _isLoading = false;
        
        // 체크박스 상태 초기화
        for (var reminder in _reminders) {
          if (reminder.reminderId != null) {
            _checkedState[reminder.reminderId!.toString()] = reminder.isActive == false;
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
    
    // 즉시 UI 업데이트
    setState(() {
      _checkedState[reminderId] = value ?? false;
      
      // 체크된 항목은 목록 하단으로 이동하도록 정렬
      _getActiveReminders();
    });
    
    try {
      // 현재 날짜/시간 정보
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayString = today.toIso8601String();
      
      // 리마인더 객체 복사 및 isActive 업데이트
      Reminder updatedReminder = reminder.copyWith(
        isActive: !(value ?? false), // value true면 isActive false로
        date: todayString, // 항상 오늘 날짜로 설정
      );
      
      // 백엔드 업데이트 (백그라운드에서 처리)
      _reminderService.updateReminder(updatedReminder).catchError((e) {
        print('리마인더 업데이트 실패: $e');
        // 실패 시 체크 상태 원복
        if (mounted) {
          setState(() {
            _checkedState[reminderId] = !(value ?? false);
          });
        }
        return null;
      });
    } catch (e) {
      print('리마인더 업데이트 실패: $e');
      // 실패 시 체크 상태 원복
      if (mounted) {
        setState(() {
          _checkedState[reminderId] = !(value ?? false);
        });
      }
    }
  }
  
  // 리마인더 리스트를 가져오는 메서드를 완전히 변경
  // 날짜별 필터링이 아닌 통합 리스트로 변경
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
      // 비활성화된 리마인더는 건너뜀
      if (reminder.isActive != true) continue;
      
      final reminderId = reminder.reminderId?.toString() ?? '';
      final isChecked = _checkedState[reminderId] ?? false;
      
      // 체크된 리마인더가 하루가 지났으면 표시하지 않음
      final reminderDate = DateTime(
        reminder.startTime.year,
        reminder.startTime.month,
        reminder.startTime.day,
      );
      
      // 체크된 리마인더이고 오늘보다 이전 날짜의 리마인더인 경우 제외
      if (isChecked && reminderDate.isBefore(todayDate)) {
        continue;
      }
      
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
          // 체크박스 상태 확인
          if (!_checkedState.containsKey(reminderId)) {
            _checkedState[reminderId] = false;
          }
          
          // 오늘 날짜로 조정된 리마인더 생성
          final adjustedReminder = reminder.copyWith(
            startTime: DateTime(
              todayDate.year,
              todayDate.month,
              todayDate.day,
              reminder.startTime.hour,
              reminder.startTime.minute,
            ),
            endTime: DateTime(
              todayDate.year,
              todayDate.month,
              todayDate.day,
              reminder.endTime.hour,
              reminder.endTime.minute,
            ),
          );
          
          filteredReminders.add(adjustedReminder);
        }
      } else {
        // 일반 리마인더의 경우 그냥 추가
        if (!_checkedState.containsKey(reminderId)) {
          _checkedState[reminderId] = false;
        }
        filteredReminders.add(reminder);
      }
    }
    
    // 알림 시간순으로 정렬
    filteredReminders.sort((a, b) => a.startTime.compareTo(b.startTime));
    
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
    
    for (var schedule in _schedules) {
      // 1. 일반 일정: 시작 날짜가 선택한 날짜와 일치하는 경우
      final scheduleDate = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      
      if (scheduleDate.isAtSameMomentAs(selectedDateOnly)) {
        filteredSchedules.add(schedule);
        continue; // 이미 추가된 일정은 반복 체크 무시
      }
      
      // 2. 반복 일정: recurrenceDays 설정이 있는 경우
      if (schedule.recurrenceDays != null && schedule.recurrenceDays!.isNotEmpty) {
        // 요일 비교를 위해 선택된, 날짜의 요일 가져오기 (1: 월요일, 7: 일요일)
        final selectedWeekday = _selectedDate.weekday;
        
        // 반복 요일 목록을 parsing
        final List<String> recurrenceDaysList = schedule.recurrenceDays!.split(',');
        
        // 반복 기간 체크 (시작일/종료일이 설정된 경우)
        bool isWithinRecurrencePeriod = true;
        if (schedule.recurrenceStartDate != null) {
          // 선택된 날짜가 반복 시작일보다 이전이면 표시하지 않음
          final startDateOnly = DateTime(
            schedule.recurrenceStartDate!.year,
            schedule.recurrenceStartDate!.month,
            schedule.recurrenceStartDate!.day,
          );
          if (selectedDateOnly.isBefore(startDateOnly)) {
            isWithinRecurrencePeriod = false;
          }
        }
        if (isWithinRecurrencePeriod && schedule.recurrenceEndDate != null) {
          // 선택된 날짜가 반복 종료일보다 이후면 표시하지 않음
          final endDateOnly = DateTime(
            schedule.recurrenceEndDate!.year,
            schedule.recurrenceEndDate!.month,
            schedule.recurrenceEndDate!.day,
          );
          if (selectedDateOnly.isAfter(endDateOnly)) {
            isWithinRecurrencePeriod = false;
          }
        }
        
        // 제외된 날짜 확인 (excludedDates 필드가 있는 경우)
        bool isExcludedDate = false;
        if (schedule.excludedDates != null && schedule.excludedDates!.isNotEmpty) {
          final selectedDateStr = '${selectedDateOnly.year}-'
              '${selectedDateOnly.month.toString().padLeft(2, '0')}-'
              '${selectedDateOnly.day.toString().padLeft(2, '0')}';
          
          final excludedDatesList = schedule.excludedDates!.split(',');
          isExcludedDate = excludedDatesList.contains(selectedDateStr);
        }
        
        // 선택한 날짜의 요일이 반복 요일에 포함되는지 확인하고, 반복 기간 내에 있고, 제외 날짜가 아닌지 확인
        if (recurrenceDaysList.contains(selectedWeekday.toString()) && 
            isWithinRecurrencePeriod && 
            !isExcludedDate) {
          // 일정 복사본 생성 (시작/종료 시간을 선택한 날짜로 조정)
          Schedule recurrentSchedule = schedule.copyWith(
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
          );
          
          filteredSchedules.add(recurrentSchedule);
        }
      }
    }
    
    return filteredSchedules;
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
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    constraints: const BoxConstraints(minHeight: 100), // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _getActiveReminders().length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 5),
                                      itemBuilder: (context, index) {
                                        final reminder = _getActiveReminders()[index];
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
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => EditReminderPage(reminder: reminder),
                                                      ),
                                                    ).then((value) {
                                                      if (value == true) {
                                                        _loadData();
                                                      }
                                                    });
                                                  },
                                                  onLongPress: () {
                                                    _showReminderOptionsDialog(reminder);
                                                  },
                                                  child: Text(
                                                    reminder.title,
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
                                    padding: const EdgeInsets.all(5),
                                    constraints: const BoxConstraints(minHeight: 100), // 최소 높이 설정
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _getSchedulesForSelectedDate().length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 5),
                                      itemBuilder: (context, index) {
                                        final schedule = _getSchedulesForSelectedDate()[index];
                                        // 우선순위에 따른 색상 설정
                                        Color priorityColor;
                                        switch(schedule.priority) {
                                          case 1:
                                            priorityColor = const Color(0xFFEC7F7F); // 높음 (빨강)
                                            break;
                                          case 2:
                                            priorityColor = const Color(0xFFFFF0A3); // 중간 (노랑)
                                            break;
                                          case 3:
                                            priorityColor = const Color(0xFFB4E07B); // 낮음 (초록)
                                            break;
                                          default:
                                            priorityColor = const Color(0xFFA5A5A5); // 없음 (회색)
                                        }
                                        
                                        final startTimeStr = DateFormat('HH:mm').format(schedule.startTime);
                                        final endTimeStr = DateFormat('HH:mm').format(schedule.endTime);
                                        
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey.shade100),
                                            ),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditSchedulePage(schedule: schedule),
                                                ),
                                              ).then((value) {
                                                if (value == true) {
                                                  _loadData();
                                                }
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
            onPressed: () {
              // TODO: 사진으로 일정 추가 기능 구현
            },
          ),
          AddButtonItem(
            label: '리마인더 추가',
            iconPath: 'assets/images/reminder.png',
            onPressed: () {
              Navigator.pushNamed(context, '/add_reminder').then((value) {
                if (value == true) _loadData();
              });
            },
          ),
          AddButtonItem(
            label: '일정 추가',
            iconPath: 'assets/images/schedule.png',
            onPressed: () {
              Navigator.pushNamed(context, '/add_schedule').then((value) {
                if (value == true) _loadData();
              });
            },
          ),
        ],
      ),
    );
  }

  // 리마인더 옵션 다이얼로그 수정
  void _showReminderOptionsDialog(Reminder reminder) {
    // 반복 일정인지 확인
    bool isRecurrent = reminder.recurrenceDays.isNotEmpty && 
                      reminder.recurrenceDays != "0,0,0,0,0,0,0" && 
                      reminder.recurrenceDays.contains("1");
                      
    if (isRecurrent) {
      // 반복 일정인 경우 - 현재 인스턴스만 삭제 또는 전체 삭제 옵션 제공
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
              // 현재 리마인더만 삭제 버튼
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _deleteCurrentReminderOccurrence(reminder);
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
                    '현재 리마인더만 삭제',
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
              // 전체 반복 리마인더 삭제 버튼
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _deleteReminder(reminder);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    '전체 반복 리마인더 삭제',
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
    } else {
      // 일반 리마인더인 경우 - 그냥 삭제만 물어봄
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '리마인더 삭제',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            '이 리마인더를 삭제하시겠습니까?',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteReminder(reminder);
                  },
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
  
  // 현재 리마인더 인스턴스만 제외 (반복 일정에서 특정 날짜만 제외)
  Future<void> _deleteCurrentReminderOccurrence(Reminder reminder) async {
    try {
      final reminderId = reminder.reminderId;
      if (reminderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리마인더 ID가 없습니다')),
        );
        return;
      }
      
      // 선택된 날짜 정보
      final selectedDateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');
      
      final idToken = await user.getIdToken(true);
      
      // 현재 인스턴스만 삭제하는 API 호출
      final String url = '${ApiConfig.remindersEndpoint}/$reminderId/exclude-occurrence';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'excludeDate': selectedDateOnly.toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('현재 리마인더만 삭제되었습니다')),
          );
          _loadData();
        }
      } else {
        throw Exception('리마인더 인스턴스 삭제 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리마인더 인스턴스 삭제 실패: $e')),
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
                // 반복 일정인지 확인 (recurrenceDays 값이 있으면 반복 일정)
                if (schedule.recurrenceDays != null && schedule.recurrenceDays!.isNotEmpty) {
                  _showRecurrenceDeleteDialog(schedule);
                } else {
                  _deleteSchedule(schedule);
                }
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

  // 미루기 다이얼로그
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

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

      final idToken = await user.getIdToken(true);

      // API 요청 본문 작성
      final requestBody = {
        'mode': mode,
        if (customDateTime != null) 'customReminderTime': customDateTime.toIso8601String()
      };

      final String url = '${ApiConfig.schedulesEndpoint}/$scheduleId/postpone';
      print('미루기 요청 URL: $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 성공적으로 미뤄졌습니다')),
          );
          _loadData(); // 데이터 새로고침
        }
      } else {
        throw Exception('일정 미루기 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 미루기 실패: $e')),
        );
      }
    }
  }

  // 리마인더 삭제
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리마인더가 삭제되었습니다')),
        );
        _loadData(); // 데이터 새로고침
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리마인더 삭제 실패: $e')),
        );
      }
    }
  }

  // 일정 삭제
  Future<void> _deleteSchedule(Schedule schedule) async {
    try {
      final scheduleId = schedule.scheduleId;
      if (scheduleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 ID가 없습니다')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');

      final idToken = await user.getIdToken(true);

      final String url = '${ApiConfig.schedulesEndpoint}/$scheduleId';
      print('삭제 요청 URL: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 삭제되었습니다')),
          );
          _loadData(); // 데이터 새로고침
        }
      } else {
        throw Exception('일정 삭제 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 삭제 실패: $e')),
        );
      }
    }
  }

  // 반복 일정 삭제 다이얼로그
  void _showRecurrenceDeleteDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '반복 일정 삭제',
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
                '이 반복 일정을 어떻게 삭제하시겠습니까?',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // 현재 일정만 삭제 버튼
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _deleteCurrentOccurrence(schedule);
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
                  '현재 일정만 삭제',
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
            // 전체 반복 일정 삭제 버튼
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _deleteSchedule(schedule);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  '전체 반복 일정 삭제',
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

  // 현재 일정만 삭제 (반복 일정의 특정 인스턴스만 제외)
  Future<void> _deleteCurrentOccurrence(Schedule schedule) async {
    try {
      final scheduleId = schedule.scheduleId;
      if (scheduleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 ID가 없습니다')),
        );
        return;
      }
      
      // 선택된 날짜 정보가 필요
      final selectedDateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');
      
      final idToken = await user.getIdToken(true);
      
      // 현재 인스턴스만 삭제하는 API 호출
      final String url = '${ApiConfig.schedulesEndpoint}/$scheduleId/exclude-occurrence';
      print('현재 인스턴스 제외 요청 URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'excludeDate': selectedDateOnly.toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('현재 일정만 삭제되었습니다')),
          );
          _loadData(); // 데이터 새로고침
        }
      } else {
        // 특정 인스턴스 제외 API가 구현되지 않았거나 오류가 발생한 경우
        // 프론트엔드에서 임시 대응: 기존 반복 설정에서 해당 요일만 제외
        if (response.statusCode == 404) {
          await _handleOccurrenceExclusionLocally(schedule, selectedDateOnly);
        } else {
          throw Exception('일정 인스턴스 삭제 실패: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 인스턴스 삭제 실패: $e')),
        );
      }
    }
  }
  
  // 백엔드 API가 구현되지 않은 경우 프론트엔드에서 임시 구현
  Future<void> _handleOccurrenceExclusionLocally(Schedule schedule, DateTime excludeDate) async {
    try {
      // 해당 인스턴스의 요일 찾기
      final dayOfWeek = excludeDate.weekday.toString(); // 1(월요일) ~ 7(일요일)
      
      if (schedule.recurrenceDays == null || !schedule.recurrenceDays!.contains(dayOfWeek)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 데이터 오류: 해당 요일이 반복 설정에 없습니다')),
        );
        return;
      }
      
      // 임시로 제외된 날짜를 저장할 새로운 필드 사용 (백엔드에 구현 필요)
      // 실제 구현에서는 DB에 excluded_dates 같은 필드를 추가해야 함
      final updatedSchedule = schedule.copyWith(
        // 여기서는 임시로 처리...
      );
      
      // 이 예시에서는 사용자에게 백엔드 구현이 필요하다는 메시지만 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 인스턴스 삭제 기능이 아직 백엔드에 완전히 구현되지 않았습니다. 백엔드 구현이 필요합니다.'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 인스턴스 처리 오류: $e')),
        );
      }
    }
  }
}
