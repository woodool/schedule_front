package org.example.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.*;

@Getter
@Setter
public class ScheduleDTO {
    private String title;

    @JsonProperty("memo")
    private String description;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private int priority;
    private Long categoryId;
    private String firebaseUid;

    private boolean isRecurring;
    private List<Integer> recurrenceDays;

    private Integer reminderMinutesBefore;

    private boolean displayOnCalendar;
    // 생성자
    public ScheduleDTO(String title, String description, LocalDateTime startTime, LocalDateTime endTime,
                       int priority, Long categoryId,
                       boolean isRecurring, List<Integer> recurrenceDays,
                       Integer reminderMinutesBefore, boolean displayOnCalendar) {
        this.title = title;
        this.description = description;
        this.startTime = startTime;
        this.endTime = endTime;
        this.priority = priority;
        this.categoryId = categoryId;
        this.isRecurring = isRecurring;
        this.recurrenceDays = recurrenceDays;
        this.reminderMinutesBefore = reminderMinutesBefore;
        this.displayOnCalendar = displayOnCalendar;
    }
}
