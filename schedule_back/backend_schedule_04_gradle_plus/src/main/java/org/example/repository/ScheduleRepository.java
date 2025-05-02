package org.example.repository;

import org.example.entity.Schedule;
import org.example.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, Long> {
    List<Schedule> findByUser(User user);
    
    // 검색 기능: 제목이나 설명에 검색어가 포함된 일정을 찾기
    @Query("SELECT s FROM Schedule s WHERE s.user = :user AND (LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(s.description) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<Schedule> searchSchedules(@Param("user") User user, @Param("query") String query);
} 