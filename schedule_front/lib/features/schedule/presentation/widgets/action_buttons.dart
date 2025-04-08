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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onCancelPressed,
          child: Container(
            width: 160,
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
        const SizedBox(width: 35),
        GestureDetector(
          onTap: onSubmitPressed,
          child: Container(
            width: 160,
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