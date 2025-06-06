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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '일정 삭제',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: const Text(
          '이 일정을 삭제하시겠습니까?',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
          ),
        ],
      );
    }

    // 반복 일정 삭제 옵션 다이얼로그
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        '반복 일정 삭제',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '이 반복 일정을 어떻게 삭제하시겠습니까?',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text(
              '이 일정만',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            subtitle: const Text(
              '현재 선택한 날짜의 일정만 삭제합니다',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            onTap: () {
              Navigator.pop(context, RecurrenceDeleteMode.SINGLE);
            },
          ),
          ListTile(
            title: const Text(
              '이 일정 및 향후 일정',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            subtitle: const Text(
              '현재 선택한 날짜 포함, 이후의 모든 반복 일정을 삭제합니다',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            onTap: () {
              Navigator.pop(context, RecurrenceDeleteMode.FUTURE);
            },
          ),
          ListTile(
            title: const Text(
              '모든 반복 일정',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            subtitle: const Text(
              '모든 반복 일정을 삭제합니다',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            onTap: () {
              Navigator.pop(context, RecurrenceDeleteMode.ALL);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '취소',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}