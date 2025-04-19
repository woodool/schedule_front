import 'package:flutter/material.dart';

enum Priority {
  high(Color(0xFFEC7F7F)),
  medium(Color(0xFFFFF0A3)),
  low(Color(0xFFB4E07B)),
  none(Color(0xFFA5A5A5));

  final Color color;
  const Priority(this.color);

  /// DB 숫자 → Priority 변환
  static Priority fromInt(int value) {
    switch (value) {
      case 1:
        return Priority.high;
      case 2:
        return Priority.medium;
      case 3:
        return Priority.low;
      case 4:
      default:
        return Priority.none;
    }
  }

  /// Priority → DB 숫자 변환
  int toInt() {
    switch (this) {
      case Priority.high:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.low:
        return 3;
      case Priority.none:
        return 4;
    }
  }
} 