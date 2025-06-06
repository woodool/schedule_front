package org.example.domain.meeting.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.example.domain.meeting.dto.*;
import org.example.domain.meeting.entity.*;
import org.example.domain.meeting.exception.MeetingNotFoundException;
import org.example.domain.meeting.exception.UnauthorizedAccessException;
import org.example.domain.meeting.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class MeetingServiceImpl implements MeetingService {

    private final MeetingRoomRepository meetingRoomRepository;
    private final MeetingParticipantRepository participantRepository;
    private final MeetingAnnouncementRepository announcementRepository;
    private final MeetingScheduleRepository scheduleRepository;
    private final MeetingScheduleExceptionRepository exceptionRepository;
    
    @Override
    public MeetingRoomDTO createMeetingRoom(MeetingRoomDTO meetingRoomDTO, String creatorId) {
        MeetingRoom meetingRoom = new MeetingRoom();
        meetingRoom.setMeetingName(meetingRoomDTO.getMeetingName());
        meetingRoom.setDescription(meetingRoomDTO.getDescription());
        meetingRoom.setCapacity(meetingRoomDTO.getCapacity());
        meetingRoom.setStartDate(meetingRoomDTO.getStartDate());
        meetingRoom.setEndDate(meetingRoomDTO.getEndDate());
        meetingRoom.setRecurrenceStart(meetingRoomDTO.getRecurrenceStart());
        meetingRoom.setRecurrenceEnd(meetingRoomDTO.getRecurrenceEnd());
        meetingRoom.setTimeOfDay(meetingRoomDTO.getTimeOfDay());
        meetingRoom.setCategoryId(meetingRoomDTO.getCategoryId());
        meetingRoom.setPhotoUrl(meetingRoomDTO.getPhotoUrl());
        meetingRoom.setCreatedBy(creatorId);
        meetingRoom.setCreatedAt(LocalDateTime.now());
        meetingRoom.setInviteCode(UUID.randomUUID().toString().substring(0, 7));
        
        MeetingRoom savedRoom = meetingRoomRepository.save(meetingRoom);
        
        // 방장을 참여자로 추가
        MeetingParticipant creator = new MeetingParticipant();
        creator.setRoomId(savedRoom.getRoomId());
        creator.setUserId(creatorId);
        creator.setRole("owner");
        creator.setJoinedAt(LocalDateTime.now());
        participantRepository.save(creator);
        
        return convertToDTO(savedRoom);
    }
    
    @Override
    public MeetingRoomDTO getMeetingRoomById(Integer roomId) {
        MeetingRoom meetingRoom = meetingRoomRepository.findById(roomId)
                .orElseThrow(() -> new MeetingNotFoundException("Meeting room not found with id: " + roomId));
        return convertToDTO(meetingRoom);
    }
    
    @Override
    public List<MeetingRoomDTO> getUserMeetingRooms(String userId) {
        List<MeetingParticipant> participations = participantRepository.findByUserId(userId);
        return participations.stream()
                .map(p -> meetingRoomRepository.findById(p.getRoomId()))
                .filter(java.util.Optional::isPresent)
                .map(java.util.Optional::get)
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    public MeetingRoomDTO updateMeetingRoom(Integer roomId, MeetingRoomDTO meetingRoomDTO, String userId) {
        if (!isRoomOwner(roomId, userId)) {
            throw new UnauthorizedAccessException("Only room owner can update meeting room");
        }
        
        MeetingRoom meetingRoom = meetingRoomRepository.findById(roomId)
                .orElseThrow(() -> new MeetingNotFoundException("Meeting room not found with id: " + roomId));
        
        meetingRoom.setMeetingName(meetingRoomDTO.getMeetingName());
        meetingRoom.setDescription(meetingRoomDTO.getDescription());
        meetingRoom.setCapacity(meetingRoomDTO.getCapacity());
        meetingRoom.setStartDate(meetingRoomDTO.getStartDate());
        meetingRoom.setEndDate(meetingRoomDTO.getEndDate());
        
        return convertToDTO(meetingRoomRepository.save(meetingRoom));
    }
    
    @Override
    public void deleteMeetingRoom(Integer roomId, String userId) {
        if (!isRoomOwner(roomId, userId)) {
            throw new UnauthorizedAccessException("Only room owner can delete meeting room");
        }
        
        // 연관된 데이터 삭제
        // 참여자 삭제
        List<MeetingParticipant> participants = participantRepository.findByRoomId(roomId);
        participantRepository.deleteAll(participants);
        
        // 공지사항 삭제
        announcementRepository.deleteByRoomId(roomId);
        
        // 일정 삭제
        scheduleRepository.deleteByRoomId(roomId);
        
        // 미팅룸 삭제
        meetingRoomRepository.deleteById(roomId);
    }
    
    @Override
    public MeetingRoomDTO joinMeetingRoomByInviteCode(String inviteCode, String userId) {
        log.info("초대코드로 방 참여 시도 - 초대코드: {}, 사용자ID: {}", inviteCode, userId);
        
        MeetingRoom meetingRoom = meetingRoomRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> {
                    log.error("유효하지 않은 초대코드: {}", inviteCode);
                    return new MeetingNotFoundException("Invalid invite code");
                });
        
        log.info("방 찾음 - 방ID: {}, 방이름: {}", meetingRoom.getRoomId(), meetingRoom.getMeetingName());
        
        if (isRoomMember(meetingRoom.getRoomId(), userId)) {
            log.info("이미 방의 멤버임 - 방ID: {}, 사용자ID: {}", meetingRoom.getRoomId(), userId);
            return convertToDTO(meetingRoom);
        }
        
        MeetingParticipant participant = new MeetingParticipant();
        participant.setRoomId(meetingRoom.getRoomId());
        participant.setUserId(userId);
        participant.setRole("member");
        participant.setJoinedAt(LocalDateTime.now());
        
        participantRepository.save(participant);
        log.info("새 참가자 추가됨 - 방ID: {}, 사용자ID: {}", meetingRoom.getRoomId(), userId);
        
        return convertToDTO(meetingRoom);
    }
    
    @Override
    public List<MeetingParticipantDTO> getMeetingParticipants(Integer roomId) {
        List<MeetingParticipant> participants = participantRepository.findByRoomId(roomId);
        return participants.stream()
                .map(this::convertToParticipantDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    public MeetingParticipantDTO addMeetingParticipant(Integer roomId, String userId, String role) {
        if (!isRoomOwner(roomId, userId)) {
            throw new UnauthorizedAccessException("Only room owner can add participants");
        }
        
        MeetingParticipant participant = new MeetingParticipant();
        participant.setRoomId(roomId);
        participant.setUserId(userId);
        participant.setRole(role);
        participant.setJoinedAt(LocalDateTime.now());
        
        return convertToParticipantDTO(participantRepository.save(participant));
    }
    
    @Override
    public void removeMeetingParticipant(Integer roomId, String userId, String requesterId) {
        if (!isRoomOwner(roomId, requesterId) && !userId.equals(requesterId)) {
            throw new UnauthorizedAccessException("Unauthorized to remove participant");
        }
        
        participantRepository.deleteByRoomIdAndUserId(roomId, userId);
    }
    
    @Override
    public void updateParticipantRole(Integer roomId, String userId, String newRole, String requesterId) {
        if (!isRoomOwner(roomId, requesterId)) {
            throw new UnauthorizedAccessException("Only room owner can update roles");
        }
        
        MeetingParticipant participant = participantRepository.findByRoomIdAndUserId(roomId, userId)
                .orElseThrow(() -> new MeetingNotFoundException("Participant not found"));
        
        participant.setRole(newRole);
        participantRepository.save(participant);
    }
    
    @Override
    public List<MeetingAnnouncementDTO> getMeetingAnnouncements(Integer roomId) {
        List<MeetingAnnouncement> announcements = announcementRepository.findByRoomIdOrderByCreatedAtDesc(roomId);
        return announcements.stream()
                .map(this::convertToAnnouncementDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    public MeetingAnnouncementDTO addMeetingAnnouncement(Integer roomId, String content, String userId) {
        if (!isRoomOwner(roomId, userId)) {
            throw new UnauthorizedAccessException("Only room owner can add announcements");
        }
        
        MeetingAnnouncement announcement = new MeetingAnnouncement();
        announcement.setRoomId(roomId);
        announcement.setContent(content);
        announcement.setCreatedBy(userId);
        announcement.setCreatedAt(LocalDateTime.now());
        
        return convertToAnnouncementDTO(announcementRepository.save(announcement));
    }
    
    @Override
    public MeetingAnnouncementDTO updateMeetingAnnouncement(Integer announcementId, String content, String userId) {
        MeetingAnnouncement announcement = announcementRepository.findById(announcementId)
                .orElseThrow(() -> new MeetingNotFoundException("Announcement not found"));
        
        if (!isRoomOwner(announcement.getRoomId(), userId)) {
            throw new UnauthorizedAccessException("Only room owner can update announcements");
        }
        
        announcement.setContent(content);
        return convertToAnnouncementDTO(announcementRepository.save(announcement));
    }
    
    @Override
    public void deleteMeetingAnnouncement(Integer announcementId, String userId) {
        MeetingAnnouncement announcement = announcementRepository.findById(announcementId)
                .orElseThrow(() -> new MeetingNotFoundException("Announcement not found"));
        
        if (!isRoomOwner(announcement.getRoomId(), userId)) {
            throw new UnauthorizedAccessException("Only room owner can delete announcements");
        }
        
        announcementRepository.deleteById(announcementId);
    }
    
    @Override
    public List<MeetingScheduleDTO> getMeetingSchedules(Integer roomId) {
        List<MeetingSchedule> schedules = scheduleRepository.findByRoomId(roomId);
        return schedules.stream()
                .map(this::convertToScheduleDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    public List<MeetingScheduleDTO> getMeetingSchedulesByDateRange(Integer roomId, LocalDate startDate, LocalDate endDate) {
        List<MeetingSchedule> schedules = scheduleRepository.findByRoomIdAndDateRange(roomId, startDate, endDate);
        return schedules.stream()
                .map(this::convertToScheduleDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    public MeetingScheduleDTO addMeetingSchedule(MeetingScheduleDTO scheduleDTO, String userId) {
        if (!isRoomMember(scheduleDTO.getRoomId(), userId)) {
            throw new UnauthorizedAccessException("Only room members can add schedules");
        }
        
        MeetingSchedule schedule = new MeetingSchedule();
        schedule.setRoomId(scheduleDTO.getRoomId());
        schedule.setScheduleDate(scheduleDTO.getScheduleDate());
        schedule.setStartTime(scheduleDTO.getStartTime());
        schedule.setEndTime(scheduleDTO.getEndTime());
        schedule.setMemo(scheduleDTO.getMemo());
        schedule.setCreatedAt(LocalDateTime.now());
        
        return convertToScheduleDTO(scheduleRepository.save(schedule));
    }
    
    @Override
    public MeetingScheduleDTO updateMeetingSchedule(Integer scheduleId, MeetingScheduleDTO scheduleDTO, String userId) {
        MeetingSchedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new MeetingNotFoundException("Schedule not found"));
        
        if (!isRoomOwner(schedule.getRoomId(), userId)) {
            throw new UnauthorizedAccessException("Unauthorized to update schedule");
        }
        
        schedule.setScheduleDate(scheduleDTO.getScheduleDate());
        schedule.setStartTime(scheduleDTO.getStartTime());
        schedule.setEndTime(scheduleDTO.getEndTime());
        schedule.setMemo(scheduleDTO.getMemo());
        
        return convertToScheduleDTO(scheduleRepository.save(schedule));
    }
    
    @Override
    public void deleteMeetingSchedule(Integer scheduleId, String userId) {
        MeetingSchedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new MeetingNotFoundException("Schedule not found"));
        
        if (!isRoomOwner(schedule.getRoomId(), userId)) {
            throw new UnauthorizedAccessException("Unauthorized to delete schedule");
        }
        
        scheduleRepository.deleteById(scheduleId);
    }
    
    @Override
    public List<MeetingScheduleExceptionDTO> getScheduleExceptions(Integer scheduleId) {
        List<MeetingScheduleException> exceptions = exceptionRepository.findByScheduleId(scheduleId);
        return exceptions.stream()
                .map(this::convertToExceptionDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    public MeetingScheduleExceptionDTO addScheduleException(MeetingScheduleExceptionDTO exceptionDTO, String userId) {
        MeetingSchedule schedule = scheduleRepository.findById(exceptionDTO.getScheduleId())
                .orElseThrow(() -> new MeetingNotFoundException("Schedule not found"));
        
        if (!isRoomOwner(schedule.getRoomId(), userId)) {
            throw new UnauthorizedAccessException("Unauthorized to add schedule exception");
        }
        
        MeetingScheduleException exception = new MeetingScheduleException();
        exception.setScheduleId(exceptionDTO.getScheduleId());
        exception.setExceptionDate(exceptionDTO.getExceptionDate());
        exception.setIsDeleted(exceptionDTO.getIsDeleted());
        exception.setOverrideStartTime(exceptionDTO.getOverrideStartTime());
        exception.setOverrideEndTime(exceptionDTO.getOverrideEndTime());
        exception.setOverrideMemo(exceptionDTO.getOverrideMemo());
        exception.setApplyToFuture(exceptionDTO.getApplyToFuture());
        
        return convertToExceptionDTO(exceptionRepository.save(exception));
    }
    
    @Override
    public void deleteScheduleException(Integer exceptionId, String userId) {
        MeetingScheduleException exception = exceptionRepository.findById(exceptionId)
                .orElseThrow(() -> new MeetingNotFoundException("Schedule exception not found"));
        
        MeetingSchedule schedule = scheduleRepository.findById(exception.getScheduleId())
                .orElseThrow(() -> new MeetingNotFoundException("Schedule not found"));
        
        if (!isRoomOwner(schedule.getRoomId(), userId)) {
            throw new UnauthorizedAccessException("Unauthorized to delete schedule exception");
        }
        
        exceptionRepository.deleteById(exceptionId);
    }
    
    @Override
    @Transactional
    public void updateAnnouncement(Integer roomId, String announcement, String userId) {
        MeetingRoom room = meetingRoomRepository.findById(roomId)
            .orElseThrow(() -> new MeetingNotFoundException("Meeting room not found"));
            
        if (!isRoomOwner(roomId, userId)) {
            throw new UnauthorizedAccessException("Only room owner can update announcement");
        }
        
        room.setAnnouncement(announcement);
        meetingRoomRepository.save(room);
    }

    @Override
    public String getAnnouncement(Integer roomId) {
        MeetingRoom room = meetingRoomRepository.findById(roomId)
            .orElseThrow(() -> new MeetingNotFoundException("Meeting room not found"));
        return room.getAnnouncement();
    }

    @Override
    @Transactional
    public void updateMemo(Integer roomId, String memo, String userId) {
        MeetingRoom room = meetingRoomRepository.findById(roomId)
            .orElseThrow(() -> new MeetingNotFoundException("Meeting room not found"));
            
        if (!isRoomOwner(roomId, userId)) {
            throw new UnauthorizedAccessException("Only room owner can update memo");
        }
        
        room.setMemo(memo);
        meetingRoomRepository.save(room);
    }

    @Override
    public String getMemo(Integer roomId) {
        MeetingRoom room = meetingRoomRepository.findById(roomId)
            .orElseThrow(() -> new MeetingNotFoundException("Meeting room not found"));
        return room.getMemo();
    }
    
    // 헬퍼 메소드
    private boolean isRoomOwner(Integer roomId, String userId) {
        return participantRepository.findByRoomIdAndUserId(roomId, userId)
                .map(participant -> "owner".equals(participant.getRole()))
                .orElse(false);
    }
    
    private boolean isRoomMember(Integer roomId, String userId) {
        return participantRepository.findByRoomIdAndUserId(roomId, userId).isPresent();
    }
    
    private MeetingRoomDTO convertToDTO(MeetingRoom meetingRoom) {
        MeetingRoomDTO dto = new MeetingRoomDTO();
        dto.setRoomId(meetingRoom.getRoomId());
        dto.setPhotoUrl(meetingRoom.getPhotoUrl());
        dto.setMeetingName(meetingRoom.getMeetingName());
        dto.setDescription(meetingRoom.getDescription());
        dto.setAnnouncement(meetingRoom.getAnnouncement());
        dto.setMemo(meetingRoom.getMemo());
        dto.setCapacity(meetingRoom.getCapacity());
        dto.setStartDate(meetingRoom.getStartDate());
        dto.setEndDate(meetingRoom.getEndDate());
        dto.setRecurrenceStart(meetingRoom.getRecurrenceStart());
        dto.setRecurrenceEnd(meetingRoom.getRecurrenceEnd());
        dto.setTimeOfDay(meetingRoom.getTimeOfDay());
        dto.setCategoryId(meetingRoom.getCategoryId());
        dto.setCreatedBy(meetingRoom.getCreatedBy());
        dto.setCreatedAt(meetingRoom.getCreatedAt());
        dto.setInviteCode(meetingRoom.getInviteCode());
        
        // 참여자 수 설정
        int participantCount = meetingRoomRepository.countParticipantsByRoomId(meetingRoom.getRoomId());
        dto.setParticipantCount(participantCount);
        
        return dto;
    }
    
    private MeetingParticipantDTO convertToParticipantDTO(MeetingParticipant participant) {
        MeetingParticipantDTO dto = new MeetingParticipantDTO();
        dto.setRoomId(participant.getRoomId());
        dto.setUserId(participant.getUserId());
        dto.setRole(participant.getRole());
        dto.setJoinedAt(participant.getJoinedAt());
        return dto;
    }
    
    private MeetingAnnouncementDTO convertToAnnouncementDTO(MeetingAnnouncement announcement) {
        MeetingAnnouncementDTO dto = new MeetingAnnouncementDTO();
        dto.setAnnouncementId(announcement.getAnnouncementId());
        dto.setRoomId(announcement.getRoomId());
        dto.setContent(announcement.getContent());
        dto.setCreatedBy(announcement.getCreatedBy());
        dto.setCreatedAt(announcement.getCreatedAt());
        dto.setCreatorName(null);
        return dto;
    }
    
    private MeetingScheduleDTO convertToScheduleDTO(MeetingSchedule schedule) {
        MeetingScheduleDTO dto = new MeetingScheduleDTO();
        dto.setScheduleId(schedule.getScheduleId());
        dto.setRoomId(schedule.getRoomId());
        dto.setScheduleDate(schedule.getScheduleDate());
        dto.setStartTime(schedule.getStartTime());
        dto.setEndTime(schedule.getEndTime());
        dto.setMemo(schedule.getMemo());
        dto.setCreatedAt(schedule.getCreatedAt());
        
        // 예외 일정 여부 확인
        boolean hasException = !exceptionRepository.findByScheduleId(schedule.getScheduleId()).isEmpty();
        dto.setHasException(hasException);
        
        return dto;
    }
    
    private MeetingScheduleExceptionDTO convertToExceptionDTO(MeetingScheduleException exception) {
        MeetingScheduleExceptionDTO dto = new MeetingScheduleExceptionDTO();
        dto.setExceptionId(exception.getExceptionId());
        dto.setScheduleId(exception.getScheduleId());
        dto.setExceptionDate(exception.getExceptionDate());
        dto.setIsDeleted(exception.getIsDeleted());
        dto.setOverrideStartTime(exception.getOverrideStartTime());
        dto.setOverrideEndTime(exception.getOverrideEndTime());
        dto.setOverrideMemo(exception.getOverrideMemo());
        dto.setApplyToFuture(exception.getApplyToFuture());
        return dto;
    }
} 