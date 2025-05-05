package org.example.domain.schedule.repository;

import org.example.domain.schedule.entity.Schedule;
import org.example.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface ScheduleRepository extends JpaRepository<Schedule, Long> {
    List<Schedule> findByUser(User user);

    @Query("SELECT s FROM Schedule s WHERE s.user = :user AND " +
           "(LOWER(s.title) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(s.description) LIKE LOWER(CONCAT('%', :q, '%')))" )
    List<Schedule> search(@Param("user") User user, @Param("q") String query);
}
