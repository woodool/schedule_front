package org.example.domain.planning.controller;

import lombok.RequiredArgsConstructor;
import org.example.domain.planning.dto.*;
import org.example.domain.planning.entity.Phase;
import org.example.domain.planning.service.PlanningService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDate;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;

@RestController
@RequestMapping("/api/planning")
@RequiredArgsConstructor
public class PlanningController {

    private final PlanningService planningService;
    private static final Logger log = LoggerFactory.getLogger(PlanningController.class);

    // PlanningRoom 관련 엔드포인트
    @PostMapping("/rooms")
    public ResponseEntity<PlanningRoomDTO> createPlanningRoom(
            @RequestBody PlanningRoomDTO planningRoomDTO,
            Authentication auth) {
        String firebaseUid = auth.getName();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(planningService.createPlanningRoom(planningRoomDTO, firebaseUid));
    }

    @GetMapping("/rooms/{roomId}")
    public ResponseEntity<PlanningRoomDTO> getPlanningRoom(@PathVariable Integer roomId) {
        return ResponseEntity.ok(planningService.getPlanningRoomById(roomId));
    }

    /** Phase 한 눈에 보기용 */
    @GetMapping("/rooms/{roomId}/phase")
    public ResponseEntity<Phase> getRoomPhase(@PathVariable Integer roomId) {
        Phase phase = planningService.getPlanningRoomById(roomId).getPhase();
        return ResponseEntity.ok(phase);
    }

    /** 방장이 “일정 잡기” 버튼을 눌러 투표 단계로 진입 */
    @PostMapping("/rooms/{roomId}/start-voting")
    public ResponseEntity<PlanningRoomDTO> startVoting(
            @PathVariable Integer roomId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        PlanningRoomDTO dto = planningService.startVoting(roomId, firebaseUid); // 서비스에 구현 필요
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/rooms/user")
    public ResponseEntity<List<PlanningRoomDTO>> getUserPlanningRooms(Authentication auth) {
        return ResponseEntity.ok(planningService.getUserPlanningRooms(auth.getName()));
    }

    @PutMapping("/rooms/{roomId}")
    public ResponseEntity<PlanningRoomDTO> updatePlanningRoom(
            @PathVariable Integer roomId,
            @RequestBody PlanningRoomDTO planningRoomDTO,
            Authentication auth) {
        return ResponseEntity.ok(
                planningService.updatePlanningRoom(roomId, planningRoomDTO, auth.getName()));
    }

    @DeleteMapping("/rooms/{roomId}")
    public ResponseEntity<Void> deletePlanningRoom(
            @PathVariable Integer roomId,
            Authentication auth) {
        planningService.deletePlanningRoom(roomId, auth.getName());
        return ResponseEntity.noContent().build();
    }   

    @PostMapping("/rooms/join/{inviteCode}")
    public ResponseEntity<PlanningRoomDTO> joinPlanningRoom(
            @PathVariable String inviteCode,
            Authentication auth) {
        return ResponseEntity.ok(
                planningService.joinPlanningRoomByInviteCode(inviteCode, auth.getName()));
    }

    // PlanningParticipant 관련 엔드포인트
    @GetMapping("/rooms/{roomId}/participants")
    public ResponseEntity<List<PlanningParticipantDTO>> getPlanningParticipants(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(planningService.getPlanningParticipants(roomId));
    }

    @PostMapping("/rooms/{roomId}/participants")
    public ResponseEntity<PlanningParticipantDTO> addPlanningParticipant(
            @PathVariable Integer roomId,
            @RequestParam String userId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(planningService.addPlanningParticipant(roomId, userId));
    }

    @DeleteMapping("/rooms/{roomId}/participants/{userId}")
    public ResponseEntity<Void> removePlanningParticipant(
            @PathVariable Integer roomId,
            @PathVariable String userId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        planningService.removePlanningParticipant(roomId, userId, firebaseUid);
        return ResponseEntity.noContent().build();
    }

    // PlanningTimeSuggestion 관련 엔드포인트
    @GetMapping("/rooms/{roomId}/suggestions")
    public ResponseEntity<List<PlanningTimeSuggestionDTO>> getPlanningTimeSuggestions(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(planningService.getPlanningTimeSuggestions(roomId));
    }

    @GetMapping("/rooms/{roomId}/suggestions/all-free")
    public ResponseEntity<List<PlanningTimeSuggestionDTO>> getAllFreeTimeSuggestions(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(planningService.getAllFreeTimeSuggestions(roomId));
    }

    @GetMapping("/rooms/{roomId}/suggestions/popular")
    public ResponseEntity<List<PlanningTimeSuggestionDTO>> getMostPopularTimeSuggestions(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(planningService.getMostPopularTimeSuggestions(roomId));
    }

    @DeleteMapping("/suggestions/{suggestionId}")
    public ResponseEntity<Void> deleteTimeSuggestion(
            @PathVariable Integer suggestionId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        planningService.deleteTimeSuggestion(suggestionId, firebaseUid);
        return ResponseEntity.noContent().build();
    }

    // PlanningSuggestionVote 관련 엔드포인트
    @GetMapping("/rooms/{roomId}/suggestions/{suggestionId}/votes")
    public ResponseEntity<List<PlanningSuggestionVoteDTO>> getVotesForSuggestion(
            @PathVariable Integer roomId,
            @PathVariable Integer suggestionId) {
        return ResponseEntity.ok(planningService.getVotesForSuggestion(roomId, suggestionId));
    }

    @PostMapping("/rooms/{roomId}/suggestions/{suggestionId}/votes")
    public ResponseEntity<PlanningSuggestionVoteDTO> voteForSuggestion(
            @PathVariable Integer roomId,
            @PathVariable Integer suggestionId,
            @RequestBody Map<String, Object> requestBody) {
        String userId = (String) requestBody.get("userId");
        Boolean voteFlag = (Boolean) requestBody.get("voteFlag");
        
        if (userId == null || voteFlag == null) {
            throw new IllegalArgumentException("userId와 voteFlag는 필수 값입니다.");
        }
        
        return ResponseEntity.ok(planningService.voteForSuggestion(roomId, suggestionId, userId, voteFlag));
    }

    @DeleteMapping("/rooms/{roomId}/suggestions/{suggestionId}/votes")
    public ResponseEntity<Void> deleteVote(
            @PathVariable Integer roomId,
            @PathVariable Integer suggestionId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        planningService.deleteVote(roomId, suggestionId, firebaseUid);
        return ResponseEntity.noContent().build();
    }

    // PlanningFinal 관련 엔드포인트
    @GetMapping("/rooms/{roomId}/final")
    public ResponseEntity<PlanningFinalDTO> getFinalSchedule(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(planningService.getFinalSchedule(roomId));
    }

    @GetMapping("/final/user")
    public ResponseEntity<List<PlanningFinalDTO>> getUserFinalSchedules(
            Authentication auth) {
        String firebaseUid = auth.getName();
        return ResponseEntity.ok(planningService.getUserFinalSchedules(firebaseUid));
    }

    @GetMapping("/final/user/range")
    public ResponseEntity<List<PlanningFinalDTO>> getUserFinalSchedulesByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Authentication auth) {
        String firebaseUid = auth.getName();
        return ResponseEntity.ok(planningService.getUserFinalSchedulesByDateRange(firebaseUid, startDate, endDate));
    }

