package org.example.domain.meeting.repository;

import org.example.domain.meeting.entity.MeetingSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface MeetingScheduleRepository extends JpaRepository<MeetingSchedule, Integer> {
    
    List<MeetingSchedule> findByRoomId(Integer roomId);
    
    @Query("SELECT ms FROM MeetingSchedule ms WHERE ms.roomId = :roomId AND ms.scheduleDate BETWEEN :startDate AND :endDate")
    List<MeetingSchedule> findByRoomIdAndDateRange(
            @Param("roomId") Integer roomId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    @Query("SELECT ms FROM MeetingSchedule ms JOIN MeetingParticipant mp ON ms.roomId = mp.roomId " +
            "WHERE mp.userId = :userId AND ms.scheduleDate BETWEEN :startDate AND :endDate")
    List<MeetingSchedule> findUserMeetingSchedulesByDateRange(
            @Param("userId") String userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    void deleteByRoomId(Integer roomId);
} 