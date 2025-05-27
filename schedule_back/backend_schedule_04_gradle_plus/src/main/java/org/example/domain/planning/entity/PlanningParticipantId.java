package org.example.domain.planning.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlanningParticipantId implements Serializable {
    private Integer roomId;
    private String userId;
} 