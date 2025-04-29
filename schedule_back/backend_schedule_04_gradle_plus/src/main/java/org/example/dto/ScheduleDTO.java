package org.example.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduleDTO {
    private Long id;
    private String title;
    private String description;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String recurrenceDays;
    private Integer categoryId;
    private Integer priority;
    private Boolean displayOnCalendar;
    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;

    public static ScheduleDTO fromEntity(org.example.entity.Schedule schedule) {
        return ScheduleDTO.builder()
                .id(schedule.getId())
                .title(schedule.getTitle())
                .description(schedule.getDescription())
                .startTime(schedule.getStartTime())
                .endTime(schedule.getEndTime())
                .recurrenceDays(schedule.getRecurrenceDays())
                .categoryId(schedule.getCategoryId())
                .priority(schedule.getPriority())
                .displayOnCalendar(schedule.getDisplayOnCalendar())
                .reminderMinutesBefore(schedule.getReminderMinutesBefore())
                .reminderTime(schedule.getReminderTime())
                .build();
    }
} 