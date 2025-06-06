package org.example.domain.meeting.dto;

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
public class MeetingRoomDTO {
    private Integer roomId;
    private String photoUrl;
    private String meetingName;
    private LocalDate startDate;
    private LocalDate endDate;
    private LocalDate recurrenceStart;
    private LocalDate recurrenceEnd;
    private LocalTime timeOfDay;
    private Integer categoryId;
    private String categoryName;
    private Integer capacity;
    private String description;
    private String announcement;
    private String memo;
    private String inviteCode;
    private String createdBy;
    private LocalDateTime createdAt;
    private Integer participantCount;
} 