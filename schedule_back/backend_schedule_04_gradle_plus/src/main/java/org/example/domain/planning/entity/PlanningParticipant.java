package org.example.domain.planning.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "planning_schedule_participants")
@IdClass(PlanningParticipantId.class)
public class PlanningParticipant {

    @Id
    @Column(name = "room_id")
    private Integer roomId;

    @Id
    @Column(name = "user_id")
    private String userId;

    @Column(name = "username", nullable = false)
    private String username;
    
    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt;
} 