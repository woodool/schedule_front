import 'package:flutter/material.dart';
import '../controllers/planning_room_controller.dart';

class PlanningWaitingWidget extends StatelessWidget {
  final PlanningRoomController controller;
  final Function() onRetryVoting;

  const PlanningWaitingWidget({
    Key? key,
    required this.controller,
    required this.onRetryVoting,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 전체 참가자 수
    final int totalParticipants = controller.participants.length;
    
    // 투표 완료한 참가자 수
    final int votedParticipants = controller.votedParticipantsCount;
    
    // 아직 투표 진행 중인 참가자 수 계산
    final int inProgressCount = totalParticipants > 0 
        ? totalParticipants - votedParticipants 
        : 0;
    
    // 텍스트 메시지 결정
    String statusMessage;
    if (inProgressCount <= 0) {
      statusMessage = '모든 참가자가 투표를 완료했습니다';
    } else if (inProgressCount == 1) {
      statusMessage = '현재 1명이 아직 투표 진행 중입니다';
    } else {
      statusMessage = '현재 ${inProgressCount}명이 아직 투표 진행 중입니다';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Color(0xFF0062FF),
          ),
          const SizedBox(height: 24),
          const Text(
            '투표가 완료되었습니다',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '다른 참가자들의 투표를 기다리고 있습니다',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextButton.icon(
            onPressed: onRetryVoting,
            icon: const Icon(Icons.replay, color: Colors.grey),
            label: const Text(
              '투표 다시하기',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 