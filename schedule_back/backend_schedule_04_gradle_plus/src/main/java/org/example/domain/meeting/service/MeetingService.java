package org.example.domain.meeting.service;

import org.example.domain.meeting.dto.*;

import java.time.LocalDate;
import java.util.List;

public interface MeetingService {

    // MeetingRoom 관련 메소드
    MeetingRoomDTO createMeetingRoom(MeetingRoomDTO meetingRoomDTO, String creatorId);
    
    MeetingRoomDTO getMeetingRoomById(Integer roomId);
    
    List<MeetingRoomDTO> getUserMeetingRooms(String userId);
    
    MeetingRoomDTO updateMeetingRoom(Integer roomId, MeetingRoomDTO meetingRoomDTO, String userId);
    
    void deleteMeetingRoom(Integer roomId, String userId);
    
    MeetingRoomDTO joinMeetingRoomByInviteCode(String inviteCode, String userId);
    
    // 공지사항 관련 메소드
    void updateAnnouncement(Integer roomId, String announcement, String userId);
    
    String getAnnouncement(Integer roomId);
    
    // 메모 관련 메소드
    void updateMemo(Integer roomId, String memo, String userId);
    
    String getMemo(Integer roomId);
    
    // MeetingParticipant 관련 메소드
    List<MeetingParticipantDTO> getMeetingParticipants(Integer roomId);
    
    MeetingParticipantDTO addMeetingParticipant(Integer roomId, String userId, String role);
    
    void removeMeetingParticipant(Integer roomId, String userId, String requesterId);
    
    void updateParticipantRole(Integer roomId, String userId, String newRole, String requesterId);
    
    // MeetingAnnouncement 관련 메소드
    List<MeetingAnnouncementDTO> getMeetingAnnouncements(Integer roomId);
    
    MeetingAnnouncementDTO addMeetingAnnouncement(Integer roomId, String content, String userId);
    
    MeetingAnnouncementDTO updateMeetingAnnouncement(Integer announcementId, String content, String userId);
    
    void deleteMeetingAnnouncement(Integer announcementId, String userId);
    
    // MeetingSchedule 관련 메소드
    List<MeetingScheduleDTO> getMeetingSchedules(Integer roomId);
    
    List<MeetingScheduleDTO> getMeetingSchedulesByDateRange(Integer roomId, LocalDate startDate, LocalDate endDate);
    
    MeetingScheduleDTO addMeetingSchedule(MeetingScheduleDTO scheduleDTO, String userId);
    
    MeetingScheduleDTO updateMeetingSchedule(Integer scheduleId, MeetingScheduleDTO scheduleDTO, String userId);
    
    void deleteMeetingSchedule(Integer scheduleId, String userId);
    
    // MeetingScheduleException 관련 메소드
    List<MeetingScheduleExceptionDTO> getScheduleExceptions(Integer scheduleId);
    
    MeetingScheduleExceptionDTO addScheduleException(MeetingScheduleExceptionDTO exceptionDTO, String userId);
    
    void deleteScheduleException(Integer exceptionId, String userId);
} 