import 'package:flutter/material.dart';
import 'planning_suggestion_vote.dart';

class PlanningTimeSuggestion {
  final int? suggestionId;
  final int roomId;
  final DateTime suggestionDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAllFree;
  final int freeCount;
  final int voteCount;
  final DateTime createdAt;
  final bool? hasVoted;
  final List<PlanningSuggestionVote> votes;

  PlanningTimeSuggestion({
    this.suggestionId,
    required this.roomId,
    required this.suggestionDate,
    required this.startTime,
    required this.endTime,
    required this.isAllFree,
    required this.freeCount,
    this.voteCount = 0,
    required this.createdAt,
    this.hasVoted,
    this.votes = const [],
  });

  factory PlanningTimeSuggestion.fromJson(Map<String, dynamic> json) {
    try {
      // suggestionDate는 '2024-05-15' 형식
      final String dateStr = json['suggestionDate'] as String;
      final DateTime date = DateTime.parse(dateStr);
      
      // startTime과 endTime은 'HH:MM:SS' 형식
      final String startTimeStr = json['startTime'] as String;
      final String endTimeStr = json['endTime'] as String;
      
      final startTimeParts = startTimeStr.split(':');
      final endTimeParts = endTimeStr.split(':');
      
      final startTime = TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      );
      
      final endTime = TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      );
      
      return PlanningTimeSuggestion(
        suggestionId: json['suggestionId'] as int?,
        roomId: json['roomId'] as int,
        suggestionDate: date,
        startTime: startTime,
        endTime: endTime,
        isAllFree: json['isAllFree'] as bool,
        freeCount: json['freeCount'] as int,
        voteCount: json['voteCount'] as int? ?? 0,
        createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
        hasVoted: json['hasVoted'] as bool?,
        votes: (json['votes'] as List<dynamic>?)
            ?.map((e) => PlanningSuggestionVote.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestionId': suggestionId,
      'roomId': roomId,
      'suggestionDate': suggestionDate.toIso8601String(),
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      'freeCount': freeCount,
      'isAllFree': isAllFree,
      'createdAt': createdAt.toIso8601String(),
      'voteCount': voteCount,
      'votes': votes.map((e) => e.toJson()).toList(),
    };
  }

  // 가독성 좋은 문자열 반환 - 날짜 및 시간 표시용
  String getDateTimeDisplay() {
    final dateStr = '${suggestionDate.year}년 ${suggestionDate.month}월 ${suggestionDate.day}일';
    final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr $startTimeStr ~ $endTimeStr';
  }
  
  // 시간만 표시
  String getTimeDisplay() {
    final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    
    return '$startTimeStr ~ $endTimeStr';
  }
  
  // 날짜만 표시
  String getDateDisplay() {
    return '${suggestionDate.year}년 ${suggestionDate.month}월 ${suggestionDate.day}일';
  }
  
  // 요일 반환 (한국어)
  String getWeekdayDisplay() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayIndex = suggestionDate.weekday - 1; // 1-7 -> 0-6
    return weekdays[weekdayIndex];
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlanningTimeSuggestion) return false;
    
    // 같은 날짜와 시간인지 비교
    return other.suggestionDate.year == suggestionDate.year &&
           other.suggestionDate.month == suggestionDate.month &&
           other.suggestionDate.day == suggestionDate.day &&
           other.startTime.hour == startTime.hour &&
           other.startTime.minute == startTime.minute;
  }
  
  @override
  int get hashCode => 
    suggestionDate.hashCode ^ 
    startTime.hour.hashCode ^ 
    startTime.minute.hashCode;
} 