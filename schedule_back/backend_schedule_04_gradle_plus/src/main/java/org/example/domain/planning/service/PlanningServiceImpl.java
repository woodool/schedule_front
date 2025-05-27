package org.example.domain.planning.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.example.domain.common.service.UserCalendarService;
import org.example.domain.planning.dto.*;
import org.example.domain.planning.entity.*;
import org.example.domain.planning.exception.*;
import org.example.domain.planning.mapper.PlanningMapper;
import org.example.domain.planning.repository.*;
import org.example.domain.schedule.dto.CreateScheduleRequestDTO;
import org.example.domain.schedule.entity.Schedule;
import org.example.domain.schedule.mapper.ScheduleMapper;
import org.example.domain.schedule.repository.ScheduleRepository;
import org.example.domain.user.User;
import org.example.domain.user.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.access.AccessDeniedException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.Optional;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Map;
import java.util.HashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class PlanningServiceImpl implements PlanningService {

    private final PlanningRoomRepository planningRoomRepository;
    private final PlanningParticipantRepository participantRepository;
    private final PlanningTimeSuggestionRepository timeSuggestionRepository;
    private final PlanningSuggestionVoteRepository suggestionVoteRepository;
    private final PlanningFinalRepository finalRepository;
    private final PlanningMapper planningMapper;
    private final UserCalendarService userCalendarService; // 사용자 일정 관리 서비스
    private final ScheduleRepository scheduleRepository; // 개인 일정 레포지토리
    private final UserRepository userRepository; // 사용자 레포지토리

    // PlanningRoom 관련 메소드 구현

    /**
     * 일정 계획 방 생성 - 새로운 일정 계획 방을 생성하고 방장을 참가자로 추가합니다.
     */
    @Override
    @Transactional
    public PlanningRoomDTO createPlanningRoom(PlanningRoomDTO dto, String creatorId) {

        String inviteCode = UUID.randomUUID().toString().substring(0, 8);

        PlanningRoom room = planningMapper.toPlanningRoom(dto);
        room.setCreatedBy(creatorId);
        room.setCreatedAt(LocalDateTime.now());
        room.setInviteCode(inviteCode);

        /* 📌 Phase 기본값 명시 */
        room.setPhase(Phase.ROOM);

        if (room.getTimeSlotUnit() == null) room.setTimeSlotUnit(60);

        PlanningRoom saved = planningRoomRepository.save(room);

        /* 방장을 참가자로 자동 등록 (기존 로직 유지) */
        User creator = userRepository.findByFirebaseUid(creatorId).orElse(null);
        String username = creator != null ? creator.getUsername() : "사용자";

        participantRepository.save(PlanningParticipant.builder()
                .roomId(saved.getRoomId())
                .userId(creatorId)
                .username(username)
                .joinedAt(LocalDateTime.now())
                .build());

        return planningMapper.toPlanningRoomDTO(saved);
    }

    @Override
    @Transactional
    public PlanningRoomDTO startVoting(Integer roomId, String requesterId) {

        PlanningRoom room = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        // 권한 체크 : 방장만 가능
        if (!room.getCreatedBy().equals(requesterId))
            throw new UnauthorizedAccessException("Only the room creator can start voting");

        if (room.getPhase() != Phase.ROOM)
            throw new IllegalStateException("Cannot start voting in phase: " + room.getPhase());

        // 1. 시간대 자동 계산
        calculateAvailableTimeSlots(roomId);

        // 2. Phase → VOTING
        room.setPhase(Phase.VOTING);
        planningRoomRepository.save(room);

        return planningMapper.toPlanningRoomDTO(room);
    }

    /**
     * 방 ID로 일정 계획 방 조회 - 특정 방 ID에 해당하는 일정 계획 방 정보를 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public PlanningRoomDTO getPlanningRoomById(Integer roomId) {
        PlanningRoom planningRoom = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        PlanningRoomDTO roomDTO = planningMapper.toPlanningRoomDTO(planningRoom);

        // 추가 정보 설정
        int participantCount = planningRoomRepository.countParticipantsByRoomId(roomId);
        boolean hasFinalSchedule = planningRoomRepository.existsFinalByRoomId(roomId);

        roomDTO.setParticipantCount(participantCount);
        roomDTO.setHasFinalSchedule(hasFinalSchedule);

        return roomDTO;
    }

    /**
     * 사용자가 참여 중인 일정 계획 방 목록 조회 - 특정 사용자가 참여하고 있는 모든 일정 계획 방을 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public List<PlanningRoomDTO> getUserPlanningRooms(String userId) {
        // 사용자가 참여중인 모든 일정 방 조회
        List<PlanningRoom> rooms = planningRoomRepository.findAllByParticipantUserId(userId);

        // 각 방에 대한 추가 정보 설정 및 DTO 변환
        return rooms.stream().map(room -> {
            PlanningRoomDTO dto = planningMapper.toPlanningRoomDTO(room);
            dto.setParticipantCount(planningRoomRepository.countParticipantsByRoomId(room.getRoomId()));
            dto.setHasFinalSchedule(planningRoomRepository.existsFinalByRoomId(room.getRoomId()));
            return dto;
        }).collect(Collectors.toList());
    }

    /**
     * 일정 계획 방 정보 수정 - 방장만 일정 계획 방의 정보를 수정할 수 있습니다.
     */
    @Override
    @Transactional
    public PlanningRoomDTO updatePlanningRoom(Integer roomId, PlanningRoomDTO planningRoomDTO, String userId) {
        // 방 존재 확인
        PlanningRoom planningRoom = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        // 권한 확인 (방장만 수정 가능)
        if (!planningRoom.getCreatedBy().equals(userId)) {
            throw new UnauthorizedAccessException("Only the room creator can update the room");
        }

        // 변경 불가능한 필드 보호
        String originalInviteCode = planningRoom.getInviteCode();
        String originalCreator = planningRoom.getCreatedBy();
        LocalDateTime originalCreatedAt = planningRoom.getCreatedAt();

        // 엔티티 수정
        planningMapper.updatePlanningRoomFromDTO(planningRoomDTO, planningRoom);

        // 보호 필드 복원
        planningRoom.setInviteCode(originalInviteCode);
        planningRoom.setCreatedBy(originalCreator);
        planningRoom.setCreatedAt(originalCreatedAt);

        // 저장
        PlanningRoom updatedRoom = planningRoomRepository.save(planningRoom);

        // DTO 변환 및 추가 정보 설정
        PlanningRoomDTO resultDTO = planningMapper.toPlanningRoomDTO(updatedRoom);
        resultDTO.setParticipantCount(planningRoomRepository.countParticipantsByRoomId(roomId));
        resultDTO.setHasFinalSchedule(planningRoomRepository.existsFinalByRoomId(roomId));

        return resultDTO;
    }

    /**
     * 일정 계획 방 삭제 - 방장만 일정 계획 방을 삭제할 수 있으며, 관련된 모든 데이터도 함께 삭제됩니다.
     */
    @Override
    @Transactional
    public void deletePlanningRoom(Integer roomId, String userId) {
        // 방 존재 확인
        PlanningRoom planningRoom = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        // 권한 확인 (방장만 삭제 가능)
        if (!planningRoom.getCreatedBy().equals(userId)) {
            throw new UnauthorizedAccessException("Only the room creator can delete the room");
        }

        // 관련 데이터 모두 삭제
        // 순서 중요: 외래 키 제약 때문에 자식 테이블부터 삭제
        finalRepository.findByRoomId(roomId).ifPresent(finalSchedule ->
                finalRepository.delete(finalSchedule));

        List<PlanningTimeSuggestion> suggestions = timeSuggestionRepository.findByRoomIdOrderByCreatedAtDesc(roomId);
        for (PlanningTimeSuggestion suggestion : suggestions) {
            suggestionVoteRepository.deleteBySuggestionId(suggestion.getSuggestionId());
        }

        timeSuggestionRepository.deleteByRoomId(roomId);
        participantRepository.findByRoomId(roomId).forEach(participant ->
                participantRepository.delete(participant));

        // 마지막으로 방 삭제
        planningRoomRepository.deleteById(roomId);
    }

    /**
     * 초대 코드로 일정 계획 방 참여 - 초대 코드를 사용하여 일정 계획 방에 새로운 참가자로 참여합니다.
     */
    @Override
    @Transactional
    public PlanningRoomDTO joinPlanningRoomByInviteCode(String inviteCode, String userId) {
        // 초대 코드로 방 찾기
        PlanningRoom planningRoom = planningRoomRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> new PlanningNotFoundException("Invalid invite code: " + inviteCode));

        // 이미 참여 중인지 확인
        if (participantRepository.findByRoomIdAndUserId(planningRoom.getRoomId(), userId).isPresent()) {
            // 이미 참여 중이면 방 정보만 반환하고 새로 추가하지 않음
            log.info("사용자 {}가 이미 방 {}에 참여 중입니다. 기존 참여 및 투표 상태를 유지합니다.", userId, planningRoom.getRoomId());

            PlanningRoomDTO roomDTO = planningMapper.toPlanningRoomDTO(planningRoom);
            int participantCount = planningRoomRepository.countParticipantsByRoomId(planningRoom.getRoomId());
            boolean hasFinalSchedule = planningRoomRepository.existsFinalByRoomId(planningRoom.getRoomId());

            roomDTO.setParticipantCount(participantCount);
            roomDTO.setHasFinalSchedule(hasFinalSchedule);

            return roomDTO;
        }

        // 참가자로 추가
        // 사용자 정보 조회하여 username 설정
        User joiningUser = userRepository.findByFirebaseUid(userId)
                .orElse(null);
        String username = joiningUser != null ? joiningUser.getUsername() : "사용자";

        PlanningParticipant participant = PlanningParticipant.builder()
                .roomId(planningRoom.getRoomId())
                .userId(userId)
                .username(username)
                .joinedAt(LocalDateTime.now())
                .build();
        participantRepository.save(participant);

        // DTO 변환 및 추가 정보 설정
        PlanningRoomDTO roomDTO = planningMapper.toPlanningRoomDTO(planningRoom);
        int newParticipantCount = planningRoomRepository.countParticipantsByRoomId(planningRoom.getRoomId());
        boolean hasFinalSchedule = planningRoomRepository.existsFinalByRoomId(planningRoom.getRoomId());

        roomDTO.setParticipantCount(newParticipantCount);
        roomDTO.setHasFinalSchedule(hasFinalSchedule);

        return roomDTO;
    }

    // PlanningParticipant 관련 메소드 구현

    /**
     * 참가자 목록 조회 - 특정 일정 계획 방의 모든 참가자 목록을 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public List<PlanningParticipantDTO> getPlanningParticipants(Integer roomId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            throw new PlanningNotFoundException(roomId);
        }

        // 참가자 목록 조회 및 DTO 변환
        List<PlanningParticipant> participants = participantRepository.findByRoomId(roomId);
        return planningMapper.toPlanningParticipantDTOList(participants);
    }

    /**
     * 참가자 추가 - 특정 일정 계획 방에 새로운 참가자를 추가합니다.
     */
    @Override
    @Transactional
    public PlanningParticipantDTO addPlanningParticipant(Integer roomId, String userId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            throw new PlanningNotFoundException(roomId);
        }

        // 이미 참여 중인지 확인
        if (participantRepository.findByRoomIdAndUserId(roomId, userId).isPresent()) {
            throw new IllegalStateException("User is already a participant in this room");
        }

        // 사용자 정보 조회하여 username 설정
        User addedUser = userRepository.findByFirebaseUid(userId)
                .orElse(null);
        String username = addedUser != null ? addedUser.getUsername() : "사용자";

        // 참가자 추가
        PlanningParticipant participant = PlanningParticipant.builder()
                .roomId(roomId)
                .userId(userId)
                .username(username) // username 필드 추가
                .joinedAt(LocalDateTime.now())
                .build();

        PlanningParticipant savedParticipant = participantRepository.save(participant);

        return planningMapper.toPlanningParticipantDTO(savedParticipant);
    }

    /**
     * 참가자 제거 - 방장이거나 본인 스스로 참가자 목록에서 제거할 수 있습니다. 방장이 나가면 방 전체가 삭제됩니다.
     */
    @Override
    @Transactional
    public void removePlanningParticipant(Integer roomId, String userId, String requesterId) {
        // 방 존재 확인
        PlanningRoom room = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        // 참가자 존재 확인
        PlanningParticipant participant = participantRepository.findByRoomIdAndUserId(roomId, userId)
                .orElseThrow(() -> new ParticipantNotFoundException(roomId, userId));

        // 권한 확인 (자기 자신이거나 방장만 삭제 가능)
        if (!userId.equals(requesterId) && !room.getCreatedBy().equals(requesterId)) {
            throw new UnauthorizedAccessException("Only the room creator or the participant themselves can remove a participant");
        }

        // 방장이 나가려는 경우 방을 삭제
        if (room.getCreatedBy().equals(userId)) {
            deletePlanningRoom(roomId, userId);
            return;
        }

        // 참가자 제거
        participantRepository.deleteByRoomIdAndUserId(roomId, userId);
    }

    // PlanningTimeSuggestion 관련 메소드 구현

    /**
     * 시간 제안 목록 조회 - 특정 방의 모든 자동 생성된 시간 제안 목록을 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public List<PlanningTimeSuggestionDTO> getPlanningTimeSuggestions(Integer roomId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            throw new PlanningNotFoundException(roomId);
        }

        // 시간 추천 목록 조회
        List<PlanningTimeSuggestion> suggestions = timeSuggestionRepository.findByRoomIdOrderByCreatedAtDesc(roomId);

        // DTO 변환
        return planningMapper.toPlanningTimeSuggestionDTOList(suggestions);
    }

    /**
     * 모든 참가자가 가능한 시간 제안 조회 - 모든 참가자가 참여 가능한 시간 제안만 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public List<PlanningTimeSuggestionDTO> getAllFreeTimeSuggestions(Integer roomId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            throw new PlanningNotFoundException(roomId);
        }

        // 모든 사용자가 비어있는 시간대 조회
        List<PlanningTimeSuggestion> suggestions = timeSuggestionRepository.findAllFreeTimesByRoomId(roomId);

        return planningMapper.toPlanningTimeSuggestionDTOList(suggestions);
    }

    /**
     * 인기 있는 시간 제안 조회 - 가장 많은 참가자가 참여 가능한 시간 제안순으로 정렬하여 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public List<PlanningTimeSuggestionDTO> getMostPopularTimeSuggestions(Integer roomId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            throw new PlanningNotFoundException(roomId);
        }

        // 가장 많은 사용자가 비어있는 시간대 조회 (freeCount 내림차순)
        List<PlanningTimeSuggestion> suggestions = timeSuggestionRepository.findByRoomIdOrderByFreeCountDesc(roomId);

        return planningMapper.toPlanningTimeSuggestionDTOList(suggestions);
    }

    /**
     * 일정 잡기 - 모든 참가자의 일정을 자동으로 비교하여 비어있는 시간대를 계산합니다.
     * 이 메소드는 명시적으로 호출되어야 하며, 참가자 변경 시 자동으로 호출되지 않습니다.
     * <p>
     * 트랜잭션 설명:
     * - REQUIRES_NEW: 새 트랜잭션을 시작하여 기존 트랜잭션과 분리
     * - rollbackFor = {}: 어떤 예외가 발생해도 롤백하지 않음 (빈 배열)
     */
    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = {})
    public List<PlanningTimeSuggestionDTO> calculateAvailableTimeSlots(Integer roomId) {
        List<PlanningTimeSuggestion> savedSuggestions = new ArrayList<>();

        try {
            // 방 정보 조회
            PlanningRoom room = planningRoomRepository.findById(roomId)
                    .orElseThrow(() -> new PlanningNotFoundException(roomId));

            // 참가자 목록 조회 전에 권한 체크
            String currentUserId = SecurityContextHolder.getContext().getAuthentication().getName();
            boolean isParticipant = participantRepository.existsByRoomIdAndUserId(roomId, currentUserId);
            
            if (!isParticipant) {
                log.warn("사용자 {}는 방 {}의 참가자가 아닙니다.", currentUserId, roomId);
                throw new AccessDeniedException("해당 방의 참가자가 아닙니다.");
            }

            try {
                // 기존 시간대 모두 삭제 - 별도 트랜잭션으로 처리
                deleteAllTimeSuggestionsForRoom(roomId);
            } catch (Exception e) {
                log.warn("기존 시간대 삭제 중 오류가 발생했으나 계속 진행합니다: {}", e.getMessage());
            }

            // 방의 설정된 기간 (startDate ~ endDate) 
            LocalDate startDate = room.getStartDate();
            LocalDate endDate = room.getEndDate();

            // 시간 슬롯 단위 (방 설정에서 가져옴)
            int timeSlotUnitMinutes = room.getTimeSlotUnit();

            // 일 단위인 경우(1440분 이상) 전체 날짜를 확인
            if (timeSlotUnitMinutes >= 1440) {
                return calculateDailyAvailableTimeSlots(roomId, room, startDate, endDate);
            }

            // 항상 30분 단위로 시간 슬롯 계산 (사용자가 설정한 값은 최종 필터링에만 사용)
            int calculationStepMinutes = 30;
            int slotDurationHours = calculationStepMinutes / 60;
            int slotDurationMinutes = calculationStepMinutes % 60;

            log.info("방 {} 에서 시간대 계산 시작. 기간: {} ~ {}, 계산단위: 30분, 표시단위: {}분",
                    roomId, startDate, endDate, timeSlotUnitMinutes);

            // 참가자 목록 조회
            List<PlanningParticipant> participants = participantRepository.findByRoomId(roomId);
            List<String> participantIds = participants.stream()
                    .map(PlanningParticipant::getUserId)
                    .collect(Collectors.toList());

            log.info("방 {} 의 참가자 수: {}, 참가자 ID: {}", roomId, participantIds.size(), participantIds);

            // 참가자가 있는 경우에만 시간대 계산
            if (!participantIds.isEmpty()) {
                // 날짜별로 순회
                for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
                    final LocalDate currentDate = date;  // for lambda capture
                    log.info("날짜 {} 의 시간대 계산 시작", currentDate);

                    // 시간대별로 순회 (오전 9시부터 오후 10시까지)
                    LocalTime currentTime = LocalTime.of(9, 0);
                    LocalTime endOfDay = LocalTime.of(22, 0);

                    while (!currentTime.isAfter(endOfDay)) {
                        // 슬롯 시작 시간과 종료 시간 계산
                        LocalTime startTime = currentTime;

                        // 슬롯 종료 시간 계산 (고정 30분 단위로)
                        LocalTime endTime = startTime.plusMinutes(calculationStepMinutes);

                        // 종료 시간이 하루 끝을 넘어가면 중단
                        if (endTime.isAfter(endOfDay)) {
                            break;
                        }

                        final LocalTime finalStartTime = startTime;  // for lambda capture
                        final LocalTime finalEndTime = endTime;      // for lambda capture
                        log.debug("시간 슬롯 확인: {} {} ~ {}", currentDate, finalStartTime, finalEndTime);

                        // 해당 시간대에 참여 가능한 참가자 수 확인
                        int freeCount = 0;
                        boolean isAllFree = true;

                        for (String userId : participantIds) {
                            try {
                                // 별도 트랜잭션으로 일정 확인 - 에러는 개별적으로 처리
                                boolean isFree = checkTimeSlotForUser(userId, currentDate, finalStartTime, finalEndTime, startDate, endDate);

                                if (isFree) {
                                    freeCount++;
                                    log.debug("참가자 {} 는 {} {} ~ {} 시간대에 가능합니다.", userId, currentDate, finalStartTime, finalEndTime);
                                } else {
                                    isAllFree = false;
                                    log.debug("참가자 {} 는 {} {} ~ {} 시간대에 불가능합니다.", userId, currentDate, finalStartTime, finalEndTime);
                                }
                            } catch (Exception e) {
                                log.error("사용자 {} 의 일정 충돌 확인 중 오류 발생: {}", userId, e.getMessage());
                                // 오류 발생 시 해당 사용자는 불가능한 것으로 간주하고 진행
                                isAllFree = false;
                            }
                        }

                        // 모든 참가자가 가능한 경우에만 시간 제안 생성 (수정)
                        if (isAllFree && freeCount == participantIds.size()) {
                            try {
                                // 안전하게 별도의 트랜잭션에서 데이터 저장
                                PlanningTimeSuggestion suggestion = saveTimeSuggestion(
                                        roomId, currentDate, finalStartTime, finalEndTime, freeCount, isAllFree);

                                if (suggestion != null) {
                                    savedSuggestions.add(suggestion);
                                    log.info("방 {} 에 시간대 추가: {} {} ~ {}, 가능 인원: {}/{}, 모두가능: {}",
                                            roomId, currentDate, finalStartTime, finalEndTime, freeCount, participantIds.size(), isAllFree);
                                }
                            } catch (Exception e) {
                                log.error("시간대 저장 중 오류 발생: {}", e.getMessage(), e);
                                // 개별 시간대 저장 실패는 무시하고 다음 시간대로 진행
                            }
                        } else {
                            log.debug("시간대 {} {} ~ {} 는 일부 또는 모든 참가자가 불가능하여 제외됨", currentDate, finalStartTime, finalEndTime);
                        }

                        // 다음 슬롯으로 이동 (항상 30분 단위로)
                        currentTime = currentTime.plusMinutes(calculationStepMinutes);
                    }
                }
            }

            log.info("방 {} 에서 총 {}개의 시간대를 생성했습니다.", roomId, savedSuggestions.size());
        } catch (Exception e) {
            log.error("시간대 계산 중 예외 발생: {}", e.getMessage(), e);
            // 예외를 던지지 않고 빈 목록 반환
            return planningMapper.toPlanningTimeSuggestionDTOList(savedSuggestions);
        }

        // DTO 변환 및 반환
        return planningMapper.toPlanningTimeSuggestionDTOList(savedSuggestions);
    }

    /**
     * 단일 사용자에 대해 시간대 확인 (분리된 트랜잭션)
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = {})
    protected boolean checkTimeSlotForUser(String userId, LocalDate date, LocalTime startTime, LocalTime endTime,
                                           LocalDate roomStartDate, LocalDate roomEndDate) {
        try {
            log.debug("일정 충돌 확인 요청 - 사용자: {}, 날짜: {}, 시간: {} ~ {}, 방 기간: {} ~ {}",
                    userId, date, startTime, endTime, roomStartDate, roomEndDate);

            // 사용자 존재 확인 - 간단히 널체크만 수행
            if (userId == null || userId.isEmpty()) {
                log.warn("사용자 ID가 비어있습니다.");
                return false;
            }

            // 사용자의 개인 Schedule 일정과 충돌 체크 - 방 기간 내 일정만 고려
            long scheduleOverlaps = 0;
            try {
                scheduleOverlaps = scheduleRepository.countOverlappingSchedulesInDateRange(
                        userId, date, startTime, endTime, roomStartDate, roomEndDate);
            } catch (Exception ex) {
                // SQL 오류 등 데이터베이스 관련 예외 발생 시 로그만 남기고 일정이 있는 것으로 처리
                log.error("일정 조회 중 데이터베이스 오류 발생: {}", ex.getMessage());
                log.debug("상세 오류: ", ex);
                return false;
            }

            if (scheduleOverlaps > 0) {
                log.debug("사용자 {} 의 {} 일자 {}~{} 시간대와 충돌하는 일정이 {}개 있습니다.",
                        userId, date, startTime, endTime, scheduleOverlaps);
            } else {
                log.debug("사용자 {} 의 {} 일자 {}~{} 시간대에 일정이 없습니다.",
                        userId, date, startTime, endTime);
            }

            // 개인 일정과 충돌이 없어야 true 반환
            return scheduleOverlaps == 0;
        } catch (Exception e) {
            log.error("사용자 {} 일정 확인 중 오류: {}", userId, e.getMessage());
            return false;
        }
    }

    /**
     * 시간대 제안 저장 (분리된 트랜잭션)
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = {})
    protected PlanningTimeSuggestion saveTimeSuggestion(Integer roomId, LocalDate suggestionDate,
                                                        LocalTime startTime, LocalTime endTime,
                                                        int freeCount, boolean isAllFree) {
        try {
            PlanningTimeSuggestion suggestion = PlanningTimeSuggestion.builder()
                    .roomId(roomId)
                    .suggestionDate(suggestionDate)
                    .startTime(startTime)
                    .endTime(endTime)
                    .freeCount(freeCount)
                    .isAllFree(isAllFree)
                    .createdAt(LocalDateTime.now())
                    .build();

            return timeSuggestionRepository.save(suggestion);
        } catch (Exception e) {
            log.error("시간대 저장 중 오류: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 방의 기존 시간대를 모두 삭제하는 헬퍼 메서드
     * 별도의 트랜잭션으로 처리해 메인 트랜잭션에 영향을 주지 않습니다.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = {})
    protected void deleteAllTimeSuggestionsForRoom(Integer roomId) {
        timeSuggestionRepository.deleteByRoomId(roomId);
        log.info("방 {}의 기존 시간대를 모두 삭제했습니다.", roomId);
    }

    /**
     * 일 단위 시간대 계산을 위한 별도 메서드
     * 1일, 2일, 3일 등 일 단위로 설정된 경우 하루 전체가 비어있는 날짜를 찾습니다.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = {})
    protected List<PlanningTimeSuggestionDTO> calculateDailyAvailableTimeSlots(Integer roomId, PlanningRoom room, LocalDate startDate, LocalDate endDate) {
        List<PlanningTimeSuggestion> savedSuggestions = new ArrayList<>();

        try {
            // 필요한 연속 일수 계산 (1440분=1일)
            int daysRequired = room.getTimeSlotUnit() / 1440;
            log.info("방 {} 에서 {}일 단위 일정 계산 시작. 기간: {} ~ {}", roomId, daysRequired, startDate, endDate);

            // 참가자 목록 조회
            List<PlanningParticipant> participants = participantRepository.findByRoomId(roomId);
            List<String> participantIds = participants.stream()
                    .map(PlanningParticipant::getUserId)
                    .collect(Collectors.toList());

            if (participantIds.isEmpty()) {
                log.warn("방 {}에 참가자가 없습니다.", roomId);
                return new ArrayList<>();
            }

            // 각 참가자의 일정 조회
            Map<String, List<Schedule>> userSchedules = new HashMap<>();
            for (String userId : participantIds) {
                List<Schedule> schedules = scheduleRepository.findSchedulesByUserIdAndDateRange(
                        userId, startDate, endDate);
                userSchedules.put(userId, schedules);
            }

            // 연속된 N일의 가능한 시작일을 찾음
            for (LocalDate currentDate = startDate; !currentDate.isAfter(endDate.minusDays(daysRequired - 1)); currentDate = currentDate.plusDays(1)) {
                boolean isAllDaysFree = true;

                // 연속된 N일 동안 모든 참가자가 하루 종일 가능한지 확인
                for (int day = 0; day < daysRequired; day++) {
                    LocalDate checkDate = currentDate.plusDays(day);

                    // 해당 날짜에 모든 참가자가 하루 종일 가능한지 확인
                    for (String userId : participantIds) {
                        List<Schedule> userDaySchedules = userSchedules.get(userId).stream()
                                .filter(s -> s.getStartTime().toLocalDate().equals(checkDate))
                                .collect(Collectors.toList());

                        if (!userDaySchedules.isEmpty()) {
                            isAllDaysFree = false;
                            break;
                        }
                    }

                    if (!isAllDaysFree) {
                        break;
                    }
                }

                if (isAllDaysFree) {
                    // 연속된 N일이 모두 가능한 경우, 시작일에 대한 제안 생성
                    try {
                        PlanningTimeSuggestion suggestion = PlanningTimeSuggestion.builder()
                                .roomId(roomId)
                                .suggestionDate(currentDate)
                                .startTime(LocalTime.of(0, 0)) // 시작 시간 00:00
                                .endTime(LocalTime.of(23, 59)) // 종료 시간 23:59
                                .isAllFree(true)
                                .freeCount(participantIds.size())
                                .voteCount(0)
                                .createdAt(LocalDateTime.now())
                                .build();

                        PlanningTimeSuggestion saved = timeSuggestionRepository.save(suggestion);
                        savedSuggestions.add(saved);
                        log.info("방 {} 에 {}일 단위 일정 추가: 시작일={}, 연속 일수={}", roomId, daysRequired, currentDate, daysRequired);
                    } catch (Exception e) {
                        log.error("일 단위 시간대 저장 중 오류: {}", e.getMessage());
                    }
                }
            }

            return planningMapper.toPlanningTimeSuggestionDTOList(savedSuggestions);
        } catch (Exception e) {
            log.error("일 단위 시간대 계산 중 예외 발생: {}", e.getMessage(), e);
            return planningMapper.toPlanningTimeSuggestionDTOList(savedSuggestions);
        }
    }

    // PlanningFinal 관련 메소드 구현

    /**
     * 최종 일정 조회 - 특정 방의 최종 확정된 일정을 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public PlanningFinalDTO getFinalSchedule(Integer roomId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            throw new PlanningNotFoundException(roomId);
        }

        // 최종 일정 조회
        PlanningFinal finalSchedule = finalRepository.findByRoomId(roomId)
                .orElseThrow(() -> new FinalScheduleNotFoundException(roomId));

        // DTO 변환 및 추가 정보 설정
        PlanningFinalDTO finalDTO = planningMapper.toPlanningFinalDTO(finalSchedule);

        // 방 이름 설정
        planningRoomRepository.findById(roomId).ifPresent(room -> {
            finalDTO.setRoomName(room.getRoomName());
        });

        return finalDTO;
    }

    /**
     * 사용자의 모든 최종 일정 조회 - 특정 사용자가 참여한 모든 방의 최종 확정된 일정 목록을 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public List<PlanningFinalDTO> getUserFinalSchedules(String userId) {
        // 사용자가 참여한 방의 최종 일정 목록 조회
        List<PlanningFinal> finalSchedules = finalRepository.findByParticipantId(userId);

        // DTO 변환 및 추가 정보 설정
        List<PlanningFinalDTO> finalDTOs = new ArrayList<>();

        for (PlanningFinal finalSchedule : finalSchedules) {
            PlanningFinalDTO dto = planningMapper.toPlanningFinalDTO(finalSchedule);

            // 방 이름 설정
            planningRoomRepository.findById(finalSchedule.getRoomId()).ifPresent(room -> {
                dto.setRoomName(room.getRoomName());
            });

            finalDTOs.add(dto);
        }

        return finalDTOs;
    }

    /**
     * 날짜 범위로 사용자의 최종 일정 조회 - 특정 사용자의 특정 날짜 범위의 최종 확정된 일정 목록을 조회합니다.
     */
    @Override
    @Transactional(readOnly = true)
    public List<PlanningFinalDTO> getUserFinalSchedulesByDateRange(String userId, LocalDate startDate, LocalDate endDate) {
        // 사용자가 참여한 방의 최종 일정 중 특정 날짜 범위의 일정 조회
        List<PlanningFinal> finalSchedules = finalRepository.findByParticipantIdAndDateRange(userId, startDate, endDate);

        // DTO 변환 및 추가 정보 설정
        List<PlanningFinalDTO> finalDTOs = new ArrayList<>();

        for (PlanningFinal finalSchedule : finalSchedules) {
            PlanningFinalDTO dto = planningMapper.toPlanningFinalDTO(finalSchedule);

            // 방 이름 설정
            planningRoomRepository.findById(finalSchedule.getRoomId()).ifPresent(room -> {
                dto.setRoomName(room.getRoomName());
            });

            finalDTOs.add(dto);
        }

        return finalDTOs;
    }

    /**
     * 최종 일정 생성 - 사용자가 최종 일정을 확정하여 생성합니다.
     */
    @Override
    @Transactional
    public PlanningFinalDTO createFinalSchedule(Integer roomId, PlanningFinalDTO finalDTO, String userId) {
        // 방 존재 확인
        PlanningRoom room = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        // 방장 권한 체크 제거

        // 이미 최종 일정이 있는지 확인
        finalRepository.findByRoomId(roomId).ifPresent(existingFinal -> {
            throw new IllegalStateException("Final schedule already exists for this room");
        });

        // 엔티티 생성 및 저장
        PlanningFinal finalSchedule = planningMapper.toPlanningFinal(finalDTO);
        finalSchedule.setRoomId(roomId);
        finalSchedule.setFinalizedAt(LocalDateTime.now());

        PlanningFinal savedFinal = finalRepository.save(finalSchedule);

        // DTO 변환 및 추가 정보 설정
        PlanningFinalDTO resultDTO = planningMapper.toPlanningFinalDTO(savedFinal);
        resultDTO.setRoomName(room.getRoomName());

        // 자동 일정 추가 제거 - 사용자가 버튼을 통해 명시적으로 추가하도록 변경
        // addFinalScheduleToParticipantSchedules(room, savedFinal);

        return resultDTO;
    }

    /**
     * 최종 일정 수정 - 사용자가 이미 확정된 최종 일정을 수정합니다.
     */
    @Override
    @Transactional
    public PlanningFinalDTO updateFinalSchedule(Integer roomId, PlanningFinalDTO finalDTO, String userId) {
        // 방 존재 확인
        PlanningRoom room = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        // 방장 권한 체크 제거

        // 최종 일정 존재 확인
        PlanningFinal finalSchedule = finalRepository.findByRoomId(roomId)
                .orElseThrow(() -> new FinalScheduleNotFoundException(roomId));

        // 엔티티 수정
        finalSchedule.setFinalDate(finalDTO.getFinalDate());
        finalSchedule.setStartTime(finalDTO.getStartTime());
        finalSchedule.setEndTime(finalDTO.getEndTime());
        finalSchedule.setFinalizedAt(LocalDateTime.now());

        PlanningFinal updatedFinal = finalRepository.save(finalSchedule);

        // DTO 변환 및 추가 정보 설정
        PlanningFinalDTO resultDTO = planningMapper.toPlanningFinalDTO(updatedFinal);
        resultDTO.setRoomName(room.getRoomName());

        return resultDTO;
    }

    /**
     * 최종 일정 삭제 - 사용자가 최종 확정된 일정을 삭제합니다.
     */
    @Override
    @Transactional
    public void deleteFinalSchedule(Integer roomId, String userId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            throw new PlanningNotFoundException(roomId);
        }

        // 방장 권한 체크 제거

        // 최종 일정 존재 확인
        PlanningFinal finalSchedule = finalRepository.findByRoomId(roomId)
                .orElseThrow(() -> new FinalScheduleNotFoundException(roomId));

        // 삭제
        finalRepository.delete(finalSchedule);
    }

    // 헬퍼 메소드

    /**
     * 방장 여부 확인 - 주어진 사용자가 해당 방의 방장인지 확인합니다.
     */
    private boolean isRoomCreator(Integer roomId, String userId) {
        return planningRoomRepository.findById(roomId)
                .map(room -> room.getCreatedBy().equals(userId))
                .orElse(false);
    }

    /**
     * 방 참가자 여부 확인 - 주어진 사용자가 해당 방의 참가자인지 확인합니다.
     */

    private PlanningTimeSuggestion resolveMostVotedSuggestion(Integer roomId, boolean earliestOnTie) {
        if (earliestOnTie) {
            List<PlanningTimeSuggestion> topList =
                    timeSuggestionRepository.findTopVotedSuggestionsForRoom(roomId);
            int max = topList.get(0).getVoteCount();
            return topList.stream()
                    .filter(s -> s.getVoteCount() == max)
                    .min(Comparator
                            .comparing(PlanningTimeSuggestion::getSuggestionDate)
                            .thenComparing(PlanningTimeSuggestion::getStartTime))
                    .orElse(topList.get(0));
        } else {
            return timeSuggestionRepository
                    .findTopByRoomIdOrderByVoteCountDesc(roomId)
                    .orElseThrow(() -> new IllegalStateException("No voted suggestions"));
        }
    }

    private boolean isRoomParticipant(Integer roomId, String userId) {
        return participantRepository.findByRoomIdAndUserId(roomId, userId).isPresent();
    }


    @Override
    @Transactional
    public PlanningSuggestionVoteDTO voteForSuggestion(Integer roomId,
                                                       Integer suggestionId,
                                                       String userId,
                                                       Boolean voteFlag) {

        /* ✔️ 기존 검증‧저장 로직 그대로 유지 */
        PlanningTimeSuggestion suggestion = timeSuggestionRepository.findById(suggestionId)
                .orElseThrow(() -> new TimeSuggestionNotFoundException(suggestionId));

        if (!suggestion.getRoomId().equals(roomId))
            throw new IllegalArgumentException("Suggestion does not belong to room " + roomId);

        if (!isRoomParticipant(roomId, userId))
            throw new UnauthorizedAccessException("Only participants can vote");

        PlanningSuggestionVote vote = suggestionVoteRepository
                .findByRoomIdAndSuggestionIdAndUserId(roomId, suggestionId, userId)
                .orElse(PlanningSuggestionVote.builder()
                        .roomId(roomId)
                        .suggestionId(suggestionId)
                        .userId(userId)
                        .build());

        vote.setVoteFlag(voteFlag);
        vote.setVotedAt(LocalDateTime.now());

        PlanningSuggestionVote saved = suggestionVoteRepository.save(vote);

        /* 📌 Phase 업데이트 로직 */
        PlanningRoom room = planningRoomRepository.findById(roomId).orElseThrow();
        
        // 현재 사용자가 실제로 투표했는지 확인
        boolean hasUserVoted = suggestionVoteRepository.checkUserVoted(roomId, userId);
        
        if (checkAllVotesCompleted(roomId)) {
            room.setPhase(Phase.RESULT);                 // 전원 투표 → RESULT
        } else if (hasUserVoted) {
            room.setPhase(Phase.WAITING);                // 현재 사용자가 투표 완료 → WAITING
        }
        planningRoomRepository.save(room);

        return planningMapper.toPlanningSuggestionVoteDTO(saved);
    }

    @Override
    @Transactional
    public void deleteVote(Integer roomId, Integer suggestionId, String userId) {
        suggestionVoteRepository.deleteVote(roomId, suggestionId, userId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<PlanningSuggestionVoteDTO> getVotesForSuggestion(Integer roomId, Integer suggestionId) {
        List<PlanningSuggestionVote> votes = suggestionVoteRepository.findByRoomIdAndSuggestionId(roomId, suggestionId);
        return planningMapper.toPlanningSuggestionVoteDTOList(votes);
    }

    // 투표수 업데이트 헬퍼 메소드
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    protected void updateSuggestionVoteCount(Integer roomId) {
        timeSuggestionRepository.findById(roomId).ifPresent(suggestion -> {
            int positiveVoteCount = suggestionVoteRepository.countPositiveVotes(roomId, suggestion.getSuggestionId());
            suggestion.setVoteCount(positiveVoteCount);

            timeSuggestionRepository.save(suggestion);
        });
    }

    @Override
    @Transactional
    public PlanningFinalDTO selectFinalScheduleByVotes(Integer roomId,
                                                       String requesterId,
                                                       Boolean useEarliestOnTie) {

        PlanningRoom room = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        if (finalRepository.findByRoomId(roomId).isPresent())
            throw new IllegalStateException("Final schedule already exists");

        if (!checkAllVotesCompleted(roomId))
            throw new IllegalStateException("Not all participants have voted");

        /* ✔️ 기존 득표수 집계 알고리즘 유지 */
        PlanningTimeSuggestion winner = resolveMostVotedSuggestion(roomId, useEarliestOnTie);

        PlanningFinal finalSchedule = finalRepository.save(PlanningFinal.builder()
                .roomId(roomId)
                .finalDate(winner.getSuggestionDate())
                .startTime(winner.getStartTime())
                .endTime(winner.getEndTime())
                .finalizedAt(LocalDateTime.now())
                .build());

        /* 📌 Phase → RESULT */
        room.setPhase(Phase.RESULT);
        planningRoomRepository.save(room);

        PlanningFinalDTO dto = planningMapper.toPlanningFinalDTO(finalSchedule);
        dto.setRoomName(room.getRoomName());
        return dto;
    }

    /**
     * 최종 일정을 모든 참가자의 개인 일정에 추가하는 헬퍼 메소드
     */
    private void addFinalScheduleToParticipantSchedules(PlanningRoom room, PlanningFinal finalSchedule) {
        // 일정 계획방의 모든 참가자 조회
        List<PlanningParticipant> participants = participantRepository.findByRoomId(room.getRoomId());

        // 시작 시간과 종료 시간 계산
        LocalDateTime startDateTime = LocalDateTime.of(finalSchedule.getFinalDate(), finalSchedule.getStartTime());
        LocalDateTime endDateTime = LocalDateTime.of(finalSchedule.getFinalDate(), finalSchedule.getEndTime());

        // 카테고리 ID 사용 (없으면 기본값 19 사용)
        Integer categoryId = room.getCategoryId() != null ? room.getCategoryId() : 19;

        // 우선순위 사용 (없으면 기본값 2 사용)
        Integer priority = room.getPriority() != null ? room.getPriority() : 2;

        // 알림 시간 (10분 전)
        Integer reminderMinutesBefore = 10;

        // 각 참가자의 개인 일정에 추가
        for (PlanningParticipant participant : participants) {
            String firebaseUid = participant.getUserId();
            User user = userRepository.findByFirebaseUid(firebaseUid)
                    .orElse(null);

            if (user != null) {
                // 개인 일정 DTO 생성
                CreateScheduleRequestDTO scheduleDTO = new CreateScheduleRequestDTO();
                scheduleDTO.setTitle(room.getRoomName());
                scheduleDTO.setDescription("");
                scheduleDTO.setCategoryId(categoryId);
                scheduleDTO.setStartTime(startDateTime);
                scheduleDTO.setEndTime(endDateTime);
                scheduleDTO.setPriority(priority);
                scheduleDTO.setDisplayOnCalendar(true);
                scheduleDTO.setReminderMinutesBefore(reminderMinutesBefore);
                scheduleDTO.setScheduleType("MEETING"); // 모임일정으로 설정

                // 개인 일정 엔티티로 변환 및 저장
                Schedule schedule = ScheduleMapper.toEntity(scheduleDTO, firebaseUid);
                schedule.setUser(user);
                scheduleRepository.save(schedule);

                log.info("사용자 {}의 개인 일정에 그룹 일정 {} 추가 완료", firebaseUid, room.getRoomName());
            }
        }
    }

    /**
     * 최종 일정을 개인 일정에 추가
     * 사용자가 버튼을 통해 명시적으로 최종 일정을 자신의 개인 일정에 추가합니다.
     *
     * @param roomId 방 ID
     * @param userId 사용자 ID
     * @return 추가된 일정의 ID
     */
    @Override
    @Transactional
    public Long addFinalScheduleToMySchedule(Integer roomId, String userId) {
        // 방 존재 확인
        PlanningRoom room = planningRoomRepository.findById(roomId)
                .orElseThrow(() -> new PlanningNotFoundException(roomId));

        // 최종 일정 존재 확인
        PlanningFinal finalSchedule = finalRepository.findByRoomId(roomId)
                .orElseThrow(() -> new FinalScheduleNotFoundException(roomId));

        // 사용자가 방 참가자인지 확인
        if (!isRoomParticipant(roomId, userId)) {
            throw new UnauthorizedAccessException("Only room participants can add final schedule to their personal calendar");
        }

        // 시작 시간과 종료 시간 계산
        LocalDateTime startDateTime = LocalDateTime.of(finalSchedule.getFinalDate(), finalSchedule.getStartTime());
        LocalDateTime endDateTime = LocalDateTime.of(finalSchedule.getFinalDate(), finalSchedule.getEndTime());

        // 카테고리 ID 사용 (없으면 기본값 19 사용)
        Integer categoryId = room.getCategoryId() != null ? room.getCategoryId() : 19;

        // 우선순위 사용 (없으면 기본값 2 사용)
        Integer priority = room.getPriority() != null ? room.getPriority() : 2;

        // 알림 시간 (10분 전)
        Integer reminderMinutesBefore = 10;

        // 사용자 조회
        User user = userRepository.findByFirebaseUid(userId)
                .orElseThrow(() -> new IllegalStateException("User not found with id: " + userId));

        // 개인 일정 DTO 생성
        CreateScheduleRequestDTO scheduleDTO = new CreateScheduleRequestDTO();
        scheduleDTO.setTitle(room.getRoomName());
        scheduleDTO.setDescription("");
        scheduleDTO.setCategoryId(categoryId);
        scheduleDTO.setStartTime(startDateTime);
        scheduleDTO.setEndTime(endDateTime);
        scheduleDTO.setPriority(priority);
        scheduleDTO.setDisplayOnCalendar(true);
        scheduleDTO.setReminderMinutesBefore(reminderMinutesBefore);
        scheduleDTO.setScheduleType("MEETING"); // 모임일정으로 설정

        // 개인 일정 엔티티로 변환 및 저장
        Schedule schedule = ScheduleMapper.toEntity(scheduleDTO, userId);
        schedule.setUser(user);
        Schedule savedSchedule = scheduleRepository.save(schedule);

        log.info("사용자 {}의 개인 일정에 그룹 일정 {} 추가 완료", userId, room.getRoomName());

        return savedSchedule.getId();
    }

    @Override
    @Transactional(readOnly = true)
    public int countUserVotesInRoom(Integer roomId, String userId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            log.warn("방 {}이 존재하지 않습니다", roomId);
            return 0;
        }

        // 사용자가 방 참가자인지 확인
        boolean isParticipant = participantRepository.findByRoomIdAndUserId(roomId, userId).isPresent();
        if (!isParticipant) {
            log.warn("사용자 {}는 방 {}의 참가자가 아닙니다", userId, roomId);
            return 0;
        }

        // 해당 사용자가 해당 방의 어떤 시간대에든 투표한 횟수를 반환
        int voteCount = suggestionVoteRepository.countVotesByRoomIdAndUserId(roomId, userId);
        log.info("방 {}에서 사용자 {}의 투표 수: {}", roomId, userId, voteCount);

        return voteCount;
    }

    @Override
    @Transactional
    public void deleteUserVotesInRoom(Integer roomId, String userId) {
        // 방 존재 확인
        if (!planningRoomRepository.existsById(roomId)) {
            throw new PlanningNotFoundException(roomId);
        }

        // 사용자가 방 참가자인지 확인
        if (!isRoomParticipant(roomId, userId)) {
            throw new UnauthorizedAccessException("User is not a participant of this room");
        }

        // 현재 요청하는 사용자의 ID 가져오기
        String currentUserId = SecurityContextHolder.getContext().getAuthentication().getName();
        
        // 본인의 투표만 삭제할 수 있도록 체크
        if (!currentUserId.equals(userId)) {
            throw new UnauthorizedAccessException("You can only delete your own votes");
        }

        // 투표 삭제 실행
        suggestionVoteRepository.deleteUserVotesInRoom(roomId, userId);
        log.info("사용자 {}의 방 {} 투표가 모두 삭제되었습니다.", userId, roomId);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean checkUserVoted(Integer roomId, String userId) {
        return suggestionVoteRepository.checkUserVoted(roomId, userId);
    }

    // 중복된 메서드 제거
    private int getPositiveVoteCount(Integer roomId, Integer suggestionId) {
        return suggestionVoteRepository.countPositiveVotes(roomId, suggestionId);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean checkAllVotesCompleted(Integer roomId) {
        // 방의 모든 참가자 조회
        List<PlanningParticipant> participants = participantRepository.findByRoomId(roomId);

        if (participants.isEmpty()) {
            log.warn("방 {}에 참가자가 없습니다.", roomId);
            return false;
        }

        log.info("방 {} 투표 완료 확인 - 참가자 수: {}", roomId, participants.size());

        // 각 참가자가 최소 하나의 시간대에 투표했는지 확인
        for (PlanningParticipant participant : participants) {
            String userId = participant.getUserId();

            // 해당 참가자가 해당 방의 어떤 시간대에든 투표했는지 확인 
            int userVoteCount = suggestionVoteRepository.countVotesByRoomIdAndUserId(roomId, userId);

            log.info("참가자 {} 투표 수: {}", userId, userVoteCount);

            if (userVoteCount == 0) {
                log.info("참가자 {}가 아직 투표하지 않았습니다", userId);
                return false; // 한 명이라도 투표하지 않은 참가자가 있으면 false
            }
        }

        log.info("방 {} - 모든 참가자가 최소 하나 이상의 시간대에 투표 완료", roomId);
        return true; // 모든 참가자가 최소 하나 이상의 시간대에 투표 완료
    }

    @Override
    @Transactional
    public void deleteTimeSuggestion(Integer suggestionId, String userId) {
        // 제안 존재 확인
        PlanningTimeSuggestion suggestion = timeSuggestionRepository.findById(suggestionId)
                .orElseThrow(() -> new TimeSuggestionNotFoundException(suggestionId));

        // 방 정보 가져오기
        PlanningRoom room = planningRoomRepository.findById(suggestion.getRoomId())
                .orElseThrow(() -> new PlanningNotFoundException(suggestion.getRoomId()));

        // 권한 확인 (방장만 삭제 가능)
        boolean isCreator = room.getCreatedBy().equals(userId);

        if (!isCreator) {
            throw new UnauthorizedAccessException("Only the room creator can delete time suggestions");
        }

        // 관련 투표 먼저 삭제
        suggestionVoteRepository.deleteBySuggestionId(suggestionId);

        // 시간 제안 삭제
        timeSuggestionRepository.deleteById(suggestionId);
    }
}