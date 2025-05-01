package org.example.controller;

import lombok.RequiredArgsConstructor;
import org.example.dto.PostponeRequestDTO;
import org.example.dto.ScheduleDTO;
import org.example.entity.User;
import org.example.service.ScheduleService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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

    @PutMapping("/{scheduleId}")
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
}
