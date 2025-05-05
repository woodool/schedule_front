package org.example.domain.schedule.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ScheduleResponseDTO {
    private Long id;
    private String title;
    private String description;
    private Integer categoryId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String recurrenceDays;
    private LocalDateTime recurrenceStartDate;
    private LocalDateTime recurrenceEndDate;
    private String excludedDates;
    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;
    private Integer priority;
    private Boolean displayOnCalendar;

    // 변환 유틸
    public static ScheduleResponseDTO fromEntity(org.example.domain.schedule.entity.Schedule s) {
        return ScheduleResponseDTO.builder()
                .id(s.getId())
                .title(s.getTitle())
                .description(s.getDescription())
                .categoryId(s.getCategoryId())
                .startTime(s.getStartTime())
                .endTime(s.getEndTime())
                .recurrenceDays(s.getRecurrenceDays())
                .recurrenceStartDate(s.getRecurrenceStartDate())
                .recurrenceEndDate(s.getRecurrenceEndDate())
                .excludedDates(s.getExcludedDates())
                .reminderMinutesBefore(s.getReminderMinutesBefore())
                .reminderTime(s.getReminderTime())
                .priority(s.getPriority())
                .displayOnCalendar(s.getDisplayOnCalendar())
                .build();
    }
}