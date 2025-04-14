import 'package:flutter/material.dart';
import 'package:schedule/features/schedule/presentation/widgets/add_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('일정 관리'),
      ),
      body: const Center(
        child: Text('홈 화면'),
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
            label: '리마인더 추가',
            iconPath: 'assets/images/reminder.png',
            onPressed: () {
              Navigator.pushNamed(context, '/add_reminder');
            },
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