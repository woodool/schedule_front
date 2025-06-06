import 'package:flutter/material.dart';

class MeetingRoom {
  final int? roomId;
  final String meetingName;
  final String? photoUrl;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime recurrenceStart;
  final DateTime recurrenceEnd;
  final TimeOfDay timeOfDay;
  final int categoryId;
  final String? categoryName;
  final int capacity;
  final String description;
  final String? inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final int participantCount;
  String? memo;
  String? announcement;

  MeetingRoom({
    this.roomId,
    required this.meetingName,
    this.photoUrl,
    required this.startDate,
    required this.endDate,
    required this.recurrenceStart,
    required this.recurrenceEnd,
    required this.timeOfDay,
    required this.categoryId,
    this.categoryName,
    required this.capacity,
    required this.description,
    this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    this.participantCount = 0,
    this.memo,
    this.announcement,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'meetingName': meetingName,
      'photoUrl': photoUrl,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'recurrenceStart': recurrenceStart.toIso8601String().split('T')[0],
      'recurrenceEnd': recurrenceEnd.toIso8601String().split('T')[0],
      'timeOfDay': '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}:00',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'capacity': capacity,
      'description': description,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'participantCount': participantCount,
      'memo': memo,
      'announcement': announcement,
    };
  }

  factory MeetingRoom.fromJson(Map<String, dynamic> json) {
    return MeetingRoom(
      roomId: json['roomId'],
      meetingName: json['meetingName'],
      photoUrl: json['photoUrl'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      recurrenceStart: DateTime.parse(json['recurrenceStart']),
      recurrenceEnd: DateTime.parse(json['recurrenceEnd']),
      timeOfDay: _parseTimeOfDay(json['timeOfDay']),
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      capacity: json['capacity'],
      description: json['description'],
      inviteCode: json['inviteCode'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      participantCount: json['participantCount'],
      memo: json['memo'],
      announcement: json['announcement'],
    );
  }

  MeetingRoom copyWith({
    int? roomId,
    String? meetingName,
    String? photoUrl,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? recurrenceStart,
    DateTime? recurrenceEnd,
    TimeOfDay? timeOfDay,
    int? categoryId,
    String? categoryName,
    int? capacity,
    String? description,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
    int? participantCount,
    String? memo,
    String? announcement,
  }) {
    return MeetingRoom(
      roomId: roomId ?? this.roomId,
      meetingName: meetingName ?? this.meetingName,
      photoUrl: photoUrl ?? this.photoUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recurrenceStart: recurrenceStart ?? this.recurrenceStart,
      recurrenceEnd: recurrenceEnd ?? this.recurrenceEnd,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      participantCount: participantCount ?? this.participantCount,
      memo: memo ?? this.memo,
      announcement: announcement ?? this.announcement,
    );
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
} 