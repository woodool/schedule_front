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
@Table(name = "planning_schedule_suggestion_votes")
@IdClass(PlanningSuggestionVoteId.class)
public class PlanningSuggestionVote {

    @Id
    @Column(name = "room_id")
    private Integer roomId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", insertable = false, updatable = false)
    private PlanningRoom planningRoom;

    @Id
    @Column(name = "suggestion_id")
    private Integer suggestionId;

    @Id
    @Column(name = "user_id")
    private String userId;

    @Column(name = "vote_flag", nullable = false)
    private Boolean voteFlag;

    @Column(name = "voted_at", nullable = false)
    private LocalDateTime votedAt;
} 