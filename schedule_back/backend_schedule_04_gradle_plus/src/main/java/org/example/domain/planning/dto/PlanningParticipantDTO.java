package org.example.domain.planning.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlanningParticipantDTO {
    private Integer roomId;
    private String userId;
    private String username;
    private String email;
    private LocalDateTime joinedAt;
} 