package org.example.domain.meeting.controller;

import lombok.RequiredArgsConstructor;
import org.example.domain.meeting.dto.*;
import org.example.domain.meeting.service.MeetingService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/meetings")
@RequiredArgsConstructor
public class MeetingController {

    private final MeetingService meetingService;

    // MeetingRoom 관련 엔드포인트
    @PostMapping
    public ResponseEntity<MeetingRoomDTO> createMeetingRoom(
            @RequestBody MeetingRoomDTO meetingRoomDTO,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(meetingService.createMeetingRoom(meetingRoomDTO, firebaseUid));
    }

    @GetMapping("/{roomId}")
    public ResponseEntity<MeetingRoomDTO> getMeetingRoom(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(meetingService.getMeetingRoomById(roomId));
    }

    @GetMapping("/user")
    public ResponseEntity<List<MeetingRoomDTO>> getUserMeetings(
            @RequestHeader("Firebase-UID") String firebaseUid) {
        return ResponseEntity.ok(meetingService.getUserMeetingRooms(firebaseUid));
    }

    @PutMapping("/{roomId}")
    public ResponseEntity<MeetingRoomDTO> updateMeetingRoom(
            @PathVariable Integer roomId,
            @RequestBody MeetingRoomDTO meetingRoomDTO,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        return ResponseEntity.ok(meetingService.updateMeetingRoom(roomId, meetingRoomDTO, firebaseUid));
    }

    @DeleteMapping("/{roomId}")
    public ResponseEntity<Void> deleteMeetingRoom(
            @PathVariable Integer roomId,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        meetingService.deleteMeetingRoom(roomId, firebaseUid);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/join/{inviteCode}")
    public ResponseEntity<MeetingRoomDTO> joinMeetingRoom(
            @PathVariable String inviteCode,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        return ResponseEntity.ok(meetingService.joinMeetingRoomByInviteCode(inviteCode, firebaseUid));
    }

    // MeetingParticipant 관련 엔드포인트
    @GetMapping("/{roomId}/participants")
    public ResponseEntity<List<MeetingParticipantDTO>> getMeetingParticipants(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(meetingService.getMeetingParticipants(roomId));
    }

    @PostMapping("/{roomId}/participants")
    public ResponseEntity<MeetingParticipantDTO> addMeetingParticipant(
            @PathVariable Integer roomId,
            @RequestParam String userId,
            @RequestParam String role,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(meetingService.addMeetingParticipant(roomId, userId, role));
    }

    @DeleteMapping("/{roomId}/participants/{userId}")
    public ResponseEntity<Void> removeMeetingParticipant(
            @PathVariable Integer roomId,
            @PathVariable String userId,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        meetingService.removeMeetingParticipant(roomId, userId, firebaseUid);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{roomId}/participants/{userId}/role")
    public ResponseEntity<Void> updateParticipantRole(
            @PathVariable Integer roomId,
            @PathVariable String userId,
            @RequestParam String role,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        meetingService.updateParticipantRole(roomId, userId, role, firebaseUid);
        return ResponseEntity.ok().build();
    }

    // MeetingAnnouncement 관련 엔드포인트
    @GetMapping("/{roomId}/announcements")
    public ResponseEntity<List<MeetingAnnouncementDTO>> getMeetingAnnouncements(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(meetingService.getMeetingAnnouncements(roomId));
    }

    @PostMapping("/{roomId}/announcements")
    public ResponseEntity<MeetingAnnouncementDTO> addMeetingAnnouncement(
            @PathVariable Integer roomId,
            @RequestParam String content,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(meetingService.addMeetingAnnouncement(roomId, content, firebaseUid));
    }

    @PutMapping("/announcements/{announcementId}")
    public ResponseEntity<MeetingAnnouncementDTO> updateMeetingAnnouncement(
            @PathVariable Integer announcementId,
            @RequestParam String content,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        return ResponseEntity.ok(meetingService.updateMeetingAnnouncement(announcementId, content, firebaseUid));
    }

    @DeleteMapping("/announcements/{announcementId}")
    public ResponseEntity<Void> deleteMeetingAnnouncement(
            @PathVariable Integer announcementId,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        meetingService.deleteMeetingAnnouncement(announcementId, firebaseUid);
        return ResponseEntity.noContent().build();
    }

    // MeetingSchedule 관련 엔드포인트
    @GetMapping("/{roomId}/schedules")
    public ResponseEntity<List<MeetingScheduleDTO>> getMeetingSchedules(
            @PathVariable Integer roomId) {
        return ResponseEntity.ok(meetingService.getMeetingSchedules(roomId));
    }

    @GetMapping("/{roomId}/schedules/range")
    public ResponseEntity<List<MeetingScheduleDTO>> getMeetingSchedulesByDateRange(
            @PathVariable Integer roomId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(meetingService.getMeetingSchedulesByDateRange(roomId, startDate, endDate));
    }

    @PostMapping("/{roomId}/schedules")
    public ResponseEntity<MeetingScheduleDTO> addMeetingSchedule(
            @PathVariable Integer roomId,
            @RequestBody MeetingScheduleDTO scheduleDTO,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        scheduleDTO.setRoomId(roomId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(meetingService.addMeetingSchedule(scheduleDTO, firebaseUid));
    }

    @PutMapping("/schedules/{scheduleId}")
    public ResponseEntity<MeetingScheduleDTO> updateMeetingSchedule(
            @PathVariable Integer scheduleId,
            @RequestBody MeetingScheduleDTO scheduleDTO,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        return ResponseEntity.ok(meetingService.updateMeetingSchedule(scheduleId, scheduleDTO, firebaseUid));
    }

    @DeleteMapping("/schedules/{scheduleId}")
    public ResponseEntity<Void> deleteMeetingSchedule(
            @PathVariable Integer scheduleId,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        meetingService.deleteMeetingSchedule(scheduleId, firebaseUid);
        return ResponseEntity.noContent().build();
    }

    // MeetingScheduleException 관련 엔드포인트
    @GetMapping("/schedules/{scheduleId}/exceptions")
    public ResponseEntity<List<MeetingScheduleExceptionDTO>> getScheduleExceptions(
            @PathVariable Integer scheduleId) {
        return ResponseEntity.ok(meetingService.getScheduleExceptions(scheduleId));
    }

    @PostMapping("/schedules/{scheduleId}/exceptions")
    public ResponseEntity<MeetingScheduleExceptionDTO> addScheduleException(
            @PathVariable Integer scheduleId,
            @RequestBody MeetingScheduleExceptionDTO exceptionDTO,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        exceptionDTO.setScheduleId(scheduleId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(meetingService.addScheduleException(exceptionDTO, firebaseUid));
    }

    @DeleteMapping("/exceptions/{exceptionId}")
    public ResponseEntity<Void> deleteScheduleException(
            @PathVariable Integer exceptionId,
            @RequestHeader("Firebase-UID") String firebaseUid) {
        meetingService.deleteScheduleException(exceptionId, firebaseUid);
        return ResponseEntity.noContent().build();
    }
} 