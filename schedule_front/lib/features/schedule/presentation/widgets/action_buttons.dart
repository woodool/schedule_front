import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback? onCancelPressed;
  final VoidCallback? onSubmitPressed;
  final String cancelText;
  final String submitText;

  const ActionButtons({
    super.key,
    this.onCancelPressed,
    this.onSubmitPressed,
    this.cancelText = '취소',
    this.submitText = '등록',
  });

  @override
  Widget build(BuildContext context) {
    // 화면 너비 가져오기
    final screenWidth = MediaQuery.of(context).size.width;
    // 버튼 너비 계산 - 여백과 사이 간격 고려
    final buttonWidth = (screenWidth - 100) / 2; // 양쪽 여백과 중간 간격을 고려한 너비

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onCancelPressed,
          child: Container(
            width: buttonWidth,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              cancelText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.025,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20), // 중간 간격 줄임
        GestureDetector(
          onTap: onSubmitPressed,
          child: Container(
            width: buttonWidth,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              submitText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.025,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 