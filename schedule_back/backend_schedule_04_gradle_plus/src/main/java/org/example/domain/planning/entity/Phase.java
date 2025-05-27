package org.example.domain.planning.entity;

public enum Phase {
    ROOM,   // 일정잡기 방 기본 상태 (수정 가능)
    VOTING, // 가능한 시간대 투표 중
    WAITING,// 본인 투표 완료 – 대기 화면
    RESULT  // 최종 일정 확정
}