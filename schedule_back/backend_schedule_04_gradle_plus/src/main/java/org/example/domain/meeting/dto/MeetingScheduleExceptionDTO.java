package org.example.domain.meeting.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MeetingScheduleExceptionDTO {
    private Integer exceptionId;
    private Integer scheduleId;
    private LocalDate exceptionDate;
    private Boolean isDeleted;
    private LocalTime overrideStartTime;
    private LocalTime overrideEndTime;
    private String overrideMemo;
    private Boolean applyToFuture;
} 