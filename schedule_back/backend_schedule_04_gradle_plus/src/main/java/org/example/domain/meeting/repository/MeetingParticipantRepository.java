package org.example.domain.meeting.repository;

import org.example.domain.meeting.entity.MeetingParticipant;
import org.example.domain.meeting.entity.MeetingParticipantId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MeetingParticipantRepository extends JpaRepository<MeetingParticipant, MeetingParticipantId> {
    
    List<MeetingParticipant> findByRoomId(Integer roomId);
    
    List<MeetingParticipant> findByUserId(String userId);
    
    Optional<MeetingParticipant> findByRoomIdAndUserId(Integer roomId, String userId);
    
    @Query("SELECT mp FROM MeetingParticipant mp WHERE mp.roomId = :roomId AND mp.role = 'owner'")
    Optional<MeetingParticipant> findOwnerByRoomId(@Param("roomId") Integer roomId);
    
    void deleteByRoomIdAndUserId(Integer roomId, String userId);
} 