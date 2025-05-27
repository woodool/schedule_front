import 'package:flutter/material.dart';

class PlanningFinal {
  final int? finalId;
  final int roomId;
  final DateTime finalDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime? finalizedAt;
  final String? roomName;

  PlanningFinal({
    this.finalId,
    required this.roomId,
    required this.finalDate,
    required this.startTime,
    required this.endTime,
    this.finalizedAt,
    this.roomName,
  });

  factory PlanningFinal.fromJson(Map<String, dynamic> json) {
    // 시간 문자열을 TimeOfDay로 변환하는 함수
    TimeOfDay parseTimeString(String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return PlanningFinal(
      finalId: json['finalId'],
      roomId: json['roomId'],
      finalDate: DateTime.parse(json['finalDate']),
      startTime: parseTimeString(json['startTime']),
      endTime: parseTimeString(json['endTime']),
      finalizedAt: json['finalizedAt'] != null 
          ? DateTime.parse(json['finalizedAt']) 
          : null,
      roomName: json['roomName'],
    );
  }

  Map<String, dynamic> toJson() {
    // TimeOfDay를 문자열로 변환하는 함수
    String formatTimeOfDay(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return {
      'finalId': finalId,
      'roomId': roomId,
      'finalDate': finalDate.toIso8601String().split('T')[0],
      'startTime': formatTimeOfDay(startTime),
      'endTime': formatTimeOfDay(endTime),
      'finalizedAt': finalizedAt?.toIso8601String(),
      'roomName': roomName,
    };
  }
} 