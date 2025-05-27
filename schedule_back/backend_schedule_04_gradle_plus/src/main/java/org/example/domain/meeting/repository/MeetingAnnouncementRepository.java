package org.example.domain.meeting.repository;

import org.example.domain.meeting.entity.MeetingAnnouncement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MeetingAnnouncementRepository extends JpaRepository<MeetingAnnouncement, Integer> {
    
    List<MeetingAnnouncement> findByRoomIdOrderByCreatedAtDesc(Integer roomId);
    
    void deleteByRoomId(Integer roomId);
} 