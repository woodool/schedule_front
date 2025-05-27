package org.example.domain.planning.repository;

import org.example.domain.planning.entity.PlanningSuggestionVote;
import org.example.domain.planning.entity.PlanningSuggestionVoteId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Modifying;

import java.util.List;
import java.util.Optional;

@Repository
public interface PlanningSuggestionVoteRepository extends JpaRepository<PlanningSuggestionVote, PlanningSuggestionVoteId> {
    
    List<PlanningSuggestionVote> findByRoomIdAndSuggestionId(Integer roomId, Integer suggestionId);
    
    @Query("SELECT psv FROM PlanningSuggestionVote psv WHERE psv.roomId = :roomId")
    List<PlanningSuggestionVote> findByRoomId(@Param("roomId") Integer roomId);
    
    Optional<PlanningSuggestionVote> findByRoomIdAndSuggestionIdAndUserId(Integer roomId, Integer suggestionId, String userId);
    
    @Query("SELECT COUNT(psv) FROM PlanningSuggestionVote psv WHERE psv.roomId = :roomId AND psv.suggestionId = :suggestionId AND psv.voteFlag = true")
    int countPositiveVotes(@Param("roomId") Integer roomId, @Param("suggestionId") Integer suggestionId);
    
    @Query("SELECT COUNT(v) FROM PlanningSuggestionVote v " +
           "WHERE v.roomId = :roomId AND v.suggestionId = :suggestionId")
    int countTotalVotes(@Param("roomId") Integer roomId, @Param("suggestionId") Integer suggestionId);
    
    @Query("DELETE FROM PlanningSuggestionVote v WHERE v.roomId = :roomId AND v.suggestionId IN " +
           "(SELECT s.suggestionId FROM PlanningTimeSuggestion s WHERE s.roomId = :roomId)")
    void deleteAllVotesForRoom(@Param("roomId") Integer roomId);
    
    int countBySuggestionId(Integer suggestionId);
    
    void deleteBySuggestionId(Integer suggestionId);
    
    void deleteBySuggestionIdAndUserId(Integer suggestionId, String userId);
    
    @Query("SELECT COUNT(v) FROM PlanningSuggestionVote v " +
           "JOIN PlanningTimeSuggestion s ON v.suggestionId = s.suggestionId " +
           "WHERE s.roomId = :roomId AND v.userId = :userId")
    int countVotesByRoomIdAndUserId(@Param("roomId") Integer roomId, @Param("userId") String userId);
    
    @Query("DELETE FROM PlanningSuggestionVote v WHERE v.roomId = :roomId AND v.userId = :userId")
    @Modifying
    void deleteVotesByRoomIdAndUserId(@Param("roomId") Integer roomId, @Param("userId") String userId);

    @Query("SELECT COUNT(v) FROM PlanningSuggestionVote v WHERE v.roomId = :roomId AND v.userId = :userId")
    int countUserVotesInRoom(@Param("roomId") Integer roomId, @Param("userId") String userId);

    @Query("SELECT CASE WHEN COUNT(v) > 0 THEN true ELSE false END FROM PlanningSuggestionVote v WHERE v.roomId = :roomId AND v.userId = :userId")
    boolean checkUserVoted(@Param("roomId") Integer roomId, @Param("userId") String userId);

    @Query("DELETE FROM PlanningSuggestionVote v WHERE v.roomId = :roomId AND v.userId = :userId")
    @Modifying
    void deleteUserVotesInRoom(@Param("roomId") Integer roomId, @Param("userId") String userId);

    @Query("DELETE FROM PlanningSuggestionVote v WHERE v.roomId = :roomId AND v.suggestionId = :suggestionId AND v.userId = :userId")
    @Modifying
    void deleteVote(@Param("roomId") Integer roomId, @Param("suggestionId") Integer suggestionId, @Param("userId") String userId);
} 