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
public class PostponeRequestDTO {
    private String mode; // "1day", "7days", "custom"
    private LocalDateTime customReminderTime; // mode가 "custom"일 때만 사용
}
