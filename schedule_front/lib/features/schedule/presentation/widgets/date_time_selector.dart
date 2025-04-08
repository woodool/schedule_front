import 'package:flutter/material.dart';

class DateTimeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime>? onStartDateChanged;
  final ValueChanged<DateTime>? onEndDateChanged;

  const DateTimeSelector({
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
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: isStartDate ? startDate.hour : endDate.hour,
          minute: isStartDate ? startDate.minute : endDate.minute,
        ),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (isStartDate) {
          onStartDateChanged?.call(selectedDateTime);
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
          '날짜 및 시간',
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
                height: 104,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    SizedBox(
                      width: 98,
                      height: 22,
                      child: Text(
                        '${startDate.hour < 12 ? '오전' : '오후'} ${startDate.hour > 12 ? startDate.hour - 12 : startDate.hour}시 ${startDate.minute}분',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
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
                height: 104,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    SizedBox(
                      width: 98,
                      height: 22,
                      child: Text(
                        '${endDate.hour < 12 ? '오전' : '오후'} ${endDate.hour > 12 ? endDate.hour - 12 : endDate.hour}시 ${endDate.minute}분',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
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