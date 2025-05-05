import 'package:flutter/material.dart';
import '../../domain/models/Recurrence_option.Dart';

class RecurrenceDeleteDialog extends StatelessWidget {
  final bool isRecurring;

  const RecurrenceDeleteDialog({
    Key? key,
    required this.isRecurring,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isRecurring) {
      // 단순 확인 다이얼로그
      return AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }

    // 반복 일정 삭제 옵션 다이얼로그
    return AlertDialog(
      title: const Text('반복 일정 삭제'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('이 반복 일정을 어떻게 삭제하시겠습니까?'),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('이 일정만'),
            subtitle: const Text('현재 선택한 날짜의 일정만 삭제합니다'),
            onTap: () {
              Navigator.pop(context, RecurrenceDeleteMode.SINGLE);
            },
          ),
          ListTile(
            title: const Text('이 일정 및 향후 일정'),
            subtitle: const Text('현재 선택한 날짜 포함, 이후의 모든 반복 일정을 삭제합니다'),
            onTap: () {
              Navigator.pop(context, RecurrenceDeleteMode.FUTURE);
            },
          ),
          ListTile(
            title: const Text('모든 반복 일정'),
            subtitle: const Text('모든 반복 일정을 삭제합니다'),
            onTap: () {
              Navigator.pop(context, RecurrenceDeleteMode.ALL);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }
}