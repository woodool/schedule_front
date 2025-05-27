package org.example.domain.planning.entity;

import jakarta.persistence.*;
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
@Table(name = "planning_schedule_time_suggestions")
public class PlanningTimeSuggestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "suggestion_id")
    private Integer suggestionId;

    @Column(name = "room_id", nullable = false)
    private Integer roomId;

    @Column(name = "suggestion_date", nullable = false)
    private LocalDate suggestionDate;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "is_all_free", nullable = false)
    private Boolean isAllFree;

    @Column(name = "free_count", nullable = false)
    private Integer freeCount;

    @Builder.Default
    @Column(name = "vote_count")
    private Integer voteCount = 0;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
} 