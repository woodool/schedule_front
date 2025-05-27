package org.example.domain.common.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.example.domain.planning.repository.PlanningFinalRepository;
import org.example.domain.planning.repository.PlanningParticipantRepository;
import org.example.domain.planning.repository.PlanningRoomRepository;
import org.example.domain.schedule.repository.ScheduleRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * 사용자 일정 관리 서비스 구현 클래스
 * 사용자의 일정을 관리하고 특정 시간대의 가용성을 확인하는 기능을 제공합니다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserCalendarServiceImpl implements UserCalendarService {

    private final PlanningFinalRepository planningFinalRepository;
    private final PlanningParticipantRepository planningParticipantRepository;
    private final PlanningRoomRepository planningRoomRepository;
    private final ScheduleRepository scheduleRepository;

    /**
     * 특정 사용자의 특정 날짜와 시간대가 비어있는지 확인합니다.
     * 사용자의 개인 일정만 확인하여 해당 시간대에 겹치는 일정이 있는지 검사합니다.
     * 방 설정 기간 내의 일정만 조회합니다.
     * 
     * @param userId 사용자 ID
     * @param date 확인할 날짜
     * @param startTime 시작 시간
     * @param endTime 종료 시간
     * @return 해당 시간대가 비어있으면 true, 일정이 있으면 false
     */
    @Override
    public boolean isTimeSlotFree(String userId, LocalDate date, LocalTime startTime, LocalTime endTime) {
        
        // 방 설정 기간 기본값 (시작일과 종료일)
        LocalDate roomStartDate = date;
        LocalDate roomEndDate = date.plusDays(30); // 기본 범위로 30일 설정
        
        // 방 설정 기간 내의 일정만 확인하기 위해 새로운 메서드 사용
        long scheduleOverlaps = scheduleRepository.countOverlappingSchedulesInDateRange(
                userId, date, startTime, endTime, roomStartDate, roomEndDate);
        
        // 개인 일정과 충돌이 없어야 true 반환
        return scheduleOverlaps == 0;
    }
} 