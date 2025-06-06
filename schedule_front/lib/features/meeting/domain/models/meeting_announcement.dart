import 'package:flutter/material.dart';

class MeetingAnnouncement {
  final int? announcementId;
  String content;
  final int roomId;
  final String createdBy;
  final String? creatorName;
  final DateTime createdAt;

  MeetingAnnouncement({
    this.announcementId,
    required this.roomId,
    required this.content,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'announcementId': announcementId,
      'roomId': roomId,
      'content': content,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MeetingAnnouncement.fromJson(Map<String, dynamic> json) {
    return MeetingAnnouncement(
      announcementId: json['announcementId'] as int?,
      roomId: json['roomId'] as int,
      content: json['content'] as String,
      createdBy: json['createdBy'] as String,
      creatorName: json['creatorName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  MeetingAnnouncement copyWith({
    int? announcementId,
    int? roomId,
    String? content,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
  }) {
    return MeetingAnnouncement(
      announcementId: announcementId ?? this.announcementId,
      roomId: roomId ?? this.roomId,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 