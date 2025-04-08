import 'package:flutter/material.dart';
import '../pages/add_schedule_page.dart';

class AddScheduleButton extends StatelessWidget {
  const AddScheduleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddSchedulePage()),
        );
      },
      tooltip: '일정 추가',
      child: const Icon(Icons.add),
    );
  }
} 