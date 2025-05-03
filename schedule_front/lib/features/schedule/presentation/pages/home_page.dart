import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';
import 'package:schedule/features/schedule/presentation/widgets/recurrence_delete_dialog.dart';
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
      
      // 백엔드 응답에서 업데이트된 리마인더 정보 받기
      final updatedReminder = Reminder.fromJson(jsonDecode(response.body));
      
      // 성공 시에만 전체 목록 다시 로드 (백엔드 응답의 isActive 값을 확인)
      // _loadData();
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
      // 비활성화된 리마인더는 포함하지 않음 - 이 조건 변경
      // if (reminder.isActive != true) continue;
      
      final reminderId = reminder.reminderId?.toString() ?? '';
      final isChecked = _checkedState[reminderId] ?? false;
      
      // 체크된 리마인더 처리
      if (isChecked) {
        // 체크 시점 날짜 확인
        if (reminder.checkedDate != null) {
          try {
            // 체크된 날짜만 추출 (시간 제외)
            final checkedDay = DateTime(
              reminder.checkedDate!.year,
              reminder.checkedDate!.month,
              reminder.checkedDate!.day,
      );
      
            // 체크 날짜가 어제 이전이면 (= 체크 후 00시가 지났으면) 목록에서 제외
            if (checkedDay.isBefore(todayDate)) {
              continue; // 다음 항목으로
            }
            
            // 체크 날짜가 오늘이면 (= 당일에 체크했으면) 목록에 포함 (절취선으로 표시)
            // 별도 처리 필요 없이 그대로 진행
          } catch (e) {
            print('날짜 파싱 오류: $e');
          }
        }
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
          
          // 그대로 리마인더 추가 (startTime/endTime 제거됨)
          filteredReminders.add(reminder);
        }
      } else {
        // 일반 리마인더의 경우 그냥 추가
        if (!_checkedState.containsKey(reminderId)) {
          _checkedState[reminderId] = false;
        }
        filteredReminders.add(reminder);
      }
    }
    
    // 기본 id순으로 정렬 (startTime이 제거됨)
    filteredReminders.sort((a, b) => (a.reminderId ?? '').compareTo(b.reminderId ?? ''));
    
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
          // yyyy-MM-dd 형식으로 날짜 변환 (월과 일이 한 자리인 경우 앞에 0 추가)
          final year = selectedDateOnly.year.toString();
          final month = selectedDateOnly.month.toString().padLeft(2, '0');
          final day = selectedDateOnly.day.toString().padLeft(2, '0');
          final selectedDateStr = '$year-$month-$day';
          
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
    
    // 시작 시간 순으로 정렬
    filteredSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    
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
      // 반복 일정인 경우 - 단순화된 옵션 제공
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
              
              // 리마인더만 삭제 버튼
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _deleteCurrentReminderOccurrence(reminder);
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
                  _deleteEntireReminder(reminder.reminderId.toString());
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
        ),
      );
    } else {
      // 일반 리마인더
      _deleteReminder(reminder);
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final bool isRecurring = reminder.recurrenceDays.isNotEmpty &&
                            reminder.recurrenceDays != "0,0,0,0,0,0,0";
    
    if (!isRecurring) {
      // 단순 확인 다이얼로그
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('리마인더 삭제'),
          content: const Text('이 리마인더를 삭제하시겠습니까?'),
          actions: [
                TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
                ),
                TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (result != true) {
        // 취소됨
        return;
      }
      
      try {
        final reminderId = reminder.reminderId;
        if (reminderId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리마인더 ID가 없습니다')),
          );
          return;
  }
  
        // 리마인더 삭제
        await _deleteEntireReminder(reminderId.toString());
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
    } else {
      // 반복 리마인더의 경우 RecurrenceDeleteDialog 사용
      final result = await showDialog(
        context: context,
        builder: (context) => RecurrenceDeleteDialog(isRecurring: true),
      );
      
      if (result == null) {
        // 취소됨
        return;
      }
      
    try {
      final reminderId = reminder.reminderId;
      if (reminderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리마인더 ID가 없습니다')),
        );
        return;
      }
      
        // 반복 리마인더 삭제 옵션에 따라 처리
        switch (result) {
          case RecurrenceDeleteMode.single:
            await _deleteCurrentReminderOccurrence(reminder);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('해당 리마인더만 삭제되었습니다')),
            );
            break;
          case RecurrenceDeleteMode.thisAndFuture:
            await _deleteThisAndFutureReminderOccurrences(reminder);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이 리마인더 및 향후 리마인더가 삭제되었습니다')),
            );
            break;
          case RecurrenceDeleteMode.allSeries:
            await _deleteEntireReminder(reminderId.toString());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('전체 반복 리마인더가 삭제되었습니다')),
            );
            break;
        }
        
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
  }
  
  // 현재 리마인더만 삭제 (특정 날짜 제외)
  Future<void> _deleteCurrentReminderOccurrence(Reminder reminder) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');
      
      final idToken = await user.getIdToken(true);
    final reminderId = reminder.reminderId!;
      
    // 현재 날짜
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
      
    // 반복 리마인더에서 특정 날짜 제외하는 API 호출
    final excludeResponse = await http.post(
      Uri.parse('${ApiConfig.remindersEndpoint}/$reminderId/exclude-occurrence'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
        'excludeDate': todayDate.toIso8601String(),
        }),
      );
      
    if (excludeResponse.statusCode != 200) {
      throw Exception('반복 리마인더에서 날짜 제외 실패: ${excludeResponse.statusCode}');
    }
  }
  
  // 현재 및 향후 리마인더 삭제 (종료일 변경)
  Future<void> _deleteThisAndFutureReminderOccurrences(Reminder reminder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');
    
    final idToken = await user.getIdToken(true);
    final reminderId = reminder.reminderId!;
    
    // 현재 날짜
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // 원본 리마인더의 시작일을 가져옴
    final originalStartDate = reminder.recurrenceStartDate;
    
    // 원본 리마인더를 삭제하기 전에 이전 리마인더만 따로 저장하는 리마인더를 만들기
    if (originalStartDate != null && originalStartDate.isBefore(todayDate)) {
      // 복사본 생성 - 종료일을 현재 날짜 전날로 변경 (이전 리마인더만 유지)
      final previousDay = todayDate.subtract(const Duration(days: 1));
      
      // 원본 리마인더의 복사본 생성 - 이전 리마인더만 유지하기 위한 목적
      final previousReminder = Reminder(
        reminder_title: reminder.reminder_title,
        recurrenceDays: reminder.recurrenceDays,
        reminderMinutesBefore: reminder.reminderMinutesBefore,
        isActive: reminder.isActive,
        date: reminder.date,
        checkedDate: null,
        recurrenceStartDate: originalStartDate,
        recurrenceEndDate: previousDay, // 종료일을 현재 날짜 전날로 변경
        excludedDates: reminder.excludedDates,
      );
      
      // 이전 리마인더 생성 API 호출
      await _reminderService.saveReminder(previousReminder);
    }
    
    // 원본 리마인더 삭제
    await _deleteEntireReminder(reminderId.toString());
  }

  // 리마인더 전체 삭제 메서드
  Future<void> _deleteEntireReminder(String reminderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다');
    
    final idToken = await user.getIdToken(true);
    
    final response = await http.delete(
      Uri.parse('${ApiConfig.remindersEndpoint}/$reminderId'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('리마인더 삭제 실패: ${response.statusCode}');
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

  // 일정 삭제 메서드 추가
  Future<void> _deleteSchedule(Schedule schedule) async {
    final bool isRecurring = schedule.recurrenceDays != null && 
                            schedule.recurrenceDays!.isNotEmpty &&
                            schedule.recurrenceDays != "0,0,0,0,0,0,0";
    
    // 삭제 다이얼로그 표시
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRecurring ? '반복 일정 삭제' : '일정 삭제'),
        content: Text(isRecurring ? 
          '이 반복 일정을 삭제하시겠습니까?' : 
          '이 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (result != true) {
      // 취소됨
      return;
    }
    
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
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.schedulesEndpoint}/$scheduleId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정이 삭제되었습니다')),
        );
        _loadData(); // 데이터 새로고침
      } else {
        throw Exception('일정 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 삭제 실패: $e')),
        );
      }
    }
  }

  // 현재 리마인더 날짜만 제외 (반복 일정에서 특정 날짜만 제외)
  Future<void> _excludeCurrentReminderDate(Reminder reminder) async {
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
}
