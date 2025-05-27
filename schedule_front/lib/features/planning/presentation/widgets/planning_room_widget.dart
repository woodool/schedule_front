import 'package:flutter/material.dart';
import '../controllers/planning_room_controller.dart';

class PlanningRoomWidget extends StatelessWidget {
  final PlanningRoomController controller;
  final Function() onSelectDateRange;
  final Function() onStartPlanningSchedule;

  const PlanningRoomWidget({
    Key? key,
    required this.controller,
    required this.onSelectDateRange,
    required this.onStartPlanningSchedule,
  }) : super(key: key);

  String _formatDateRange() {
    final room = controller.updatedRoom ?? controller.planningRoom;
    return "${room.startDate.month}월 ${room.startDate.day}일 ~ ${room.endDate.month}월 ${room.endDate.day}일";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onSelectDateRange,
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
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: Color(0xFF0062FF),
                ),
                const SizedBox(height: 16),
                const Text(
                  '일정 계획을 시작해보세요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '아래 버튼을 눌러 일정 투표를 시작하세요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 275,
                height: 50,
                child: ElevatedButton(
                  onPressed: onStartPlanningSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0062FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '일정 잡기',
                    style: TextStyle(
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
    );
  }
} 