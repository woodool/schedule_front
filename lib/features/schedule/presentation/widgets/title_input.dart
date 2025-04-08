import 'package:flutter/material.dart';

class TitleInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const TitleInput({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 335,
      height: 60,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 16,
            height: 1.4,
            letterSpacing: -0.025,
            color: Colors.black,
            fontFamily: 'Pretendard',
          ),
          decoration: const InputDecoration(
            hintText: '제목',
            hintStyle: TextStyle(
              fontSize: 16,
              height: 1.4,
              letterSpacing: -0.025,
              color: Color(0xFF767676),
              fontFamily: 'Pretendard',
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
} 