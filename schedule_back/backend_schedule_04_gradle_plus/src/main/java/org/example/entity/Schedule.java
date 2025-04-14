package org.example.entity;

import jakarta.persistence.*;

import lombok.*;
import org.example.dto.ScheduleDTO;
import org.example.entity.Reminder;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.*;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Schedule {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long scheduleId; // 일정 ID

    private String firebaseUid; // 사용자 고유 ID
    private String title; // 일정 제목
    private String description; // 일정 설명

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime; // 시작 시간

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime; // 종료 시간
    private int priority;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    private boolean isRecurring;

    @Column(name = "display_on_calendar", nullable = false)
    private Boolean displayOnCalendar = true;

    @ElementCollection
    @CollectionTable(name = "schedule_recurrence_days", joinColumns = @JoinColumn(name = "schedule_id"))
    @Column(name = "day_of_week")
    private List<Integer> recurrenceDays;

    @Column(name = "reminder_minutes_before")
    private Integer reminderMinutesBefore;

    @OneToMany(mappedBy = "schedule", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Reminder> reminders = new ArrayList<>();

    private Boolean isHiddenInToDo = false; // To-Do 리스트에서 숨김 여부 (기본값 false)
    private Boolean isReminderEnabled = true; // 리마인더 활성화 여부 (기본값 true)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "user_id")
    private User user;

    // ScheduleDTO -> Schedule 변환 메서드
    public static Schedule fromDTO(String firebaseUid, ScheduleDTO dto, Category category) {
        return Schedule.builder()
                .firebaseUid(firebaseUid)
                .title(dto.getTitle())
                .description(dto.getDescription())
                .startTime(dto.getStartTime())
                .endTime(dto.getEndTime())
                .priority(dto.getPriority())
                .category(category)
                .isRecurring(dto.isRecurring())
                .recurrenceDays(dto.getRecurrenceDays() != null ? dto.getRecurrenceDays() : new ArrayList<>())
                .isHiddenInToDo(false)         // 기본값 처리
                .isReminderEnabled(true)      // 기본값 처리
                .displayOnCalendar(dto.isDisplayOnCalendar())
                .reminderMinutesBefore(dto.getReminderMinutesBefore())
                .build();
    }

    // 일정 미루기 메서드 (일 수 기준으로 연기)
    public void postponeSchedule(int days) {
        if (days <= 0) {
            throw new IllegalArgumentException("미룰 일 수는 0보다 커야 합니다.");
        }
        if (this.endTime.isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("이미 지난 일정은 미룰 수 없습니다.");
        }
        this.startTime = this.startTime.plusDays(days);
        this.endTime = this.endTime.plusDays(days);
    }

    // To-Do 리스트에서 숨기면서 리마인더 비활성화
    public void hideFromToDoList() {
        this.isHiddenInToDo = true;
        this.isReminderEnabled = false; // 리마인더도 비활성화
    }

}