    @PostMapping("/rooms/{roomId}/final")
    public ResponseEntity<PlanningFinalDTO> createFinalSchedule(
            @PathVariable Integer roomId,
            @RequestBody PlanningFinalDTO finalDTO,
            Authentication auth) {
        String firebaseUid = auth.getName();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(planningService.createFinalSchedule(roomId, finalDTO, firebaseUid));
    }

    @PutMapping("/rooms/{roomId}/final")
    public ResponseEntity<PlanningFinalDTO> updateFinalSchedule(
            @PathVariable Integer roomId,
            @RequestBody PlanningFinalDTO finalDTO,
            Authentication auth) {
        String firebaseUid = auth.getName();
        return ResponseEntity.ok(planningService.updateFinalSchedule(roomId, finalDTO, firebaseUid));
    }

    @DeleteMapping("/rooms/{roomId}/final")
    public ResponseEntity<Void> deleteFinalSchedule(
            @PathVariable Integer roomId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        planningService.deleteFinalSchedule(roomId, firebaseUid);
        return ResponseEntity.noContent().build();
    }

    /**
     * 일정 잡기 API - 모든 참가자의 일정을 자동으로 비교하여 비어있는 시간대를 계산합니다.
     */
    @PostMapping("/rooms/{roomId}/calculate-available-times")
    public ResponseEntity<List<PlanningTimeSuggestionDTO>> calculateAvailableTimes(
            @PathVariable Integer roomId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        log.info("사용자 {}가 방 {}의 시간대 계산 요청(POST)", firebaseUid, roomId);
        
        try {
            List<PlanningTimeSuggestionDTO> availableTimes = planningService.calculateAvailableTimeSlots(roomId);
            return ResponseEntity.ok(availableTimes);
        } catch (Exception e) {
            log.error("시간대 계산 중 오류 발생: {}", e.getMessage(), e);
            // 빈 배열 반환하여 클라이언트가 처리할 수 있도록 함
            return ResponseEntity.ok(new ArrayList<>());
        }
    }

