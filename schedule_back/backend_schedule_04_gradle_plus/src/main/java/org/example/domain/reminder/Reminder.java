package org.example.domain.reminder;

import jakarta.persistence.*;
import lombok.*;
import org.example.domain.user.User;

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

    @Column(name = "reminder_title", nullable = false)
    private String reminderTitle;

    @Column(name = "recurrence_days", nullable = false)
    private String recurrenceDays;

    @Column(name = "reminder_minutes_before", nullable = true)
    private Integer reminderMinutesBefore;

    @Column(name = "reminder_time", nullable = false)
    private LocalDateTime reminderTime;  // 실제 알림 시간

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;     // 활성화 여부 (기본 true)

    @Column(name = "checked_date", nullable = true)
    private LocalDateTime checkedDate;   // 체크된 날짜 (null이면 체크되지 않음)

    @Column(name = "recurrence_start_date", nullable = true)
    private LocalDateTime recurrenceStartDate;

    @Column(name = "recurrence_end_date", nullable = true)
    private LocalDateTime recurrenceEndDate;
    
    @Column(name = "excluded_dates", nullable = true, columnDefinition = "TEXT")
    private String excludedDates; // 쉼표로 구분된 ISO 날짜 문자열 "2023-10-01,2023-10-08"

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "firebase_uid")
    private User user;
}
