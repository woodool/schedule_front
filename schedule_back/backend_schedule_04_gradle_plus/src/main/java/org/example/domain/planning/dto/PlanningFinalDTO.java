package org.example.domain.planning.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlanningFinalDTO {
    private Integer roomId;
    private LocalDate finalDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private LocalDateTime finalizedAt;
    private String roomName;
    private String categoryName;
} 