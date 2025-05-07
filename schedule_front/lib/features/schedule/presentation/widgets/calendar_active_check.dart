import 'package:flutter/material.dart';
import 'action_buttons.dart';
import 'dart:math' as math;

class CalendarActiveCheckWidget extends StatelessWidget {
  final List<Map<String, dynamic>> scheduleItems;
  
  const CalendarActiveCheckWidget({
    super.key, 
    required this.scheduleItems,
  });

  // 다이얼로그로 표시하는 정적 메서드
  static Future<List<Map<String, dynamic>>?> show(
    BuildContext context,
    List<Map<String, dynamic>> scheduleItems,
  ) {
    return showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: CalendarActiveCheckWidget(scheduleItems: scheduleItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 토글 상태에 따라 항목 필터링
    final enabledItems = scheduleItems.where((item) => item['isEnabled'] == true).toList();
    final disabledItems = scheduleItems.where((item) => item['isEnabled'] == false).toList();
    
    // 화면 크기 계산
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.8; // 최대 높이 제한 - 더 많은 공간 확보
    
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: maxHeight,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞춤
          children: [
            // 헤더
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '일정 확인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // 메인 콘텐츠
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽: 달력 미표시 항목들
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            '달력 미표시',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (disabledItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              '항목 없음',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF767676),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(disabledItems.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  disabledItems[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF767676),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ),
                      ],
                    ),
                  ),
                  
                  // 중앙 구분선
                  Container(
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  
                  // 오른쪽: 달력 표시 항목들
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            '달력 표시',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (enabledItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              '항목 없음',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(enabledItems.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  enabledItems[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ActionButtons(
                onCancelPressed: () {
                  Navigator.of(context).pop();
                },
                onSubmitPressed: () {
                  // 최종 등록 처리
                  Navigator.of(context).pop(scheduleItems);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 