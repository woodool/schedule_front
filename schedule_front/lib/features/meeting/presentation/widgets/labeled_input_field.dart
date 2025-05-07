import 'package:flutter/material.dart';

class LabeledInputField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isRequired;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry contentPadding;

  const LabeledInputField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 레이블
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          
          // 내용 (패딩 적용)
          Padding(
            padding: contentPadding,
            child: child,
          ),
        ],
      ),
    );
  }
}

// 입력 컨테이너 스타일 위젯
class InputContainer extends StatelessWidget {
  final Widget child;
  final double? height;

  const InputContainer({
    super.key,
    required this.child,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: child,
    );
  }
} 