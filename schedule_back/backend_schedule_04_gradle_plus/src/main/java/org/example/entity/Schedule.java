package org.example.entity;

import jakarta.persistence.*;
import lombok.*;

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

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", nullable = true)
    private String description;

    @Column(name = "category_id", nullable = true)
    private Integer categoryId;

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    @Column(name = "recurrence_days", nullable = true)
    private String recurrenceDays;

    @Builder.Default
    @Column(name = "priority", nullable = true)
    private Integer priority = 4;

    @Builder.Default
    @Column(name = "display_on_calendar", nullable = false)
    private Boolean displayOnCalendar = true;

    @Column(name = "reminder_minutes_before", nullable = true)
    private Integer reminderMinutesBefore;

    @Column(name = "reminder_time", nullable = true)
    private LocalDateTime reminderTime;

    @Column(name = "recurrence_start_date", nullable = true)
    private LocalDateTime recurrenceStartDate;

    @Column(name = "recurrence_end_date", nullable = true)
    private LocalDateTime recurrenceEndDate;

    @Column(name = "excluded_dates", nullable = true, columnDefinition = "TEXT")
    private String excludedDates; // 쉼표로 구분된 ISO 날짜 문자열 "2023-10-01,2023-10-08"

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;
} 