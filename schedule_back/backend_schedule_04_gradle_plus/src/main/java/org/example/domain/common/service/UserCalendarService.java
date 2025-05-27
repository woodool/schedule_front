package org.example.domain.common.service;

import java.time.LocalDate;
import java.time.LocalTime;

/**
 * 사용자 일정 관리 서비스 인터페이스
 * 사용자의 일정을 관리하고 특정 시간대의 가용성을 확인하는 기능을 제공합니다.
 */
public interface UserCalendarService {

    /**
     * 특정 사용자의 특정 날짜와 시간대가 비어있는지 확인합니다.
     * 
     * @param userId 사용자 ID
     * @param date 확인할 날짜
     * @param startTime 시작 시간
     * @param endTime 종료 시간
     * @return 해당 시간대가 비어있으면 true, 일정이 있으면 false
     */
    boolean isTimeSlotFree(String userId, LocalDate date, LocalTime startTime, LocalTime endTime);
} 