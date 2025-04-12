import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';

class MeetingPage extends StatelessWidget {
  const MeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Text('모임 화면'),
      ),
      floatingActionButton: AddButton(
        items: [
          AddButtonItem(
            label: '초대코드 입력',
            iconPath: 'assets/images/link.png',
            onPressed: () {
              // TODO: 초대코드 입력 기능 구현
            },
            description: '일정 잡기 또는 모임 초대코드를 입력해 참가해보세요',
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
            label: '일정 잡기',
            iconPath: 'assets/images/bookmark.png',
            onPressed: () {
              // TODO: 일정 잡기 기능 구현
            },
            description: '등록된 일정을 기반으로 최적의 날을 잡아드립니다',
          ),
        ],
      ),
    );
  }
} 