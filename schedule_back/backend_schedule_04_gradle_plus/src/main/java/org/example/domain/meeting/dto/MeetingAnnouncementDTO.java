package org.example.domain.meeting.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MeetingAnnouncementDTO {
    private Integer announcementId;
    private Integer roomId;
    private String content;
    private LocalDateTime createdAt;
    private String createdBy;
    private String creatorName;
} 