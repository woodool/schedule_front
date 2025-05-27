package org.example.domain.meeting.repository;

import org.example.domain.meeting.entity.MeetingScheduleException;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MeetingScheduleExceptionRepository extends JpaRepository<MeetingScheduleException, Integer> {
    
    List<MeetingScheduleException> findByScheduleId(Integer scheduleId);
    
    Optional<MeetingScheduleException> findByScheduleIdAndExceptionDate(Integer scheduleId, LocalDate exceptionDate);
    
    @Query("SELECT mse FROM MeetingScheduleException mse WHERE mse.scheduleId = :scheduleId AND mse.exceptionDate BETWEEN :startDate AND :endDate")
    List<MeetingScheduleException> findByScheduleIdAndDateRange(
            @Param("scheduleId") Integer scheduleId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    void deleteByScheduleId(Integer scheduleId);
} 