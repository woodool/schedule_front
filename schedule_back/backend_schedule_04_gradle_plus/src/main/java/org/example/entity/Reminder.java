package org.example.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reminder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "schedule_id", nullable = false)
    private Schedule schedule;
    private LocalDateTime reminderTime;
    private int minutesBefore;

    private Integer reminderMinutesBefore;

    public Reminder(Schedule schedule, Integer reminderMinutesBefore, LocalDateTime reminderTime) {
        this.schedule = schedule;
        this.reminderMinutesBefore = reminderMinutesBefore;
        this.reminderTime = reminderTime;
    }

}

