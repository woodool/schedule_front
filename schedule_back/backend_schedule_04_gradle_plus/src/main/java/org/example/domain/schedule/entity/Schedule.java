package org.example.domain.schedule.entity;

import jakarta.persistence.*;
import lombok.*;
import org.example.domain.user.User;
import java.time.LocalDateTime;

@Entity
@Table(name = "schedules")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Schedule {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "schedule_id")
    private Long id;

    @Column(name = "firebase_uid")
    private String firebaseUid;

    @Column(nullable = false)
    private String title;

    private String description;
    private Integer categoryId;

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    @Column(name = "recurrence_days")
    private String recurrenceDays;

    @Column(name = "recurrence_start_date")
    private LocalDateTime recurrenceStartDate;

    @Column(name = "recurrence_end_date")
    private LocalDateTime recurrenceEndDate;

    @Column(name = "excluded_dates", columnDefinition = "TEXT")
    private String excludedDates; // 쉼표로 구분된 ISO 날짜 문자열 "2023-10-01,2023-10-08"

    @Builder.Default
    private Integer priority = 4;

    @Builder.Default
    @Column(name = "display_on_calendar", nullable = false)
    private Boolean displayOnCalendar = true;

    @Column(name = "reminder_minutes_before")
    private Integer reminderMinutesBefore;

    @Column(name = "reminder_time")
    private LocalDateTime reminderTime;

    @Column(name = "schedule_type")
    @Builder.Default
    private String scheduleType = "PERSONAL"; // "PERSONAL" 또는 "MEETING"

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;
} 