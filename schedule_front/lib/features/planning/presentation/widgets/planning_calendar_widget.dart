import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// 일정 계획 캘린더 위젯
/// 날짜 선택 기능과 추천 날짜, 불가능한 날짜 표시 기능을 제공합니다.
class PlanningCalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> unavailableDates;
  final List<DateTime> recommendedDates;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(DateTime) onMonthChanged;

  const PlanningCalendarWidget({
    Key? key,
    required this.focusedDay,
    this.selectedDay,
    required this.startDate,
    required this.endDate,
    required this.unavailableDates,
    required this.recommendedDates,
    required this.onDaySelected,
    required this.onMonthChanged,
  }) : super(key: key);

  // 날짜가 사용 불가능한지 체크
  bool _isUnavailableDate(DateTime date) {
    return unavailableDates.any((d) => 
      d.year == date.year && 
      d.month == date.month && 
      d.day == date.day
    );
  }
  
  // 날짜가 추천 날짜인지 체크
  bool _isRecommendedDate(DateTime date) {
    return recommendedDates.any((d) => 
      d.year == date.year && 
      d.month == date.month && 
      d.day == date.day
    );
  }

  @override  
  Widget build(BuildContext context) {    
    // 디버그 정보 출력    
    print('📅 PlanningCalendarWidget 빌드 시작');    
    print('📆 현재 날짜 범위: $startDate ~ $endDate');    
    print('📊 추천 날짜 수: ${recommendedDates.length}');    
    if (recommendedDates.isNotEmpty) {      
      print('📆 추천 날짜: ${recommendedDates.map((d) => '${d.year}-${d.month}-${d.day}').join(', ')}');    
    }        
    
    return Column(      
      children: [        
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
                  final previousMonth = DateTime(focusedDay.year, focusedDay.month - 1, 1);                  
                  // 시작일 월보다 이전으로는 이동 불가                  
                  if (previousMonth.year > startDate.year ||                       
                       (previousMonth.year == startDate.year &&                        
                        previousMonth.month >= startDate.month)) {                    
                    print('📅 이전 달로 이동: ${previousMonth.year}년 ${previousMonth.month}월');                    
                    onMonthChanged(previousMonth);                  
                  }                
                },              
              ),                            
              
              // 연도와 월 표시              
              Text(                
                '${focusedDay.year}년 ${focusedDay.month}월',                
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
                  final nextMonth = DateTime(focusedDay.year, focusedDay.month + 1, 1);                  
                  // 마감일 월보다 다음으로는 이동 불가                  
                  if (nextMonth.year < endDate.year ||                       
                      (nextMonth.year == endDate.year &&                        
                       nextMonth.month <= endDate.month)) {                    
                    print('📅 다음 달로 이동: ${nextMonth.year}년 ${nextMonth.month}월');                    
                    onMonthChanged(nextMonth);                  
                  }                
                },              
              ),            
            ],          
          ),        
        ),
        
        // 캘린더
        TableCalendar(
          firstDay: DateTime(startDate.year, startDate.month, 1),
          lastDay: DateTime(endDate.year, endDate.month, 
                   DateTime(endDate.year, endDate.month + 1, 0).day),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) {
            return selectedDay != null && isSameDay(selectedDay!, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (!_isUnavailableDate(selectedDay)) {
              onDaySelected(selectedDay, focusedDay);
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
    );
  }
} 