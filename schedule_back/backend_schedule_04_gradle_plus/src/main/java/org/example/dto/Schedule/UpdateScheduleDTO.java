package org.example.dto.Schedule;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.time.LocalDateTime;
import java.util.*;

@Getter
@Setter
public class UpdateScheduleDTO {
    @NotBlank(message = "제목은 필수입니다.")
    private String title;

    @NotNull(message = "시작 시간은 필수입니다.")
    private LocalDateTime startTime;

    @NotNull(message = "종료 시간은 필수입니다.")
    private LocalDateTime endTime;

    @NotNull(message = "반복 요일 정보는 필수입니다.")
    private List<Integer> recurrenceDays;

    @NotNull(message = "알림 시간 설정은 필수입니다.")
    private Integer reminderMinutesBefore;

    private LocalDateTime reminderTime;

    private Long categoryId;
    private int priority;

    @JsonProperty("memo")
    private String description;
    private String firebaseUid;

    private boolean displayOnCalendar;
}
