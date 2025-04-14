package org.example.repository;

import org.example.entity.Schedule;
import org.example.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;


@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    List<Schedule> findAll();

    // 특정 사용자(firebaseUid)의 일정 중 특정 시간 사이의 일정 조회
    List<Schedule> findByFirebaseUidAndStartTimeBetween(String firebaseUid, LocalDateTime from, LocalDateTime to);

    // To-Do 리스트에서 숨겨지지 않은 일정만 조회
    List<Schedule> findByFirebaseUidAndIsHiddenInToDoFalse(String firebaseUid);

    // 리마인더가 활성화된 일정만 조회
    List<Schedule> findByIsReminderEnabledTrue();

    List<Schedule> findByFirebaseUidAndRemindersIsNotEmpty(String firebaseUid);

    @Query("SELECT s FROM Schedule s " +
            "JOIN s.reminders r " +
            "WHERE s.firebaseUid = :firebaseUid " +
            "AND (s.priority = 1 OR r.minutesBefore IN (5, 10, 15, 20))")
    List<Schedule> findPriorityOrHasAdditionalReminders(@Param("firebaseUid") String firebaseUid);

}
