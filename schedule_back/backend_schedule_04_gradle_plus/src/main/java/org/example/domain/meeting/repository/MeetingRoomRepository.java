package org.example.domain.meeting.repository;

import org.example.domain.meeting.entity.MeetingRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MeetingRoomRepository extends JpaRepository<MeetingRoom, Integer> {
    
    List<MeetingRoom> findByCreatedBy(String firebaseUid);
    
    @Query("SELECT mr FROM MeetingRoom mr JOIN MeetingParticipant mp ON mr.roomId = mp.roomId WHERE mp.userId = :userId")
    List<MeetingRoom> findAllByParticipantUserId(@Param("userId") String userId);
    
    Optional<MeetingRoom> findByInviteCode(String inviteCode);
    
    @Query("SELECT COUNT(mp) FROM MeetingParticipant mp WHERE mp.roomId = :roomId")
    int countParticipantsByRoomId(@Param("roomId") Integer roomId);
} 