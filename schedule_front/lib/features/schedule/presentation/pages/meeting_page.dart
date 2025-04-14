import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  bool _isScheduleSelected = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // 상태바와 하단 패딩을 제외한 실제 사용 가능한 높이 계산
    final availableHeight = screenHeight - topPadding - bottomPadding;
    // 이미지 높이 계산 (화면 너비의 33%)
    final imageHeight = size.width * 0.33;
    // 이미지 아래부터 시작하는 배경 높이
    final backgroundHeight = availableHeight * 0.75;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40), // 상단 여백 조정
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 335,
                      maxHeight: imageHeight,
                    ),
                    child: Image.asset(
                      'assets/images/meetingimage.png',
                      width: size.width - 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: size.width,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDFE6FF),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            width: size.width - 40,
                            constraints: const BoxConstraints(maxWidth: 335),
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFE6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isScheduleSelected = true;
                                        });
                                        // TODO: 일정 잡기 리스트 불러오기
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _isScheduleSelected ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '일정 잡기',
                                            style: TextStyle(
                                              fontSize: 13, // 텍스트 크기 조정
                                              fontWeight: _isScheduleSelected ? FontWeight.w600 : FontWeight.w400,
                                              height: 1.4,
                                              letterSpacing: -0.025,
                                              color: _isScheduleSelected ? Colors.black : const Color(0xFF505050),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 1),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isScheduleSelected = false;
                                        });
                                        // TODO: 모임 리스트 불러오기
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: !_isScheduleSelected ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '모임',
                                            style: TextStyle(
                                              fontSize: 13, // 텍스트 크기 조정
                                              fontWeight: !_isScheduleSelected ? FontWeight.w600 : FontWeight.w400,
                                              height: 1.4,
                                              letterSpacing: -0.025,
                                              color: !_isScheduleSelected ? Colors.black : const Color(0xFF505050),
                                            ),
                                          ),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AddButton(
        items: [
          AddButtonItem(
            label: '일정 잡기',
            iconPath: 'assets/images/bookmark.png',
            onPressed: () {
              // TODO: 일정 잡기 기능 구현
            },
            description: '등록된 일정을 기반으로 최적의 날을 잡아드립니다',
          ),
          AddButtonItem(
            label: '모임 만들기',
            iconPath: 'assets/images/makemeeting.png',
            onPressed: () {
              // TODO: 모임 만들기 기능 구현
            },
            description: '모임을 만들어 쉽게 공지와 일정을 공유해 보세요',
          ),
          AddButtonItem(
            label: '초대코드 입력',
            iconPath: 'assets/images/link.png',
            onPressed: () {
              // TODO: 초대코드 입력 기능 구현
            },
            description: '일정 잡기 또는 모임 초대코드를 입력해 참가해보세요',
          ),
        ],
      ),
    );
  }
} 