    // GET 메서드로도 동일한 기능 제공 (POST 요청에 문제가 있는 클라이언트를 위함)
    @GetMapping("/rooms/{roomId}/calculate-available-times")
    public ResponseEntity<List<PlanningTimeSuggestionDTO>> calculateAvailableTimesGet(
            @PathVariable Integer roomId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        log.info("사용자 {}가 방 {}의 시간대 계산 요청(GET)", firebaseUid, roomId);
        
        try {
            List<PlanningTimeSuggestionDTO> availableTimes = planningService.calculateAvailableTimeSlots(roomId);
            return ResponseEntity.ok(availableTimes);
        } catch (Exception e) {
            log.error("시간대 계산 중 오류 발생: {}", e.getMessage(), e);
            // 빈 배열 반환하여 클라이언트가 처리할 수 있도록 함
            return ResponseEntity.ok(new ArrayList<>());
        }
    }

    /**
     * 투표 완료 여부 확인 API - 모든 참가자가 투표를 완료했는지 확인합니다.
     */
    @GetMapping("/rooms/{roomId}/check-votes-completed")
    public ResponseEntity<Boolean> checkAllVotesCompleted(
            @PathVariable Integer roomId) {
        boolean completed = planningService.checkAllVotesCompleted(roomId);
        return ResponseEntity.ok(completed);
    }

    /**
     * 투표 결과로 최종 일정 선택 API - 가장 많은 득표를 받은
     * 시간을 최종 일정으로 자동 선택합니다.
     * 
     * @param useEarliestOnTie 동률 시 가장 빠른 시간을 선택할지 여부 (기본값: false)
     */
    @PostMapping("/rooms/{roomId}/select-final-by-votes")
    public ResponseEntity<PlanningFinalDTO> selectFinalScheduleByVotes(
            @PathVariable Integer roomId,
            @RequestParam(defaultValue = "false") Boolean useEarliestOnTie,
            Authentication auth) {
        String firebaseUid = auth.getName();
        log.info("사용자 {}가 방 {}의 최종 일정 선택 요청. 동률 시 가장 빠른 시간 선택: {}", 
               firebaseUid, roomId, useEarliestOnTie);
        PlanningFinalDTO finalSchedule = planningService.selectFinalScheduleByVotes(roomId, firebaseUid, useEarliestOnTie);
        return ResponseEntity.ok(finalSchedule);
    }

    /**
     * 최종 일정을 개인 일정에 추가 API - 사용자가 버튼을 통해 최종 일정을 자신의 개인 일정에 추가합니다.
     */
    @PostMapping("/rooms/{roomId}/add-to-my-schedule")
    public ResponseEntity<Long> addFinalScheduleToMySchedule(
            @PathVariable Integer roomId,
            Authentication auth) {
        String firebaseUid = auth.getName();
        Long scheduleId = planningService.addFinalScheduleToMySchedule(roomId, firebaseUid);
        return ResponseEntity.status(HttpStatus.CREATED).body(scheduleId);
    }

    @GetMapping("/rooms/{roomId}/user-votes/{userId}/count")
    public ResponseEntity<Integer> countUserVotesInRoom(
            @PathVariable Integer roomId,
            @PathVariable String userId) {
        return ResponseEntity.ok(planningService.countUserVotesInRoom(roomId, userId));
    }

    @GetMapping("/rooms/{roomId}/user-votes/{userId}/check")
    public ResponseEntity<Boolean> checkUserVoted(
            @PathVariable Integer roomId,
            @PathVariable String userId) {
        return ResponseEntity.ok(planningService.checkUserVoted(roomId, userId));
    }

    @DeleteMapping("/rooms/{roomId}/user-votes/{userId}")
    public ResponseEntity<Void> deleteUserVotesInRoom(
            @PathVariable Integer roomId,
            @PathVariable String userId) {
        int voteCount = planningService.countUserVotesInRoom(roomId, userId);
        if (voteCount > 0) {
            planningService.deleteUserVotesInRoom(roomId, userId);
        }
        return ResponseEntity.noContent().build();
    }
} 