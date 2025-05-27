package org.example.domain.planning.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "planning_schedule_rooms")
public class PlanningRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "room_id")
    private Integer roomId;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "phase", columnDefinition = "room_phase", nullable = false)
    @org.hibernate.annotations.ColumnTransformer(
        write = "?::room_phase"
    )
    private Phase phase = Phase.ROOM;

    @Column(name = "room_name", nullable = false)
    private String roomName;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "category_id", nullable = true)
    private Integer categoryId;

    @Column(name = "priority", nullable = true)
    private Integer priority;

    @Column(name = "time_slot_unit", nullable = false)
    private Integer timeSlotUnit;

    @Column(name = "invite_code", nullable = false, unique = true)
    private String inviteCode;

    @Column(name = "created_by", nullable = false)
    private String createdBy;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
} 