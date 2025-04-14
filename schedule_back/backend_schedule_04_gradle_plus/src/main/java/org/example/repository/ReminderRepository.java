package org.example.repository;

import org.example.entity.Reminder;
import org.example.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;


@Repository
public interface ReminderRepository extends JpaRepository<Reminder, Long> {
    Reminder findByScheduleAndReminderTime(Schedule schedule, LocalDateTime reminderTime);

}

