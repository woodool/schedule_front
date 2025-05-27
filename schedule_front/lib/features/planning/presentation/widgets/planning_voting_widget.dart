import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/planning_room.dart';
import '../controllers/planning_room_controller.dart';
import 'planning_calendar_widget.dart';
import 'time_slot_selector_widget.dart';
import 'recommended_dates_widget.dart';

class PlanningVotingWidget extends StatelessWidget {
  final PlanningRoomController controller;
  final Function() onSubmitVotes;

  const PlanningVotingWidget({
    Key? key,
    required this.controller,
    required this.onSubmitVotes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 추천 일자 섹션
          Padding(
            padding: const EdgeInsets.all(16),
            child: RecommendedDatesWidget(
              recommendedDates: controller.recommendedDates,
            ),
          ),
          
          // 선택된 날짜의 가능한 시간대 표시
          if (controller.selectedDay != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TimeSlotSelectorWidget(
                availableTimeSlots: controller.availableTimeSlots,
                selectedTimeSlots: controller.selectedTimeSlots,
                timeSlotUnit: controller.planningRoom.timeSlotUnit,
                onTimeSlotToggle: (timeSlot) {
                  controller.toggleTimeSlot(timeSlot);
                },
              ),
            ),
          
          // 가능한 날짜 선택 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '가능한 날짜${controller.selectedDay != null ? ' (전체보기 가능)' : ''} 달력',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          
          // 캘린더 위젯
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PlanningCalendarWidget(
              focusedDay: controller.focusedDay,
              selectedDay: controller.selectedDay,
              startDate: controller.updatedRoom?.startDate ?? controller.planningRoom.startDate,
              endDate: controller.updatedRoom?.endDate ?? controller.planningRoom.endDate,
              unavailableDates: controller.unavailableDates,
              recommendedDates: controller.recommendedDates,
              onDaySelected: (selectedDay, focusedDay) {
                controller.selectDay(selectedDay, focusedDay);
              },
              onMonthChanged: (focusedDay) {
                controller.changeMonth(focusedDay);
              },
            ),
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
                    onPressed: onSubmitVotes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '투표 등록',
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
      ),
    );
  }
} 