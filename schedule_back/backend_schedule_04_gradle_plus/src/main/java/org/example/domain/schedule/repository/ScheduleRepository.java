package org.example.domain.schedule.repository;

import org.example.domain.schedule.entity.Schedule;
import org.example.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

public interface ScheduleRepository extends JpaRepository<Schedule, Long> {
    List<Schedule> findByUser(User user);
    List<Schedule> findAllByFirebaseUid(String firebaseUid);

    @Query("SELECT s FROM Schedule s WHERE s.user = :user AND " +
           "(LOWER(s.title) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(s.description) LIKE LOWER(CONCAT('%', :q, '%')))" )
    List<Schedule> search(@Param("user") User user, @Param("q") String query);
    
    /**
     * 특정 사용자의 특정 기간과 시간대에 겹치는 개인 일정 수를 계산합니다.
     * 방의 설정 기간 내에 있는 일정만 고려합니다.
     * 부분 겹침도 정확하게 감지하도록 쿼리를 개선했습니다.
     * 
     * @param firebaseUid 사용자 ID
     * @param date 날짜
     * @param startTime 시작 시간
     * @param endTime 종료 시간
     * @param roomStartDate 방 시작일
     * @param roomEndDate 방 종료일
     * @return 겹치는 일정 수
     */
    @Query(value = "SELECT COUNT(*) FROM schedules s " +
           "WHERE s.firebase_uid = :firebaseUid " +
           "AND CAST(s.start_time AS DATE) = :date " +
           "AND (" +
           "    (CAST(s.start_time AS TIME) <= :startTime AND CAST(s.end_time AS TIME) > :startTime) OR " + // 일정이 시간대 시작 전에 시작해서 시간대 내에 끝나는 경우
           "    (CAST(s.start_time AS TIME) >= :startTime AND CAST(s.start_time AS TIME) < :endTime) OR " + // 일정이 시간대 내에 시작하는 경우
           "    (CAST(s.start_time AS TIME) <= :startTime AND CAST(s.end_time AS TIME) >= :endTime)" +      // 일정이 시간대를 완전히 포함하는 경우
           ") " +
           "AND CAST(s.start_time AS DATE) BETWEEN :roomStartDate AND :roomEndDate", 
           nativeQuery = true)
    long countOverlappingSchedulesInDateRange(
            @Param("firebaseUid") String firebaseUid, 
            @Param("date") LocalDate date,
            @Param("startTime") LocalTime startTime,
            @Param("endTime") LocalTime endTime,
            @Param("roomStartDate") LocalDate roomStartDate,
            @Param("roomEndDate") LocalDate roomEndDate);
            
    /**
     * 특정 사용자의 특정 기간 내의 일정을 조회합니다.
     * 
     * @param firebaseUid 사용자 ID
     * @param startDate 시작일
     * @param endDate 종료일
     * @return 해당 기간 내의 일정 목록
     */
    @Query("SELECT s FROM Schedule s WHERE s.firebaseUid = :firebaseUid " +
           "AND CAST(s.startTime AS LocalDate) BETWEEN :startDate AND :endDate")
    List<Schedule> findSchedulesByUserIdAndDateRange(
            @Param("firebaseUid") String firebaseUid,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
