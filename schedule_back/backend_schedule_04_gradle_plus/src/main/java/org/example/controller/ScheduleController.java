package org.example.controller;

import lombok.RequiredArgsConstructor;
import org.example.dto.ScheduleDTO;
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
    public ResponseEntity<ScheduleDTO> updateSchedule(@PathVariable Long scheduleId,
                                                       @RequestBody ScheduleDTO scheduleDTO,
                                                       Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(scheduleService.updateSchedule(scheduleId, scheduleDTO, firebaseUid));
    }
}
