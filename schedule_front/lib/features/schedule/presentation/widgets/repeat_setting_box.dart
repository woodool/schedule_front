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
    String recurrenceDays = '';
    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        if (recurrenceDays.isNotEmpty) {
          recurrenceDays += ',';
        }
        recurrenceDays += (i + 1).toString(); // 1부터 시작 (월요일)
      }
    }
    return recurrenceDays.isEmpty ? null : recurrenceDays;
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
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: List.generate(
                          weekdays.length,
                          (index) => GestureDetector(
                            onTap: () {
                              setState(() {
                                tempSelectedDays[index] = !tempSelectedDays[index];
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
                _getSelectedDaysText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 