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
public class PlanningSuggestionVoteDTO {
    private Integer roomId;
    private Integer suggestionId;
    private String userId;
    private String username;
    private Boolean voteFlag;
    private LocalDateTime votedAt;
} 