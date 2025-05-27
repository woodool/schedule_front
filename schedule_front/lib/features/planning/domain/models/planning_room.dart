enum RoomPhase {
  ROOM,    // 일정잡기 방 기본 상태 (수정 가능)
  VOTING,  // 가능한 시간대 투표 중
  WAITING, // 본인 투표 완료 – 대기 화면
  RESULT;  // 최종 일정 확정

  @override
  String toString() {
    return name;  // enum의 이름을 문자열로 반환
  }
}

class PlanningRoom {
  final int? roomId;
  final String? photoUrl;
  final String roomName;
  final DateTime startDate;
  final DateTime endDate;
  final int? categoryId;
  final int? priority;
  final int timeSlotUnit;
  final String? inviteCode;
  final String? createdBy;
  final DateTime? createdAt;
  final RoomPhase phase;  // 신규 필드

  PlanningRoom({
    this.roomId,
    this.photoUrl,
    required this.roomName,
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.priority,
    required this.timeSlotUnit,
    this.inviteCode,
    this.createdBy,
    this.createdAt,
    this.phase = RoomPhase.ROOM,  // 기본값
  });

  factory PlanningRoom.fromJson(Map<String, dynamic> json) {
    // phase 문자열을 enum 값으로 변환
    RoomPhase _parsePhase(String? raw) {
      switch (raw) {
        case 'VOTING': return RoomPhase.VOTING;
        case 'WAITING': return RoomPhase.WAITING;
        case 'RESULT':  return RoomPhase.RESULT;
        case 'ROOM':
        default:        return RoomPhase.ROOM;
      }
    }

    return PlanningRoom(
      roomId: json['roomId'] as int?,
      photoUrl: json['photoUrl'] as String?,
      roomName: json['roomName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      categoryId: json['categoryId'] as int?,
      priority: json['priority'] as int?,
      timeSlotUnit: json['timeSlotUnit'] as int,
      inviteCode: json['inviteCode'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      phase: _parsePhase(json['phase'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    String _phaseToString(RoomPhase p) {
      switch (p) {
        case RoomPhase.VOTING: return 'VOTING';
        case RoomPhase.WAITING: return 'WAITING';
        case RoomPhase.RESULT: return 'RESULT';
        case RoomPhase.ROOM:
        default: return 'ROOM';
      }
    }

    final data = <String, dynamic>{
      'roomName': roomName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'timeSlotUnit': timeSlotUnit,
      'phase': _phaseToString(phase),
    };
    if (roomId != null) data['roomId'] = roomId;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (priority != null) data['priority'] = priority;
    if (inviteCode != null) data['inviteCode'] = inviteCode;
    if (createdBy != null) data['createdBy'] = createdBy;
    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    return data;
  }

  PlanningRoom copyWith({
    int? roomId,
    String? photoUrl,
    String? roomName,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    int? priority,
    int? timeSlotUnit,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
    RoomPhase? phase,
  }) {
    return PlanningRoom(
      roomId: roomId ?? this.roomId,
      photoUrl: photoUrl ?? this.photoUrl,
      roomName: roomName ?? this.roomName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      timeSlotUnit: timeSlotUnit ?? this.timeSlotUnit,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      phase: phase ?? this.phase,
    );
  }
}