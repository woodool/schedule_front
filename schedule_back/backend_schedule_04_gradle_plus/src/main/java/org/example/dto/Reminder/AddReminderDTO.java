package org.example.dto.Reminder;

import lombok.*;

import java.time.LocalDateTime;
import java.util.*;

@Getter
@Setter
public class AddReminderDTO {
    private String title;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    private List<Integer> recurrenceDays;

    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;
    private String firebaseUid;
}
