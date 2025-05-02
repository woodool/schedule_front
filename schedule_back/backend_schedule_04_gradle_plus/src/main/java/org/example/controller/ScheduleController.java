package org.example.controller;

import lombok.RequiredArgsConstructor;
import org.example.dto.PostponeRequestDTO;
import org.example.dto.ScheduleDTO;
import org.example.entity.User;
import org.example.service.ScheduleService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/schedules")
@RequiredArgsConstructor
public class ScheduleController {
    private final ScheduleService scheduleService;

    @GetMapping
    public ResponseEntity<List<ScheduleDTO>> getSchedules(Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(scheduleService.getSchedules(firebaseUid));
    }

    @PostMapping
    public ResponseEntity<ScheduleDTO> createSchedule(@RequestBody ScheduleDTO scheduleDTO, Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(scheduleService.createSchedule(scheduleDTO, firebaseUid));
    }

    @PutMapping("/{scheduleId}/postpone")
    public ResponseEntity<ScheduleDTO> postponeScheduleReminder(@PathVariable Long scheduleId, @RequestBody PostponeRequestDTO request, Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(scheduleService.postponeScheduleReminder(scheduleId, firebaseUid, request));
    }

    @PutMapping("/{scheduleId}")
    public ResponseEntity<ScheduleDTO> updateSchedule(@PathVariable Long scheduleId,
                                                       @RequestBody ScheduleDTO scheduleDTO,
                                                       Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(scheduleService.updateSchedule(scheduleId, scheduleDTO, firebaseUid));
    }

    @DeleteMapping("/{scheduleId}")
    public ResponseEntity<?> deleteSchedule(@PathVariable Long scheduleId, Authentication authentication) {
        try {
            String firebaseUid = authentication.getName();
            scheduleService.deleteSchedule(scheduleId, firebaseUid);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/{scheduleId}/exclude-occurrence")
    public ResponseEntity<?> excludeOccurrence(
            @PathVariable Long scheduleId,
            @RequestBody Map<String, String> payload,
            Authentication authentication) {
        try {
            String firebaseUid = authentication.getName();
            String excludeDateStr = payload.get("excludeDate");
            
            if (excludeDateStr == null) {
                return ResponseEntity.badRequest().body("excludeDate is required");
            }
            
            LocalDateTime excludeDate = LocalDateTime.parse(excludeDateStr);
            scheduleService.excludeOccurrence(scheduleId, excludeDate, firebaseUid);
            
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 일정 검색 API
     * 
     * @param query 검색할 텍스트
     * @param authentication 인증 정보
     * @return 검색된 일정 목록
     */
    @GetMapping("/search")
    public ResponseEntity<List<ScheduleDTO>> searchSchedules(@RequestParam String query, Authentication authentication) {
        try {
            String firebaseUid = authentication.getName();
            List<ScheduleDTO> searchResults = scheduleService.searchSchedules(query, firebaseUid);
            return ResponseEntity.ok(searchResults);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(null);
        }
    }
}
