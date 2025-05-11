package org.example.domain.schedule.dto;

import lombok.*;
import java.time.LocalTime;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Data
public class AutoScheduleRequestDTO {
    private String title;
    private String description;
    private int priority; // 1: 높음 ~ 5: 낮음
    private LocalTime startTime; // 사용자가 원하는 시작 시각
    private LocalTime endTime;   // 사용자가 원하는 마감 시각
}

