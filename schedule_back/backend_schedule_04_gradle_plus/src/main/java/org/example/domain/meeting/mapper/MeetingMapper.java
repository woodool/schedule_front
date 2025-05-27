package org.example.domain.meeting.mapper;

import org.example.domain.meeting.dto.*;
import org.example.domain.meeting.entity.*;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.factory.Mappers;

@Mapper(componentModel = "spring")
public interface MeetingMapper {

    MeetingMapper INSTANCE = Mappers.getMapper(MeetingMapper.class);

    // MeetingRoom 매핑
    @Mapping(target = "categoryName", ignore = true)
    @Mapping(target = "participantCount", ignore = true)
    MeetingRoomDTO toMeetingRoomDTO(MeetingRoom meetingRoom);
    
    MeetingRoom toMeetingRoom(MeetingRoomDTO meetingRoomDTO);
    
    void updateMeetingRoomFromDTO(MeetingRoomDTO dto, @MappingTarget MeetingRoom entity);

    // MeetingParticipant 매핑
    @Mapping(target = "username", ignore = true)
    @Mapping(target = "email", ignore = true)
    MeetingParticipantDTO toMeetingParticipantDTO(MeetingParticipant participant);
    
    MeetingParticipant toMeetingParticipant(MeetingParticipantDTO participantDTO);

    // MeetingAnnouncement 매핑
    @Mapping(target = "createdBy", ignore = true)
    @Mapping(target = "creatorName", ignore = true)
    MeetingAnnouncementDTO toMeetingAnnouncementDTO(MeetingAnnouncement announcement);
    
    MeetingAnnouncement toMeetingAnnouncement(MeetingAnnouncementDTO announcementDTO);

    // MeetingSchedule 매핑
    @Mapping(target = "hasException", ignore = true)
    MeetingScheduleDTO toMeetingScheduleDTO(MeetingSchedule schedule);
    
    MeetingSchedule toMeetingSchedule(MeetingScheduleDTO scheduleDTO);
    
    void updateMeetingScheduleFromDTO(MeetingScheduleDTO dto, @MappingTarget MeetingSchedule entity);

    // MeetingScheduleException 매핑
    MeetingScheduleExceptionDTO toMeetingScheduleExceptionDTO(MeetingScheduleException exception);
    
    MeetingScheduleException toMeetingScheduleException(MeetingScheduleExceptionDTO exceptionDTO);
} 