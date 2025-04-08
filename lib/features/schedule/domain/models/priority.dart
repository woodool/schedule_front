import 'package:flutter/material.dart';

enum Priority {
  high(Color(0xFFEC7F7F)),
  medium(Color(0xFFFFF0A3)),
  low(Color(0xFFB4E07B)),
  none(Color(0xFFA5A5A5));

  final Color color;
  const Priority(this.color);
} 