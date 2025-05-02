import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';
import 'package:schedule/features/schedule/domain/models/priority.dart';
import 'package:schedule/features/schedule/domain/models/schedule.dart';
import 'package:schedule/features/schedule/domain/services/schedule_service.dart';
import 'package:schedule/features/schedule/presentation/pages/schedule_search_page.dart';
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
    _calendarFormat = CalendarFormat.month;
    _loadSchedules();
  }

  @override
  void didUpdateWidget(CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 화면이 다시 표시될 때마다 일정 새로고침
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 서비스를 통해 일정 데이터 로드
      final schedules = await _scheduleService.getSchedules();
      
      // 날짜별로 일정 정리
      final events = <DateTime, List<Schedule>>{};
      
      for (final schedule in schedules) {
        // displayOnCalendar 속성에 관계없이 모든 일정을 _events에 저장
        // 다일 일정 처리 - 시작일부터 종료일까지 모든 날짜에 일정 표시
        final startDay = DateTime(
          schedule.startTime.year,
          schedule.startTime.month,
          schedule.startTime.day,
        );
        
        final endDay = DateTime(
          schedule.endTime.year,
          schedule.endTime.month,
          schedule.endTime.day,
        );
        
        // 시작일부터 종료일까지 순회
        for (DateTime day = startDay; 
            !day.isAfter(endDay); 
            day = day.add(const Duration(days: 1))) {
              
          final normalizedDay = DateTime(day.year, day.month, day.day);
          
          if (events[normalizedDay] == null) {
            events[normalizedDay] = [];
          }
          
          events[normalizedDay]!.add(schedule);
        }
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

  List<Schedule> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _events[normalizedDate] ?? [];
  }

  // 하단 일정바에는 모든 일정을 표시하는 메서드
  List<Schedule> _getAllEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    // displayOnCalendar 속성과 관계없이 모든 일정을 반환
    return _events[normalizedDate] ?? [];
  }

  // 마커 표시를 위한 일정 필터링 (displayOnCalendar가 true인 일정만 표시)
  List<Schedule> _getEventsForCalendarMarker(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    final events = _events[normalizedDate] ?? [];
    // displayOnCalendar가 true인 일정만 필터링
    return events.where((schedule) => schedule.displayOnCalendar).toList();
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
                // 메뉴 기능
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
                      style: TextStyle(color: color),
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
    final startTime = DateFormat('HH:mm').format(schedule.startTime);
    final endTime = DateFormat('HH:mm').format(schedule.endTime);
    
    return GestureDetector(
      onTap: () async {
        // 일정 수정 페이지로 이동
        final result = await Navigator.pushNamed(
          context, 
          '/edit_schedule',
          arguments: schedule,
        );
        
        if (result == true) {
          // 일정 수정 후 새로고침
          _loadSchedules();
        }
      },
      onLongPress: () {
        // 길게 누르면 삭제/미루기 옵션 표시
        _showScheduleOptions(schedule);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    '$startTime ~ $endTime',
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
                onTap: () async {
                  Navigator.pop(context);
                  
                  // 삭제 확인 대화상자
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('일정 삭제'),
                      content: const Text('이 일정을 삭제하시겠습니까?'),
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
                  
                  if (confirmed == true) {
                    try {
                      await _scheduleService.deleteSchedule(schedule.scheduleId!);
                      
                      setState(() {
                        // 현재 선택된 날짜의 이벤트에서 해당 일정 제거
                        final normalizedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
                        if (_events[normalizedDate] != null) {
                          _events[normalizedDate]!.removeWhere((s) => s.scheduleId == schedule.scheduleId);
                        }
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('일정이 삭제되었습니다')),
                      );
                      
                      // 전체 일정을 백그라운드에서 다시 로드
                      _loadSchedules();
                      
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('일정 삭제 중 오류가 발생했습니다: $e')),
                      );
                    }
                  }
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
} 