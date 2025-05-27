package org.example.domain.planning.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
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
@Entity
@Table(name = "planning_schedule_final")
public class PlanningFinal {

    @Id
    @Column(name = "room_id")
    private Integer roomId;

    @Column(name = "final_date", nullable = false)
    private LocalDate finalDate;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "finalized_at", nullable = false)
    private LocalDateTime finalizedAt;
} 