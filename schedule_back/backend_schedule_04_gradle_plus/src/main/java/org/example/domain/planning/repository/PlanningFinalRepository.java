package org.example.domain.planning.repository;

import org.example.domain.planning.entity.PlanningFinal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

public interface PlanningFinalRepository extends JpaRepository<PlanningFinal, Integer> {
    
    Optional<PlanningFinal> findByRoomId(Integer roomId);
    
    @Query("SELECT pf FROM PlanningFinal pf JOIN PlanningParticipant pp ON pf.roomId = pp.roomId " +
           "WHERE pp.userId = :userId")
    List<PlanningFinal> findByParticipantId(@Param("userId") String userId);
    
    @Query("SELECT pf FROM PlanningFinal pf JOIN PlanningParticipant pp ON pf.roomId = pp.roomId " +
           "WHERE pp.userId = :userId AND pf.finalDate BETWEEN :startDate AND :endDate")
    List<PlanningFinal> findByParticipantIdAndDateRange(
            @Param("userId") String userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
            
    /**
     * 특정 사용자의 특정 날짜와 시간대에 겹치는 일정 수를 계산합니다.
     * 
     * @param userId 사용자 ID
     * @param date 날짜
     * @param startTime 시작 시간
     * @param endTime 종료 시간
     * @return 겹치는 일정 수
     */
    @Query("SELECT COUNT(pf) FROM PlanningFinal pf JOIN PlanningParticipant pp ON pf.roomId = pp.roomId " +
           "WHERE pp.userId = :userId AND pf.finalDate = :date " +
           "AND ((pf.startTime <= :endTime AND pf.endTime >= :startTime))")
    long countOverlappingPlannings(
            @Param("userId") String userId, 
            @Param("date") LocalDate date,
            @Param("startTime") LocalTime startTime,
            @Param("endTime") LocalTime endTime);
} 