import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/matching_room.dart';
import '../../../../features/schedule/domain/models/schedule.dart';
import 'matching_room_result.dart';

class MatchingScheduleRoom extends StatefulWidget {
  final Schedule schedule;
  final int participantCount;

  const MatchingScheduleRoom({
    Key? key,
    required this.schedule,
    this.participantCount = 6,
  }) : super(key: key);

  @override
  State<MatchingScheduleRoom> createState() => _MatchingScheduleRoomState();
}

class _MatchingScheduleRoomState extends State<MatchingScheduleRoom> {
  bool _showVotingView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Set<TimeOfDay> _selectedTimeSlots = {};
  
  // 불가능한 날짜 목록 (예시)
  final List<DateTime> _unavailableDates = [
    DateTime.now().add(const Duration(days: 2)),
    DateTime.now().add(const Duration(days: 5)),
  ];
  
  // 추천 일자 목록 (예시)
  final List<DateTime> _recommendedDates = [
    DateTime.now().add(const Duration(days: 3)),
    DateTime.now().add(const Duration(days: 4)),
  ];
  
  // 선택된 날짜의 가능한 시간대 (예시)
  final List<TimeOfDay> _availableTimeSlots = [
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 18, minute: 0),
    const TimeOfDay(hour: 19, minute: 0),
    const TimeOfDay(hour: 20, minute: 0),
    const TimeOfDay(hour: 21, minute: 0),
  ];
  
  // 참여자 목록 (예시)
  final List<String> _participants = [
    '(방장)나',
    '김김김',
    '남남남',
    '담담담',
    '팜팜팜',
    '맘맘맘',
  ];
  
  @override
  void initState() {
    super.initState();
    _focusedDay = widget.schedule.startTime;
    _selectedDay = null;
  }

  // 날짜 포맷 함수
  String _formatDateRange() {
    final DateFormat formatter = DateFormat('MM월 dd일');
    final startDate = formatter.format(widget.schedule.startTime);
    final endDate = formatter.format(widget.schedule.endTime);
    
    return "$startDate ~ $endDate";
  }
  
  // 날짜 선택 다이얼로그
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: widget.schedule.startTime,
        end: widget.schedule.endTime,
      ),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      // 여기서 날짜 범위 업데이트 처리
      // 예: _updateDateRange(picked.start, picked.end);
    }
  }
  
  // 날짜가 사용 불가능한지 체크
  bool _isUnavailableDate(DateTime date) {
    return _unavailableDates.any((d) => 
      d.year == date.year && 
      d.month == date.month && 
      d.day == date.day
    );
  }
  
  // 날짜가 추천 날짜인지 체크
  bool _isRecommendedDate(DateTime date) {
    return _recommendedDates.any((d) => 
      d.year == date.year && 
      d.month == date.month && 
      d.day == date.day
    );
  }
  
  // 초대 코드 복사 함수
  void _copyInvitationCode() {
    // TODO: 초대 코드 복사 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대 코드가 복사되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 시간대 선택 함수
  void _toggleTimeSlot(TimeOfDay timeSlot) {
    setState(() {
      if (_selectedTimeSlots.contains(timeSlot)) {
        _selectedTimeSlots.remove(timeSlot);
      } else {
        _selectedTimeSlots.add(timeSlot);
      }
    });
  }

  // 시간대가 선택되었는지 확인하는 함수
  bool _isTimeSlotSelected(TimeOfDay timeSlot) {
    return _selectedTimeSlots.contains(timeSlot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildParticipantsDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '일정 잡기 이름',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // 사용자 수 표시
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.black, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.participantCount}명',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 날짜 범위 선택 섹션
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDateRange(),
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 24),
                ],
              ),
            ),
          ),
          
          // 메인 콘텐츠 영역
          Expanded(
            child: _showVotingView 
              ? _buildVotingView() 
              : _buildInitialView(),
          ),
          
          // 하단 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 275,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_showVotingView) {
                        // 투표 등록 후 결과 화면으로 이동
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MatchingRoomResult(
                              schedule: widget.schedule,
                              confirmedDate: _recommendedDates.first, // 예시로 첫 번째 추천 날짜 사용
                            ),
                          ),
                        );
                      } else {
                        // 일정 잡기 뷰로 전환
                        setState(() {
                          _showVotingView = true;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _showVotingView ? '투표 등록' : '일정 잡기',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 참여자 목록 드로워
  Widget _buildParticipantsDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.45,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '참여자 목록',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    _participants[index],
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          // 초대 코드 복사 버튼
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _copyInvitationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '초대코드 복사',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 초기 빈 화면
  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 여기에 빈 화면 컨텐츠 추가 (선택사항)
        ],
      ),
    );
  }
  
  // 투표 화면 (캘린더 + 추천 일자)
  Widget _buildVotingView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 추천 일자 섹션
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '추천 일자',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _recommendedDates.map((date) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          DateFormat('MM월 dd일 (E)', 'ko_KR').format(date),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // 선택된 날짜의 가능한 시간대 표시
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '가능한 시간대',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTimeSlots.map((timeSlot) {
                      final isSelected = _isTimeSlotSelected(timeSlot);
                      return GestureDetector(
                        onTap: () => _toggleTimeSlot(timeSlot),
                        child: Chip(
                          label: Text(
                            '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                          side: BorderSide(
                            color: isSelected ? Colors.blue : Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          
          // 가능한 날짜 선택 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '가능한 날짜${_selectedDay != null ? ' (전체보기 가능)' : ''} 달력',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          
          // 커스텀 캘린더 헤더
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이전 달 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black),
                  onPressed: () {
                    final previousMonth = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    // 시작일 월보다 이전으로는 이동 불가
                    if (previousMonth.year > widget.schedule.startTime.year || 
                        (previousMonth.year == widget.schedule.startTime.year && 
                         previousMonth.month >= widget.schedule.startTime.month)) {
                      setState(() {
                        _focusedDay = previousMonth;
                      });
                    }
                  },
                ),
                
                // 연도와 월 표시
                Text(
                  '${_focusedDay.year}년 ${_focusedDay.month}월',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // 다음 달 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black),
                  onPressed: () {
                    final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    // 마감일 월보다 다음으로는 이동 불가
                    if (nextMonth.year < widget.schedule.endTime.year || 
                        (nextMonth.year == widget.schedule.endTime.year && 
                         nextMonth.month <= widget.schedule.endTime.month)) {
                      setState(() {
                        _focusedDay = nextMonth;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          // 캘린더
          TableCalendar(
            firstDay: DateTime(widget.schedule.startTime.year, widget.schedule.startTime.month, 1),
            lastDay: DateTime(widget.schedule.endTime.year, widget.schedule.endTime.month, 
                     DateTime(widget.schedule.endTime.year, widget.schedule.endTime.month + 1, 0).day),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return _selectedDay != null && isSameDay(_selectedDay!, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!_isUnavailableDate(selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            headerStyle: HeaderStyle(
              titleTextStyle: const TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              formatButtonTextStyle: const TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.black,
                fontSize: 14,
              ),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(16.0),
              ),
              // 헤더를 숨김
              titleCentered: true,
              formatButtonVisible: false,
              leftChevronVisible: false,
              rightChevronVisible: false,
              headerPadding: const EdgeInsets.all(0),
              // 헤더 높이를 최소화하여 거의 보이지 않게 함
              titleTextFormatter: (date, locale) => '',
            ),
            calendarStyle: CalendarStyle(
              // 선택 불가능한 날짜는 빨간색으로 표시
              disabledTextStyle: const TextStyle(color: Colors.red),
              outsideTextStyle: const TextStyle(color: Colors.black38),
              // 선택된 날짜 스타일
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF0062FF),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              // 일반 날짜 텍스트 색상 검정색으로 설정
              defaultTextStyle: const TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.black,
              ),
              // 주말 텍스트 색상 변경
              weekendTextStyle: const TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.red,
              ),
              // 오늘 날짜 텍스트 색상
              todayTextStyle: const TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              // 선택된 날짜 텍스트 색상
              selectedTextStyle: const TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) {
                // 불가능한 날짜는 빨간색으로 표시
                if (_isUnavailableDate(date)) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.red
                      ),
                    ),
                  );
                }
                
                // 추천 일자는 파란색 배경으로 표시
                if (_isRecommendedDate(date)) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.blue
                      ),
                    ),
                  );
                }
                
                // 주말 날짜는 빨간색으로 표시 (토요일, 일요일)
                if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.red,
                      ),
                    ),
                  );
                }
                
                // 일반 날짜 - 검정색으로 표시
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.black,
                    ),
                  ),
                );
              },
              
              // 오늘 날짜
              todayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              
              // 선택된 날짜
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0062FF),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              
              // 현재 달이 아닌 외부 날짜
              outsideBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.black38,
                    ),
                  ),
                );
              },
              
              // 마커 없음
              markerBuilder: (context, date, events) {
                return null;
              },
              
              // 요일 헤더 (월, 화, 수, 목, 금, 토, 일)
              dowBuilder: (context, day) {
                final text = ['월', '화', '수', '목', '금', '토', '일'][day.weekday - 1];
                final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      color: isWeekend ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 