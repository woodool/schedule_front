package org.example.dto.Schedule;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import java.time.LocalDateTime;
import java.util.*;

@Getter
@Setter
public class AddScheduleDTO {
    private String title;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    private List<Integer> recurrenceDays;

    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;

    private Long categoryId;
    private int priority;

    @JsonProperty("memo")
    private String description;
    private String firebaseUid;

    private boolean displayOnCalendar;
}
