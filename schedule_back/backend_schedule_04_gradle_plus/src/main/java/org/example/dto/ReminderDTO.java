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
    private String reminderTitle;
    private String recurrenceDays;
    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;
    private Boolean isActive;
    private LocalDateTime checkedDate;
    private LocalDateTime recurrenceStartDate;
    private LocalDateTime recurrenceEndDate;
    private String excludedDates;

    public static ReminderDTO fromEntity(Reminder reminder) {
        return ReminderDTO.builder()
                .id(reminder.getId())
                .reminderTitle(reminder.getReminderTitle())
                .recurrenceDays(reminder.getRecurrenceDays())
                .reminderMinutesBefore(reminder.getReminderMinutesBefore())
                .reminderTime(reminder.getReminderTime())
                .isActive(reminder.getIsActive())
                .checkedDate(reminder.getCheckedDate())
                .recurrenceStartDate(reminder.getRecurrenceStartDate())
                .recurrenceEndDate(reminder.getRecurrenceEndDate())
                .excludedDates(reminder.getExcludedDates())
                .build();
    }
}
