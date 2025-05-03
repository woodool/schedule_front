import 'package:flutter/material.dart';

enum RecurrenceDeleteMode {
  single,      // 이 일정만 삭제
  thisAndFuture, // 이 일정 및 향후 모든 일정 삭제
  allSeries    // 전체 시리즈 삭제
}

class RecurrenceDeleteDialog extends StatelessWidget {
  final bool isRecurring; // 반복 일정인지 여부

  const RecurrenceDeleteDialog({
    super.key, 
    this.isRecurring = false,
  });

  @override
  Widget build(BuildContext context) {
    // 반복 일정이 아니면 단순 확인 다이얼로그 표시
    if (!isRecurring) {
      return AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }

    // 반복 일정인 경우 삭제 범위 선택 다이얼로그 표시
    return AlertDialog(
      title: const Text('반복 일정 삭제'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이 반복 일정을 어떻게 삭제하시겠습니까?'),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('이 일정만 삭제'),
            subtitle: const Text('현재 선택한 날짜의 일정만 삭제합니다'),
            onTap: () {
              Navigator.of(context).pop(RecurrenceDeleteMode.single);
            },
          ),
          ListTile(
            title: const Text('이 일정 및 향후 모든 일정 삭제'),
            subtitle: const Text('선택한 날짜 및 향후 모든 일정을 삭제합니다'),
            onTap: () {
              Navigator.of(context).pop(RecurrenceDeleteMode.thisAndFuture);
            },
          ),
          ListTile(
            title: const Text('전체 시리즈 삭제'),
            subtitle: const Text('모든 반복 일정을 삭제합니다'),
            onTap: () {
              Navigator.of(context).pop(RecurrenceDeleteMode.allSeries);
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