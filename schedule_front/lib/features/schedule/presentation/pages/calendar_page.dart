import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';
import 'package:schedule/features/schedule/domain/models/priority.dart';
import 'package:schedule/features/schedule/domain/models/schedule.dart';
import 'package:schedule/features/schedule/domain/models/Recurrence_option.Dart';
import 'package:schedule/features/schedule/domain/services/schedule_service.dart';
import 'package:schedule/features/schedule/presentation/pages/schedule_search_page.dart';
import 'package:schedule/features/schedule/presentation/widgets/recurrence_delete_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  bool _isLoading = true;
  String? _errorMessage;

  // 일정 데이터 (실제 앱에서는 데이터베이스에서 가져와야 함)
  final Map<DateTime, List<Schedule>> _events = {};
  final ScheduleService _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.week;
    // 초기 로드
    _loadSchedules(forceRefresh: true);
  }

  @override
  void didUpdateWidget(CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 화면이 다시 표시될 때마다 일정 새로고침
    _loadSchedules(forceRefresh: true);
  }

  // 강제로 일정 다시 로드
  void refreshSchedules() {
    print('캘린더 일정 강제 새로고침 요청');
    // 모든 이벤트 데이터를 초기화하고 새로 불러옴
    setState(() {
      _events.clear();
    });
    _loadSchedules(forceRefresh: true);
  }

  Future<void> _loadSchedules({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('일정 불러오기 시작 (강제 새로고침: $forceRefresh)');
      
      // 현재 기준 이전 1년과 이후 1년 범위 설정
      final now = DateTime.now();
      final startRange = DateTime(now.year - 1, now.month, now.day);
      final endRange = DateTime(now.year + 1, now.month, now.day);
      
      List<Schedule> schedules = [];
      try {
        // 범위 내 모든 일정을 백엔드 API로 한 번에 가져옴 (반복 일정 확장은 백엔드에서 처리)
        schedules = await _scheduleService.getSchedulesInRange(startRange, endRange);
        print('범위 서버 API에서 받은 일정 수: ${schedules.length}개');
      } catch (rangeError) {
        // 범위 조회 API 실패시 일반 일정 조회로 대체
        print('범위 일정 조회 실패, 일반 일정 조회로 대체: $rangeError');
        schedules = await _scheduleService.getSchedules();
        print('일반 API에서 받은 일정 수: ${schedules.length}개');
      }
      
      // 날짜별로 일정 분류
      final Map<DateTime, List<Schedule>> events = {};
      
      for (var schedule in schedules) {
          final date = DateTime(
            schedule.startTime.year,
            schedule.startTime.month,
            schedule.startTime.day,
          );
          
          if (!events.containsKey(date)) {
            events[date] = [];
          }
          events[date]!.add(schedule);
      }
      
      setState(() {
        _events.clear();
        _events.addAll(events);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '일정을 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  // 오늘 날짜로 이동
  void _goToToday() {
    setState(() {
      _selectedDay = DateTime.now();
      _focusedDay = DateTime.now();
    });
  }

  // 날짜에 해당하는 일정 이벤트 가져오기
  List<Schedule> _getEventsForDay(DateTime day) {
    // 통합 일정 목록에서 선택된 날짜와 일치하는 일정만 필터링
    List<Schedule> events = [];
    
    // 1. 일반 일정 필터링 (시작 날짜가 선택된 날짜와 일치하는 경우)
    for (var schedule in _events.values.expand((e) => e)) {
      final scheduleDate = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      
      final selectedDate = DateTime(
        day.year,
        day.month,
        day.day,
      );
      
      if (scheduleDate.isAtSameMomentAs(selectedDate)) {
        events.add(schedule);
      } 
      // 2. 반복 일정 필터링
      else if (schedule.recurrenceDays != null && schedule.recurrenceDays!.isNotEmpty) {
        // 새 헬퍼 메서드 사용
        if (_shouldShowRecurringSchedule(schedule, day)) {
          // 반복 일정의 복사본을 생성 (날짜만 변경)
          Schedule recurrentSchedule = Schedule(
            id: schedule.id,
            title: schedule.title,
            description: schedule.description,
            categoryId: schedule.categoryId,
            startTime: DateTime(
              day.year,
              day.month,
              day.day,
              schedule.startTime.hour,
              schedule.startTime.minute,
            ),
            endTime: DateTime(
              day.year,
              day.month,
              day.day,
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
          events.add(recurrentSchedule);
        }
      }
    }
    
    return events.where((schedule) => schedule.displayOnCalendar).toList();
  }

  // 하단 일정바에는 모든 일정을 표시하는 메서드
  List<Schedule> _getAllEventsForDay(DateTime day) {
    // getEventsForDay를 활용하여 반복 일정도 제대로 가져오게 함
    final events = _getEventsForDay(day);
    
    // displayOnCalendar 속성과 관계없이 모든 일정을 반환 
    // 시작 시간 순으로 정렬
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return events;
  }

  // 마커 표시를 위한 일정 필터링 (displayOnCalendar가 true인 일정만 표시)
  List<Schedule> _getEventsForCalendarMarker(DateTime day) {
    // getEventsForDay를 활용하여 반복 일정도 제대로 가져오게 함
    final events = _getEventsForDay(day);
    // displayOnCalendar가 true인 일정만 필터링
    return events.where((schedule) => schedule.displayOnCalendar).toList();
  }

  // 반복 일정의 특정 날짜 표시 여부 결정 (중복 로직 제거를 위한 헬퍼 메서드)
  bool _shouldShowRecurringSchedule(Schedule schedule, DateTime date) {
    if (schedule.recurrenceDays == null || 
        schedule.recurrenceDays!.isEmpty || 
        !schedule.recurrenceDays!.contains("1")) {
      return false;
    }
    
    // 날짜 기준으로만 비교하기 위한 변환
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // 1. 반복 시작일/종료일 체크
    if (schedule.recurrenceStartDate != null) {
      final startDate = DateTime(
        schedule.recurrenceStartDate!.year,
        schedule.recurrenceStartDate!.month,
        schedule.recurrenceStartDate!.day,
      );
      if (dateOnly.isBefore(startDate)) {
        return false;
      }
    }
    
    if (schedule.recurrenceEndDate != null) {
      final endDate = DateTime(
        schedule.recurrenceEndDate!.year,
        schedule.recurrenceEndDate!.month,
        schedule.recurrenceEndDate!.day,
      );
      if (dateOnly.isAfter(endDate)) {
        return false;
      }
    }
    
    // 2. 제외된 날짜 체크
    if (schedule.excludedDates != null && schedule.excludedDates!.isNotEmpty) {
      final year = dateOnly.year.toString();
      final month = dateOnly.month.toString().padLeft(2, '0');
      final day = dateOnly.day.toString().padLeft(2, '0');
      final dateStr = '$year-$month-$day';
      
      if (schedule.excludedDates!.split(',').contains(dateStr)) {
        return false;
      }
    }
    
    // 3. 요일 패턴 체크
    final weekday = date.weekday; // 1(월)~7(일)
    final List<String> days = schedule.recurrenceDays!.split(',');
    
    // Dart의 weekday(1=월요일, 7=일요일)를 배열 인덱스(0부터 시작)로 변환
    // 백엔드는 이제 월요일=1, 일요일=7로 Dart와 동일하게 처리
    int dayIndex = weekday - 1; // 배열 인덱스는 0부터 시작하므로 1을 빼줌
    
    return days.length == 7 && days[dayIndex] == "1";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Container(
            width: 40,
            child: IconButton(
              icon: Image.asset('assets/images/calendarchange.png', width: 24, height: 24),
              onPressed: () {
                // 캘린더 형식 변경
                setState(() {
                  if (_calendarFormat == CalendarFormat.week) {
                    _calendarFormat = CalendarFormat.month;
                  } else {
                    _calendarFormat = CalendarFormat.week;
                  }
                });
              },
            ),
          ),
          actions: [
            Container(
              width: 40,
              child: IconButton(
                icon: Image.asset('assets/images/calendarreturn.png', width: 24, height: 24),
                onPressed: () {
                  // 오늘 날짜로 돌아가기
                  _goToToday();
                },
              ),
            ),
            Container(
              width: 40,
              child: IconButton(
                icon: Image.asset('assets/images/calendarsearch.png', width: 24, height: 24),
                onPressed: () {
                  // 검색 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleSearchPage(),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: 40,
              child: IconButton(
                icon: Image.asset('assets/images/calendarsetting.png', width: 24, height: 24),
                onPressed: () {
                  // 설정 기능
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              daysOfWeekHeight: 40,
              rowHeight: 50,
              availableGestures: AvailableGestures.all,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                leftChevronIcon: Image.asset('assets/images/calendarleft.png', width: 24, height: 24),
                rightChevronIcon: Image.asset('assets/images/calendarright.png', width: 24, height: 24),
                titleTextStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                headerPadding: const EdgeInsets.symmetric(vertical: 16),
                headerMargin: const EdgeInsets.only(bottom: 8),
                titleTextFormatter: (date, locale) {
                  // 주간 뷰일 때는 연도, 월, 주차 표시
                  if (_calendarFormat == CalendarFormat.week) {
                    // 해당 월의 첫 번째 날짜 찾기
                    final firstDayOfMonth = DateTime(date.year, date.month, 1);
                    
                    // 현재 날짜가 몇 번째 주인지 계산
                    final int weekNumber = ((date.day + firstDayOfMonth.weekday - 1) / 7).ceil();
                    
                    return '${date.year}년 ${date.month}월 ${weekNumber}주차';
                  }
                  return '${date.year}년 ${date.month}월';
                },
              ),
              onHeaderTapped: (date) {
                _showMonthYearPicker(context, date);
              },
              calendarStyle: CalendarStyle(
                cellMargin: EdgeInsets.zero,
                cellPadding: EdgeInsets.zero,
                defaultDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.transparent, width: 0),
                  borderRadius: BorderRadius.circular(10),
                ),
                weekendDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.transparent, width: 0),
                  borderRadius: BorderRadius.circular(10),
                ),
                outsideDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.transparent, width: 0),
                  borderRadius: BorderRadius.circular(10),
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.blue, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.blue, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                cellAlignment: Alignment.center,
                weekendTextStyle: const TextStyle(color: Colors.red),
                defaultTextStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                ),
                outsideTextStyle: const TextStyle(color: Colors.grey),
                markersMaxCount: 3,
                markersAnchor: 0.7,
                markerMargin: const EdgeInsets.only(top: 5),
                markerSize: 6,
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              availableCalendarFormats: const {
                CalendarFormat.month: '월',
                CalendarFormat.week: '주',
              },
              eventLoader: _getEventsForCalendarMarker,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
                  final index = day.weekday % 7;
                  Color color;
                  
                  if (day.weekday == DateTime.sunday) {
                    color = Colors.red;
                  } else if (day.weekday == DateTime.saturday) {
                    color = Colors.blue;
                  } else {
                    color = Colors.black;
                  }
                  
                  return Center(
                    child: Text(
                      weekdays[index],
                      style: TextStyle(
                        color: color,
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
                markerBuilder: (context, day, events) {
                  // events는 이미 _getEventsForCalendarMarker에서 필터링되었으므로
                  // 추가 필터링은 불필요함
                  if (events.isEmpty) return Container();
                  
                  // 우선순위를 빨강, 노랑, 초록으로 제한
                  final priorities = events
                      .map((e) => Priority.fromValue((e as Schedule).priority))
                      .where((p) => p == Priority.high || p == Priority.medium || p == Priority.low)
                      .toSet()
                      .toList();
                  
                  return Positioned(
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: priorities.map((priority) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: priority.color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final isSelected = isSameDay(day, _selectedDay);
                  return Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                      shape: BoxShape.rectangle,
                      border: Border.all(color: Colors.blue, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: day.weekday == DateTime.sunday 
                                ? Colors.red 
                                : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  return Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      border: Border.all(color: Colors.transparent, width: 0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: day.weekday == DateTime.sunday 
                                ? Colors.red 
                                : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.rectangle,
                      border: Border.all(color: Colors.blue, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: day.weekday == DateTime.sunday 
                                ? Colors.red 
                                : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 12), // 캘린더와 일정바 사이 간격 추가
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null && _events.isEmpty)
            Expanded(
              child: Center(
                child: Text(_errorMessage!),
              ),
            )
          else
            Expanded(
              child: _buildEventList(),
            ),
        ],
      ),
      floatingActionButton: AddButton(
        items: [
          AddButtonItem(
            label: '사진으로 일정 추가',
            iconPath: 'assets/images/image.png',
            onPressed: () {
              // 사진으로 일정 추가 기능
            },
          ),
          AddButtonItem(
            label: '일정 자동 배치',
            iconPath: 'assets/images/list.png',
            onPressed: () {
              // 일정 자동 배치 기능
            },
            description: '여러 개의 일정을 일정표에 맞춰 배치 해드립니다',
          ),
          AddButtonItem(
            label: '일정 추가',
            iconPath: 'assets/images/schedule.png',
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/add_schedule');
              if (result == true) {
                // 일정 추가 후 새로고침
                _loadSchedules();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    // 하단 일정바에는 모든 일정을 표시 (displayOnCalendar=false 포함)
    final events = _getAllEventsForDay(_selectedDay);
    
    // 시작 시간 순으로 정렬
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더 부분 (고정)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                '${_selectedDay.day}일, ${_getDayOfWeek(_selectedDay.weekday)}',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _selectedDay.weekday == DateTime.sunday 
                    ? Colors.red 
                    : (_selectedDay.weekday == DateTime.saturday ? Colors.blue : Colors.black),
                ),
              ),
            ],
          ),
        ),
        
        // 일정 목록 또는 '일정 없음' 메시지
        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Text(
                    '일정이 없습니다',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF767676),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: events.length + 1, // 추가 여백을 위해 +1
                  padding: const EdgeInsets.symmetric(vertical: 0), // 상단 여백 제거
                  itemBuilder: (context, index) {
                    if (index == events.length) {
                      // 마지막 아이템은 추가 여백
                      return const SizedBox(height: 100);
                    }
                    return _buildScheduleItem(events[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    final priority = Priority.fromValue(schedule.priority);
    // 24시간 형식으로 시간 표시 (HH는 대문자로 24시간 형식, hh는 소문자로 12시간 형식)
    final startTime = DateFormat('HH:mm').format(schedule.startTime);
    final endTime = DateFormat('HH:mm').format(schedule.endTime);
    
    // 캘린더 형식에 따라 다른 디자인 적용
    if (_calendarFormat == CalendarFormat.week) {
      // 주차별 캘린더 화면 (주간 뷰)에서 사용할 디자인
      // 우선순위에 따라 다른 색상 적용
      Color boxColor;
      switch (priority) {
        case Priority.high:
          boxColor = const Color(0xFFFF9E99); // 빨강색
          break;
        case Priority.medium:
          boxColor = const Color(0xFFFFEE8C); // 노랑색
          break;
        case Priority.low:
          boxColor = const Color(0xFFADEBB3); // 초록색
          break;
        default:
          boxColor = const Color(0xFFB8B4A3); // 기본 베이지색
      }
      
      return GestureDetector(
        onTap: () async {
          // 일정 수정 페이지로 이동
          final result = await Navigator.pushNamed(
            context, 
            '/edit_schedule',
            arguments: schedule,
          );
          
          // 일정 수정 후 새로고침
          if (result == true) {
            refreshSchedules();
          }
        },
        onLongPress: () {
          // 길게 누르면 삭제/미루기 옵션 표시
          _showScheduleOptions(schedule);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // 상단 여백 추가 줄임
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, // 오른쪽 정렬로 변경
            children: [
              // 시간과 실선을 Row로 배치하여 사진처럼 표시
              Row(
                children: [
                  // 시간 표시 - 24시간 형식 (13:00, 23:55 등)
                  Text(
                    startTime,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 실선
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2), // 간격 줄임
              // 일정 내용
              Container(
                width: 224, // 요청한 박스 너비
                height: 126, // 요청한 박스 높이
                margin: const EdgeInsets.only(top: 0), // 상단 여백 제거
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      schedule.title,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // 간격 4로 변경
                    // 종료 시간 - 24시간 형식 (13:00, 23:55 등)
                    Row(
                      children: [
                        Text(
                          "⏱️",
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~ $endTime',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            color: Color(0xFF767676),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15), // 간격 15로 변경
                    // 메모 내용
                    if (schedule.description != null && schedule.description!.isNotEmpty)
                      Text(
                        schedule.description!,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 기본 캘린더 화면 (월간 뷰)에서 사용할 디자인
      return GestureDetector(
        onTap: () async {
          // 일정 수정 페이지로 이동
          final result = await Navigator.pushNamed(
            context, 
            '/edit_schedule',
            arguments: schedule,
          );
          
          // 일정 수정 후 새로고침
          if (result == true) {
            refreshSchedules();
          }
        },
        onLongPress: () {
          // 길게 누르면 삭제/미루기 옵션 표시
          _showScheduleOptions(schedule);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // 간격 추가
          padding: EdgeInsets.zero, // 내부 여백 제거
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      decoration: BoxDecoration(
                        color: priority.color,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.title,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (schedule.description != null && schedule.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                schedule.description!,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  color: Color(0xFF767676),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey.withOpacity(0.05),
                child: Row(
                  children: [
                    Text(
                      '$startTime ~ $endTime', // 24시간 형식 (13:00, 23:55 등)
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Color(0xFF767676),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return '월요일';
      case 2: return '화요일';
      case 3: return '수요일';
      case 4: return '목요일';
      case 5: return '금요일';
      case 6: return '토요일';
      case 7: return '일요일';
      default: return '';
    }
  }

  // 연도와 월 선택 다이얼로그 표시
  void _showMonthYearPicker(BuildContext context, DateTime initialDate) async {
    final ThemeData theme = Theme.of(context);
    
    // 현재 선택된 날짜
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    
    // 연도 범위
    final years = List.generate(11, (index) => selectedYear - 5 + index);
    // 월 리스트
    final months = List.generate(12, (index) => index + 1);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('날짜 선택', 
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Container(
            width: 300,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 연도 선택
                Text('연도', 
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 100,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                    ),
                    itemCount: years.length,
                    itemBuilder: (context, index) {
                      final year = years[index];
                      final isSelected = year == selectedYear;
                      
                      return GestureDetector(
                        onTap: () {
                          selectedYear = year;
                          Navigator.pop(context);
                          _showMonthYearPicker(context, DateTime(year, selectedMonth));
                        },
                        child: Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '$year년',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                color: isSelected ? Colors.blue : Colors.black,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                
                // 월 선택
                Text('월', 
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 100,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      final month = months[index];
                      final isSelected = month == selectedMonth;
                      
                      return GestureDetector(
                        onTap: () {
                          selectedMonth = month;
                          Navigator.pop(context);
                          
                          // 선택된 연도와 월로 캘린더 업데이트
                          setState(() {
                            _focusedDay = DateTime(selectedYear, selectedMonth, 1);
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '$month월',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                color: isSelected ? Colors.blue : Colors.black,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 일정 옵션 (삭제/미루기) 대화상자 표시
  void _showScheduleOptions(Schedule schedule) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  '일정 삭제',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteSchedule(schedule);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text(
                  '일정 미루기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showPostponeDialog(schedule);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
                _postponeSchedule(schedule, '내일', null);
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
                _postponeSchedule(schedule, '일주일 후', null);
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
        
        _postponeSchedule(schedule, '직접 설정', customDateTime);
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

      // 스케줄 서비스를 사용해 미루기 기능 호출
      await _scheduleService.postponeSchedule(
        scheduleId,
        mode,
        custom: customDateTime,
        occurrenceDate: _selectedDay
      );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 성공적으로 미뤄졌습니다')),
          );
          // 화면 즉시 갱신
          setState(() {
            final normalizedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
            if (_events[normalizedDate] != null) {
              _events[normalizedDate]!.removeWhere((s) => s.scheduleId == schedule.scheduleId);
            }
          });
          
          // 백그라운드에서 전체 일정 다시 로드
          _loadSchedules();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 미루기 실패: $e')),
        );
      }
    }
  }

  // 일정 삭제 메서드
  Future<void> _deleteSchedule(Schedule schedule) async {
    final bool isRecurring = schedule.recurrenceDays != null && 
                            schedule.recurrenceDays!.isNotEmpty &&
                            schedule.recurrenceDays != "0,0,0,0,0,0,0";
    
    // 삭제 다이얼로그 표시
    final result = await showDialog(
      context: context,
      builder: (context) => RecurrenceDeleteDialog(isRecurring: isRecurring),
    );
    
    if (result == null) {
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

      String option = 'ALL';
      DateTime? fromDate;
      
      if (result is bool && result == true) {
        // 일회성 일정이거나 단순 확인에서 '삭제' 선택한 경우
        option = 'ALL';
      } else if (result is RecurrenceDeleteMode) {
        // 반복 일정의 경우 선택한 모드에 따라 처리
        switch (result) {
          case RecurrenceDeleteMode.SINGLE:
            option = 'SINGLE';
            fromDate = DateTime(
              _selectedDay.year,
              _selectedDay.month,
              _selectedDay.day,
            );
            break;
          case RecurrenceDeleteMode.FUTURE:
            option = 'FUTURE';
            fromDate = DateTime(
              _selectedDay.year,
              _selectedDay.month,
              _selectedDay.day,
            );
            break;
          case RecurrenceDeleteMode.ALL:
            option = 'ALL';
            break;
        }
      }
      
      // 스케줄 서비스를 통해 삭제 처리
      await _scheduleService.deleteSchedule(
        scheduleId, 
        option: option,
        occurrenceDate: fromDate
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      
      // 현재 선택된 날짜의 이벤트에서 해당 일정 제거
      setState(() {
        final normalizedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
        if (_events[normalizedDate] != null) {
          _events[normalizedDate]!.removeWhere((s) => s.scheduleId == schedule.scheduleId);
        }
      });
      
      // 일정 새로고침
      _loadSchedules();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
} 