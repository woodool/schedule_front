package org.example.domain.planning.service;

import org.example.domain.planning.dto.*;

import java.time.LocalDate;
import java.util.List;

/**
 * “일정 잡기” 비즈니스 계층 최상위 인터페이스  
 * - Phase 전환(ROOM → VOTING → WAITING → RESULT)을 컨트롤러‧프론트와 동일 기준으로 노출  
 * - 내부 로직은 그대로 유지하면서 startVoting 등 신규 기능을 추가  
 */
public interface PlanningService {

    /* ───────── PlanningRoom ───────── */
    PlanningRoomDTO createPlanningRoom(PlanningRoomDTO planningRoomDTO, String creatorId);
    PlanningRoomDTO getPlanningRoomById(Integer roomId);
    List<PlanningRoomDTO> getUserPlanningRooms(String userId);
    PlanningRoomDTO updatePlanningRoom(Integer roomId, PlanningRoomDTO planningRoomDTO, String userId);
    void deletePlanningRoom(Integer roomId, String userId);
    PlanningRoomDTO joinPlanningRoomByInviteCode(String inviteCode, String userId);

    /** ★ 방장이 “일정 잡기” 버튼을 눌러 VOTING Phase 로 전환 */
    PlanningRoomDTO startVoting(Integer roomId, String requesterId);

    /* ───────── PlanningParticipant ───────── */
    List<PlanningParticipantDTO> getPlanningParticipants(Integer roomId);
    PlanningParticipantDTO addPlanningParticipant(Integer roomId, String userId);
    void removePlanningParticipant(Integer roomId, String userId, String requesterId);

    /* ───────── PlanningTimeSuggestion ───────── */
    List<PlanningTimeSuggestionDTO> getPlanningTimeSuggestions(Integer roomId);
    List<PlanningTimeSuggestionDTO> getAllFreeTimeSuggestions(Integer roomId);
    List<PlanningTimeSuggestionDTO> getMostPopularTimeSuggestions(Integer roomId);
    void deleteTimeSuggestion(Integer suggestionId, String userId);

    /* ───────── PlanningSuggestionVote ───────── */
    List<PlanningSuggestionVoteDTO> getVotesForSuggestion(Integer roomId, Integer suggestionId);
    PlanningSuggestionVoteDTO voteForSuggestion(Integer roomId, Integer suggestionId,
                                                String userId, Boolean voteFlag);
    void deleteVote(Integer roomId, Integer suggestionId, String userId);

    /* ───────── PlanningFinal ───────── */
    PlanningFinalDTO getFinalSchedule(Integer roomId);
    List<PlanningFinalDTO> getUserFinalSchedules(String userId);
    List<PlanningFinalDTO> getUserFinalSchedulesByDateRange(String userId,
                                                            LocalDate startDate, LocalDate endDate);
    PlanningFinalDTO createFinalSchedule(Integer roomId, PlanningFinalDTO finalDTO, String userId);
    PlanningFinalDTO updateFinalSchedule(Integer roomId, PlanningFinalDTO finalDTO, String userId);
    void deleteFinalSchedule(Integer roomId, String userId);

    /* ───────── Utility / Flow 메소드 ───────── */
    List<PlanningTimeSuggestionDTO> calculateAvailableTimeSlots(Integer roomId);
    boolean checkAllVotesCompleted(Integer roomId);
    PlanningFinalDTO selectFinalScheduleByVotes(Integer roomId, String userId, Boolean useEarliestOnTie);
    Long addFinalScheduleToMySchedule(Integer roomId, String userId);
    int  countUserVotesInRoom(Integer roomId, String userId);
    boolean checkUserVoted(Integer roomId, String userId);
    void deleteUserVotesInRoom(Integer roomId, String userId);
}
