package org.example.domain.schedule.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateScheduleRequestDTO {
    private String title;
    private String description;
    private Integer categoryId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;

    // 반복 일정
    // "1,0,0,0,0,0,0"
    private String recurrenceDays;
    private LocalDateTime recurrenceStartDate;
    private LocalDateTime recurrenceEndDate;
    private String excludedDates;

    private Integer reminderMinutesBefore;
    private Integer priority;
    private Boolean displayOnCalendar;
}