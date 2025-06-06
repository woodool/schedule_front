import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddScheduleButton extends StatelessWidget {
  const AddScheduleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        context.push('/add-schedule');
      },
      tooltip: '일정 추가',
      child: const Icon(Icons.add),
    );
  }
} 