import 'package:flutter/material.dart';

/// 시간 슬롯 선택 위젯
/// 특정 날짜에 사용 가능한 시간대를 선택할 수 있는 UI를 제공합니다.
class TimeSlotSelectorWidget extends StatelessWidget {
  final List<TimeOfDay> availableTimeSlots;
  final Set<TimeOfDay> selectedTimeSlots;
  final int timeSlotUnit;
  final Function(TimeOfDay) onTimeSlotToggle;

  const TimeSlotSelectorWidget({
    Key? key,
    required this.availableTimeSlots,
    required this.selectedTimeSlots,
    required this.timeSlotUnit,
    required this.onTimeSlotToggle,
  }) : super(key: key);

  // 시간대 포맷 문자열 반환
  String _formatTimeSlot(TimeOfDay timeSlot) {
    final hour = timeSlot.hour.toString().padLeft(2, '0');
    final minute = timeSlot.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // 시간 단위 표시 텍스트
  String _getTimeSlotUnitText(int minutes) {
    if (minutes < 60) {
      return '$minutes분';
    } else {
      return '${minutes ~/ 60}시간';
    }
  }

  // 시간대가 선택되었는지 확인하는 함수
  bool _isTimeSlotSelected(TimeOfDay timeSlot) {
    return selectedTimeSlots.contains(timeSlot);
  }

  @override
  Widget build(BuildContext context) {
    // 시간대를 이른 시간순(오름차순)으로 정렬
    List<TimeOfDay> sortedTimeSlots = List.from(availableTimeSlots);
    sortedTimeSlots.sort((a, b) {
      if (a.hour != b.hour) {
        return a.hour.compareTo(b.hour); // 시간 기준 오름차순
      }
      return a.minute.compareTo(b.minute); // 분 기준 오름차순
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Text(
              '${_getTimeSlotUnitText(timeSlotUnit)} 단위',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedTimeSlots.map((timeSlot) {
            final isSelected = _isTimeSlotSelected(timeSlot);
            return GestureDetector(
              onTap: () => onTimeSlotToggle(timeSlot),
              child: Chip(
                label: Text(
                  _formatTimeSlot(timeSlot),
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
    );
  }
} 