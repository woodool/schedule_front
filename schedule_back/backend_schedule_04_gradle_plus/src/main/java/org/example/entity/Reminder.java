package org.example.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Reminder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "reminder_id")
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    @Column(name = "recurrence_days", nullable = false)
    private String recurrenceDays;

    @Column(name = "reminder_minutes_before", nullable = true)
    private Integer reminderMinutesBefore;

    @Column(name = "reminder_time", nullable = false)
    private LocalDateTime reminderTime;  // 실제 알림 시간

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;     // 활성화 여부 (기본 true)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "firebase_uid")
    private User user;
}
