package org.example.domain.schedule.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Data
public class AutoScheduleResponseDTO {
    private String title;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String description;
    private int priority;
    private Long replacedScheduleId;
}

