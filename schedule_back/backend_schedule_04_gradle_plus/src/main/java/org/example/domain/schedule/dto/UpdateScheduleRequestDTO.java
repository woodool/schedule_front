package org.example.domain.schedule.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateScheduleRequestDTO {
    private String title;
    private String description;
    private Integer categoryId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;

    // 반복 일정
    private String recurrenceDays;
    private LocalDateTime recurrenceStartDate;
    private LocalDateTime recurrenceEndDate;
    private String excludedDates;

    private Integer reminderMinutesBefore;
    private Integer priority;
    private Boolean displayOnCalendar;

    // 수정 모드: SINGLE, FUTURE, ALL
    private RecurrenceOption option;
    // SINGLE 또는 FUTURE 모드에서 대상 날짜(YYYY-MM-DD 또는 ISO) 기준
    private LocalDateTime occurrenceDate;
}