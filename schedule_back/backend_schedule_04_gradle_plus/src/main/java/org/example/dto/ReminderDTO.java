package org.example.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.util.*;

@Getter
@Setter
@NoArgsConstructor
public class ReminderDTO {
    private String title;
    private String startTime;
    private String endTime;
    private boolean isRecurring;
    private Long scheduleId;
    private List<Integer> recurrenceDays;
    private Integer reminderMinutesBefore;
}

