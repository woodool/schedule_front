import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/matching_meeting_create_dialog.dart';
import '../../../../features/schedule/domain/models/schedule.dart';
import '../../../../features/common_pages/meeting_page.dart';

class MatchingRoomResult extends StatelessWidget {
  final Schedule schedule;
  final DateTime confirmedDate;
  final String confirmedTime;
  
  const MatchingRoomResult({
    Key? key,
    required this.schedule,
    required this.confirmedDate,
    this.confirmedTime = '14:00',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          schedule.title,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // 확정된 날짜 표시
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '확정된 날짜',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 280,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(confirmedDate),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          confirmedTime,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0062FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '모든 참가자가 투표를 완료했습니다!',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 하단 버튼들
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 일정 등록 버튼
                  Center(
                    child: SizedBox(
                      width: 275,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 일정 등록 기능 구현
                          // 현재는 주석 처리하고 모임 화면으로 돌아감
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MeetingPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0062FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '일정 등록',
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
                  
                  // 새로운 일정 잡기 버튼
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 275,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          // 기존 제목 유지한 상태로 새로운 일정 잡기 다이얼로그 표시
                          MatchingMeetingCreateDialog.show(
                            context,
                            initialTitle: schedule.title,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '새로운 일정 잡기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 