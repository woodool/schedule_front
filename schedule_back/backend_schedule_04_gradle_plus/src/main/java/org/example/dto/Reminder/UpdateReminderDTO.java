package org.example.dto.Reminder;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.*;

@Getter
@Setter
public class UpdateReminderDTO {
    private String title;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    private List<Integer> recurrenceDays;

    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;
    private String firebaseUid;
}
