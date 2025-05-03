import 'package:flutter/material.dart';

enum Priority {
  //none(4, Color(0xFFA5A5A5))
  none(4, Color(0xFFB8B4A3)),
  low(3, Color(0xFFB4E07B)),
  medium(2, Color(0xFFFFF0A3)),
  high(1, Color(0xFFEC7F7F));

  final int value;
  final Color color;
  const Priority(this.value, this.color);

  static Priority fromValue(int? value) {
    if (value == null) return Priority.none;
    return Priority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Priority.none,
    );
  }
} 