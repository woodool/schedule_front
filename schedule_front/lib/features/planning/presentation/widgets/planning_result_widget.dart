import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/planning_final.dart';
import 'package:go_router/go_router.dart';

class PlanningResultWidget extends StatelessWidget {
  final PlanningFinal finalSchedule;
  final bool isRegistering;
  final bool isRegistered;
  final String message;
  final VoidCallback onRegisterToMySchedule;

  const PlanningResultWidget({
    Key? key,
    required this.finalSchedule,
    required this.isRegistering,
    required this.isRegistered,
    required this.message,
    required this.onRegisterToMySchedule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 시간 형식 변환
    final formattedStartTime = DateFormat('HH:mm').format(
      DateTime(2022, 1, 1, 
        finalSchedule.startTime.hour, 
        finalSchedule.startTime.minute
      )
    );
    
    final formattedEndTime = DateFormat('HH:mm').format(
      DateTime(2022, 1, 1, 
        finalSchedule.endTime.hour, 
        finalSchedule.endTime.minute
      )
    );
    
    final timeRange = '$formattedStartTime - $formattedEndTime';

    return Column(
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
                        DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(finalSchedule.finalDate),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeRange,
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
                  '투표를 통해 최종 확정된 일정입니다!',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isRegistered ? Colors.green : Colors.red,
                      ),
                      textAlign: TextAlign.center,
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
                      onPressed: isRegistering || isRegistered 
                          ? null 
                          : onRegisterToMySchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRegistered 
                            ? Colors.grey 
                            : const Color(0xFF0062FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isRegistering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : Text(
                              isRegistered ? '등록 완료' : '내 일정에 등록하기',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                
                // 모임 화면으로 돌아가기 버튼
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 275,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        context.go('/meeting');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '모임 화면으로 돌아가기',
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
    );
  }
} 