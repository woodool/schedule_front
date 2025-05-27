package org.example.domain.planning.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.domain.planning.entity.Phase;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlanningRoomDTO {
    private Integer roomId;
    private String photoUrl;
    private String roomName;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer categoryId;
    private String categoryName;
    private Integer priority;
    
    @Builder.Default
    private Integer timeSlotUnit = 60;
    
    private String inviteCode;
    private String createdBy;
    private String creatorName;
    private LocalDateTime createdAt;
    private Integer participantCount;
    private Boolean hasFinalSchedule;

    @Builder.Default
    private Phase phase = Phase.ROOM;
} 