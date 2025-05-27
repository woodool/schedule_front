package org.example.domain.planning.mapper;

import org.example.domain.planning.dto.*;
import org.example.domain.planning.entity.*;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper(componentModel = "spring")
public interface PlanningMapper {

    PlanningMapper INSTANCE = Mappers.getMapper(PlanningMapper.class);

    /* ───────── PlanningRoom 매핑 ───────── */
    @Mapping(target = "categoryName",     ignore = true)
    @Mapping(target = "creatorName",      ignore = true)
    @Mapping(target = "participantCount", ignore = true)
    @Mapping(target = "hasFinalSchedule", ignore = true)
    /* phase는 그대로 매핑 (기본값 포함) */
    PlanningRoomDTO toPlanningRoomDTO(PlanningRoom planningRoom);

    PlanningRoom toPlanningRoom(PlanningRoomDTO planningRoomDTO);

    /* 부분 수정 시 phase 도 반영 */
    void updatePlanningRoomFromDTO(PlanningRoomDTO dto,
                                   @MappingTarget PlanningRoom entity);

    /* ───────── PlanningParticipant 매핑 ───────── */
    @Mapping(target = "email", ignore = true)
    PlanningParticipantDTO toPlanningParticipantDTO(PlanningParticipant participant);
    PlanningParticipant toPlanningParticipant(PlanningParticipantDTO participantDTO);
    List<PlanningParticipantDTO> toPlanningParticipantDTOList(List<PlanningParticipant> participants);

    /* ───────── PlanningTimeSuggestion 매핑 ───────── */
    @Mapping(target = "hasVoted", ignore = true)
    @Mapping(target = "votes",    ignore = true)
    PlanningTimeSuggestionDTO toPlanningTimeSuggestionDTO(PlanningTimeSuggestion suggestion);
    PlanningTimeSuggestion toPlanningTimeSuggestion(PlanningTimeSuggestionDTO suggestionDTO);
    List<PlanningTimeSuggestionDTO> toPlanningTimeSuggestionDTOList(List<PlanningTimeSuggestion> suggestions);

    /* ───────── PlanningSuggestionVote 매핑 ───────── */
    @Mapping(target = "username",      ignore = true)
    PlanningSuggestionVoteDTO toPlanningSuggestionVoteDTO(PlanningSuggestionVote vote);
    @Mapping(target = "planningRoom",  ignore = true)
    PlanningSuggestionVote toPlanningSuggestionVote(PlanningSuggestionVoteDTO voteDTO);
    List<PlanningSuggestionVoteDTO> toPlanningSuggestionVoteDTOList(List<PlanningSuggestionVote> votes);

    /* ───────── PlanningFinal 매핑 ───────── */
    @Mapping(target = "roomName",     ignore = true)
    @Mapping(target = "categoryName", ignore = true)
    PlanningFinalDTO toPlanningFinalDTO(PlanningFinal finalSchedule);
    PlanningFinal toPlanningFinal(PlanningFinalDTO finalDTO);
    List<PlanningFinalDTO> toPlanningFinalDTOList(List<PlanningFinal> finalSchedules);
}
