package org.example.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.entity.Reminder;

import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReminderDTO {
    private Long id;
    private String title;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String recurrenceDays;
    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;
    private Boolean isActive;

    public static ReminderDTO fromEntity(Reminder reminder) {
        return ReminderDTO.builder()
                .id(reminder.getId())
                .title(reminder.getTitle())
                .startTime(reminder.getStartTime())
                .endTime(reminder.getEndTime())
                .recurrenceDays(reminder.getRecurrenceDays())
                .reminderMinutesBefore(reminder.getReminderMinutesBefore())
                .reminderTime(reminder.getReminderTime())
                .isActive(reminder.getIsActive())
                .build();
    }
}
