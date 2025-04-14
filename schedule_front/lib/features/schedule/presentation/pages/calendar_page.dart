import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Text('캘린더 화면'),
      ),
      floatingActionButton: AddButton(
        items: [
          AddButtonItem(
            label: '사진으로 일정 추가',
            iconPath: 'assets/images/image.png',
            onPressed: () {
              // TODO: 사진으로 일정 추가 기능 구현
            },
          ),
          AddButtonItem(
            label: '일정 자동 배치',
            iconPath: 'assets/images/list.png',
            onPressed: () {
              // TODO: 일정 자동 배치 기능 구현
            },
            description: '여러 개의 일정을 일정표에 맞춰 배치 해드립니다',
          ),
          AddButtonItem(
            label: '일정 추가',
            iconPath: 'assets/images/schedule.png',
            onPressed: () {
              Navigator.pushNamed(context, '/add_schedule');
            },
          ),

        ],
      ),
    );
  }
} 