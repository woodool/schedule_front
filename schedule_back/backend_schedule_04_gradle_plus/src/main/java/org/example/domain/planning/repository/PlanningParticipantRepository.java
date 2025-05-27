package org.example.domain.planning.repository;

import org.example.domain.planning.entity.PlanningParticipant;
import org.example.domain.planning.entity.PlanningParticipantId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PlanningParticipantRepository extends JpaRepository<PlanningParticipant, PlanningParticipantId> {
    
    List<PlanningParticipant> findByRoomId(Integer roomId);
    
    List<PlanningParticipant> findByUserId(String userId);
    
    Optional<PlanningParticipant> findByRoomIdAndUserId(Integer roomId, String userId);
    
    void deleteByRoomIdAndUserId(Integer roomId, String userId);
    
    boolean existsByRoomIdAndUserId(Integer roomId, String userId);
} 