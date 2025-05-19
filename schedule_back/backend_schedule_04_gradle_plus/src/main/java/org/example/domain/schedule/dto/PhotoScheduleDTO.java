package org.example.domain.schedule.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PhotoScheduleDTO {
    private String title;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String recurrenceDays;
    private LocalDateTime recurrenceStartDate;
    private LocalDateTime recurrenceEndDate;
}
