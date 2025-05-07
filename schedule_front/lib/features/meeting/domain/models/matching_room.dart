import 'package:flutter/material.dart';

/// 매칭 룸 정보를 저장하는 모델 클래스
class MatchingRoom {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> recommendedDates;
  final List<DateTime> unavailableDates;
  final int participantCount;
  final List<ParticipantVote>? votes;

  MatchingRoom({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.recommendedDates = const [],
    this.unavailableDates = const [],
    this.participantCount = 0,
    this.votes,
  });
}

/// 참가자의 투표 정보
class ParticipantVote {
  final String userId;
  final String userName;
  final List<VoteTimeSlot> availableTimeSlots;

  ParticipantVote({
    required this.userId,
    required this.userName,
    this.availableTimeSlots = const [],
  });
}

/// 투표한 시간대 정보
class VoteTimeSlot {
  final DateTime date;
  final TimeOfDay time;

  VoteTimeSlot({
    required this.date,
    required this.time,
  });
} 