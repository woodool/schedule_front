package org.example.domain.planning.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlanningTimeSuggestionDTO {
    private Integer suggestionId;
    private Integer roomId;
    private LocalDate suggestionDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private Boolean isAllFree;
    private Integer freeCount;
    
    @Builder.Default
    private Integer voteCount = 0;
    
    private LocalDateTime createdAt;
    private Boolean hasVoted;
    private List<PlanningSuggestionVoteDTO> votes;
} 