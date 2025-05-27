import 'package:flutter/material.dart';

class PlanningSuggestionVote {
  final int roomId;
  final int suggestionId;
  final String userId;
  final String username;
  final bool voteFlag;
  final DateTime votedAt;

  PlanningSuggestionVote({
    required this.roomId,
    required this.suggestionId,
    required this.userId,
    required this.username,
    required this.voteFlag,
    required this.votedAt,
  });

  factory PlanningSuggestionVote.fromJson(Map<String, dynamic> json) {
    try {
      return PlanningSuggestionVote(
        roomId: json['roomId'] as int? ?? -1,
        suggestionId: json['suggestionId'] as int? ?? -1,
        userId: json['userId'] as String? ?? '',
        username: json['username'] as String? ?? '',
        voteFlag: json['voteFlag'] as bool? ?? false,
        votedAt: json['votedAt'] != null 
          ? DateTime.parse(json['votedAt'] as String)
          : DateTime.now(),
      );
    } catch (e) {
      print('❌ PlanningSuggestionVote 파싱 오류: $e');
      print('📄 원본 데이터: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'suggestionId': suggestionId,
      'userId': userId,
      'username': username,
      'voteFlag': voteFlag,
      'votedAt': votedAt.toIso8601String(),
    };
  }
} 