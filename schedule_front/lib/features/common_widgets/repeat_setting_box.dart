import 'package:flutter/material.dart';

class RepeatSettingBox extends StatelessWidget {
  final List<bool> selectedDays;
  final ValueChanged<List<bool>>? onDaysChanged;
  final ValueChanged<String?>? onRecurrenceDaysChanged;
  final DateTime? recurrenceStartDate;
  final DateTime? recurrenceEndDate;
  final ValueChanged<DateTime?>? onRecurrenceStartDateChanged;
  final ValueChanged<DateTime?>? onRecurrenceEndDateChanged;

  const RepeatSettingBox({
    super.key,
    required this.selectedDays,
    this.onDaysChanged,
    this.onRecurrenceDaysChanged,
    this.recurrenceStartDate,
    this.recurrenceEndDate,
    this.onRecurrenceStartDateChanged,
    this.onRecurrenceEndDateChanged,
  });

  static const List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String? _getRecurrenceDays(List<bool> days) {
    // 백엔드 요일 순서에 맞게 재정렬 
    // 백엔드: 월(0), 화(1), 수(2), 목(3), 금(4), 토(5), 일(6) 순서로 배열 인덱스로 사용
    // 우리 UI: [월,화,수,목,금,토,일] 순서로 표시 (0부터 시작)
    final List<String> recurrenceBits = List.filled(7, '0');
    
    print('요일 변환 - UI 요일배열: $days');
    print('  선택된 요일 인덱스:');
    
    // UI 인덱스 -> 백엔드 배열 인덱스 매핑
    // UI: 0(월), 1(화), 2(수), 3(목), 4(금), 5(토), 6(일)
    // BE: 0(월), 1(화), 2(수), 3(목), 4(금), 5(토), 6(일) - 순서 동일
    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        // UI와 백엔드의 요일 순서가 같으므로 인덱스 변환 불필요
        int arrayIndex = i;
        recurrenceBits[arrayIndex] = '1';
        
        String dayName = '';
        switch(i) {
          case 0: dayName = '월요일'; break;
          case 1: dayName = '화요일'; break;
          case 2: dayName = '수요일'; break;
          case 3: dayName = '목요일'; break;
          case 4: dayName = '금요일'; break;
          case 5: dayName = '토요일'; break;
          case 6: dayName = '일요일'; break;
        }
        print('    $i ($dayName): 선택됨');
      }
    }
    
    // 모든 요일이 선택되지 않았으면 null 반환
    if (!recurrenceBits.contains('1')) {
      return null;
    }
    
    final result = recurrenceBits.join(',');
    
    // 디버그 정보 출력
    print('요일 선택 텍스트: ${_selectedDaysToText(days)}');
    print('최종 요일 패턴: $result');
    
    return result;
  }
  
  // 선택된 요일을 텍스트로 변환하는 도우미 메서드
  String _selectedDaysToText(List<bool> days) {
    List<String> result = [];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        result.add(weekdays[i]);
      }
    }
    return result.join(', ');
  }

  String _getSelectedDaysText([List<bool>? days]) {
    final targetDays = days ?? selectedDays;
    if (!targetDays.contains(true)) return '-';
    
    final selectedWeekdays = <String>[];
    for (int i = 0; i < targetDays.length; i++) {
      if (targetDays[i]) {
        selectedWeekdays.add(weekdays[i]);
      }
    }
    
    if (selectedWeekdays.length >= 4) {
      return '매주 ${selectedWeekdays.length}일';
    }
    
    return '매주 ${selectedWeekdays.join(', ')}';
  }

  Future<void> _showDaySelector(BuildContext context) async {
    List<bool> tempSelectedDays = List.from(selectedDays);
    DateTime? tempStartDate = recurrenceStartDate;
    DateTime? tempEndDate = recurrenceEndDate;
    
    // 현재 선택된 요일 기반으로 시작일 계산 함수
    void updateStartDateBasedOnSelection() {
      if (tempSelectedDays.contains(true) && tempStartDate == null) {
        // 오늘 날짜
        final today = DateTime.now();
        final todayWeekday = today.weekday; // 1(월요일)부터 7(일요일)
        
        // 선택된 요일 찾기
        List<int> selectedIndices = [];
        for (int i = 0; i < tempSelectedDays.length; i++) {
          if (tempSelectedDays[i]) {
            selectedIndices.add(i + 1); // 1(월요일)부터 7(일요일)
          }
        }
        
        // 가장 가까운 선택된 요일 찾기
        if (selectedIndices.isNotEmpty) {
          int minDaysToAdd = 7; // 최대 일주일
          
          for (int weekday in selectedIndices) {
            // 남은 일수 계산
            int daysToAdd = weekday >= todayWeekday 
                ? weekday - todayWeekday 
                : 7 + weekday - todayWeekday;
            
            if (daysToAdd < minDaysToAdd) {
              minDaysToAdd = daysToAdd;
            }
          }
          
          // 가장 가까운 날짜로 임시 시작일 설정
          tempStartDate = DateTime(today.year, today.month, today.day + minDaysToAdd);
          
          // 시작일이 설정되었고 종료일이 없으면 기본 종료일 설정 (4주 후)
          if (tempEndDate == null) {
            tempEndDate = DateTime(tempStartDate!.year, tempStartDate!.month, tempStartDate!.day + 28);
          }
        }
      }
    }
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: 300,
                height: 400, // 높이 증가
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '반복 설정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _getSelectedDaysText(tempSelectedDays),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0062FF),
                        ),
                      ),
                    ),
                    // 요일 선택 UI
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 요일 선택 레이블
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              '요일 선택',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: List.generate(
                              weekdays.length,
                              (index) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    tempSelectedDays[index] = !tempSelectedDays[index];
                                    // 요일 선택이 변경되면 시작일 자동 업데이트
                                    updateStartDateBasedOnSelection();
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: tempSelectedDays[index] ? const Color(0xFF0062FF) : Colors.black,
                                    border: Border.all(
                                      color: tempSelectedDays[index] ? const Color(0xFF0062FF) : Colors.white,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: tempSelectedDays[index] ? [
                                      BoxShadow(
                                        color: const Color(0xFF0062FF).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      weekdays[index],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: tempSelectedDays[index] ? Colors.white : Colors.white,
                                        fontWeight: tempSelectedDays[index] ? FontWeight.bold : FontWeight.normal,
                                        fontFamily: 'Pretendard',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 반복 기간 선택 UI
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '반복 기간',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard',
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 시작일 선택
                          GestureDetector(
                            onTap: () async {
                              // 선택할 때 기본 시작일 계산
                              updateStartDateBasedOnSelection();
                              
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: tempStartDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Color(0xFF0062FF),
                                        onPrimary: Colors.white,
                                        surface: Color(0xFF222222),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  tempStartDate = pickedDate;
                                  // 시작일이 종료일보다 이후라면 종료일 자동 업데이트
                                  if (tempEndDate != null && pickedDate.isAfter(tempEndDate!)) {
                                    tempEndDate = pickedDate.add(const Duration(days: 30));
                                  }
                                });
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Color(0xFF0062FF),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tempStartDate != null
                                      ? '시작일: ${tempStartDate!.year}.${tempStartDate!.month.toString().padLeft(2, '0')}.${tempStartDate!.day.toString().padLeft(2, '0')}'
                                      : '시작일 선택',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Pretendard',
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 종료일 선택
                          GestureDetector(
                            onTap: () async {
                              // 종료일 선택 시 최소 시작일 확인
                              if (tempStartDate == null) {
                                // 시작일이 없으면 자동 계산
                                updateStartDateBasedOnSelection();
                              }
                              
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: tempEndDate ?? (tempStartDate != null ? tempStartDate!.add(const Duration(days: 30)) : DateTime.now().add(const Duration(days: 30))),
                                firstDate: tempStartDate ?? DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Color(0xFF0062FF),
                                        onPrimary: Colors.white,
                                        surface: Color(0xFF222222),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  tempEndDate = pickedDate;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Color(0xFF0062FF),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tempEndDate != null
                                      ? '종료일: ${tempEndDate!.year}.${tempEndDate!.month.toString().padLeft(2, '0')}.${tempEndDate!.day.toString().padLeft(2, '0')}'
                                      : '종료일 선택',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Pretendard',
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('취소', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    // 시작일이 없으면 자동 계산
                    if (tempSelectedDays.contains(true) && tempStartDate == null) {
                      updateStartDateBasedOnSelection();
                    }
                    
                    onDaysChanged?.call(tempSelectedDays);
                    onRecurrenceDaysChanged?.call(_getRecurrenceDays(tempSelectedDays));
                    onRecurrenceStartDateChanged?.call(tempStartDate);
                    onRecurrenceEndDateChanged?.call(tempEndDate);
                    Navigator.of(context).pop();
                  },
                  child: Text('확인', style: TextStyle(color: Color(0xFF0062FF))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 반복 설정 텍스트 미리 계산
    final repeatText = _getSelectedDaysText();
    final bool hasRepeatDays = selectedDays.contains(true);
    
    // 반복 설정이 있을 때 시작일이 없으면 오늘 날짜 또는 선택한 요일 중 가장 가까운 날짜로 설정
    if (hasRepeatDays && recurrenceStartDate == null) {
      // 선택된 요일 찾기
      List<int> selectedIndices = [];
      for (int i = 0; i < selectedDays.length; i++) {
        if (selectedDays[i]) {
          // 우리의 인덱스(0=월요일)를 실제 요일 번호(1=월요일)로 변환
          selectedIndices.add(i + 1); // 1(월요일)부터 7(일요일)
        }
      }
      
      // 오늘 날짜
      final today = DateTime.now();
      final todayWeekday = today.weekday; // 1(월요일)부터 7(일요일)
      
      // 가장 가까운 선택된 요일 찾기
      DateTime nearestDate = today;
      
      if (selectedIndices.isNotEmpty) {
        // 오늘보다 이후의 가장 가까운 요일 찾기
        int minDaysToAdd = 7; // 최대 일주일
        
        for (int weekday in selectedIndices) {
          // 선택된 요일이 오늘보다 이후면 해당 요일까지 남은 일수
          // 선택된 요일이 오늘보다 이전이면 다음 주의 해당 요일까지 남은 일수
          int daysToAdd = weekday >= todayWeekday 
              ? weekday - todayWeekday 
              : 7 + weekday - todayWeekday;
          
          if (daysToAdd < minDaysToAdd) {
            minDaysToAdd = daysToAdd;
          }
        }
        
        // 가장 가까운 날짜 계산
        nearestDate = DateTime(today.year, today.month, today.day + minDaysToAdd);
      }
      
      // 디버그 출력
      print('반복 설정: 시작일 설정 - 오늘: $today, 요일: $todayWeekday, 선택된 요일: $selectedIndices, 설정된 시작일: $nearestDate');
      
      // 비동기적으로 시작일 업데이트
      Future.microtask(() {
        onRecurrenceStartDateChanged?.call(nearestDate);
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '반복설정',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _showDaySelector(context),
          child: Container(
            width: 140,
            height: 60,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: Colors.black,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                repeatText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: hasRepeatDays ? Colors.black : Colors.grey,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 