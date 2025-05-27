import 'package:flutter/material.dart';

/// 날짜만 선택할 수 있는 선택기 위젯
/// 기존 DateTimeSelector와 동일한 스타일을 유지하되 시간 선택 부분이 없습니다.
class DateOnlySelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime>? onStartDateChanged;
  final ValueChanged<DateTime>? onEndDateChanged;

  const DateOnlySelector({
    super.key,
    required this.startDate,
    required this.endDate,
    this.onStartDateChanged,
    this.onEndDateChanged,
  });

  String _getWeekday(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // 시간은 00:00:00으로 설정 (시간 부분 제거)
      final DateTime selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );

      if (isStartDate) {
        onStartDateChanged?.call(selectedDateTime);
        
        // 시작일이 마감일보다 나중이면 마감일을 자동으로 시작일로 설정
        if (selectedDateTime.isAfter(endDate)) {
          onEndDateChanged?.call(selectedDateTime);
        }
      } else {
        // 선택한 마감일이 시작일보다 이전이면 조정
        if (selectedDateTime.isBefore(startDate)) {
          onEndDateChanged?.call(startDate);
        } else {
          onEndDateChanged?.call(selectedDateTime);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '날짜',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: -0.025,
            color: Colors.black,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            GestureDetector(
              onTap: () => _selectDate(context, true),
              child: Container(
                width: 150,
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 98,
                      height: 22,
                      child: Text(
                        '${startDate.month}월 ${startDate.day}일 (${_getWeekday(startDate)})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          letterSpacing: -0.025,
                          color: Colors.black,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Image.asset(
                'assets/images/arrow-right.png',
                width: 28,
                height: 28,
              ),
            ),
            GestureDetector(
              onTap: () => _selectDate(context, false),
              child: Container(
                width: 150,
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 98,
                      height: 22,
                      child: Text(
                        '${endDate.month}월 ${endDate.day}일 (${_getWeekday(endDate)})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          letterSpacing: -0.025,
                          color: Colors.black,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 