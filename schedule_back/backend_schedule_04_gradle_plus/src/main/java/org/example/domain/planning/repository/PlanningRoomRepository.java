package org.example.domain.planning.repository;

import org.example.domain.planning.entity.Phase;
import org.example.domain.planning.entity.PlanningRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface PlanningRoomRepository extends JpaRepository<PlanningRoom, Integer> {

    /* ── 기본 조회 ── */
    List<PlanningRoom> findByCreatedBy(String firebaseUid);

    @Query("""
           SELECT pr FROM PlanningRoom pr
           JOIN PlanningParticipant pp
             ON pr.roomId = pp.roomId
          WHERE pp.userId = :userId
           """)
    List<PlanningRoom> findAllByParticipantUserId(@Param("userId") String userId);

    Optional<PlanningRoom> findByInviteCode(String inviteCode);

    @Query("SELECT COUNT(pp) FROM PlanningParticipant pp WHERE pp.roomId = :roomId")
    int countParticipantsByRoomId(@Param("roomId") Integer roomId);

    @Query("SELECT CASE WHEN COUNT(pf) > 0 THEN true ELSE false END FROM PlanningFinal pf WHERE pf.roomId = :roomId")
    boolean existsFinalByRoomId(@Param("roomId") Integer roomId);

    /* ── Phase 기반 추가 메서드 ── */
    List<PlanningRoom> findByPhase(Phase phase);

    List<PlanningRoom> findByCreatedByAndPhase(String firebaseUid, Phase phase);
}
