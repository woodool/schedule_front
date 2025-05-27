package org.example.domain.planning.repository;

import org.example.domain.planning.entity.PlanningTimeSuggestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PlanningTimeSuggestionRepository extends JpaRepository<PlanningTimeSuggestion, Integer> {
    
    List<PlanningTimeSuggestion> findByRoomIdOrderByCreatedAtDesc(Integer roomId);
    
    @Query("SELECT pts FROM PlanningTimeSuggestion pts WHERE pts.roomId = :roomId AND pts.isAllFree = true")
    List<PlanningTimeSuggestion> findAllFreeTimesByRoomId(@Param("roomId") Integer roomId);
    
    @Query("SELECT pts FROM PlanningTimeSuggestion pts WHERE pts.roomId = :roomId ORDER BY pts.freeCount DESC")
    List<PlanningTimeSuggestion> findByRoomIdOrderByFreeCountDesc(@Param("roomId") Integer roomId);
    
    void deleteByRoomId(Integer roomId);

    // 특정 방에서 투표수가 가장 많은 시간 제안 조회
    Optional<PlanningTimeSuggestion> findTopByRoomIdOrderByVoteCountDesc(Integer roomId);
    
    /**
     * 특정 방의 시간 제안들을 투표수 내림차순, 날짜 오름차순, 시작시간 오름차순으로 정렬하여 조회
     * 동률 처리를 위해 사용됩니다.
     */
    @Query("SELECT s FROM PlanningTimeSuggestion s WHERE s.roomId = :roomId " +
           "ORDER BY s.voteCount DESC, s.suggestionDate ASC, s.startTime ASC")
    List<PlanningTimeSuggestion> findTopVotedSuggestionsForRoom(@Param("roomId") Integer roomId);
} 