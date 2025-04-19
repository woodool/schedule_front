package org.example.controller.Schedule;

import lombok.RequiredArgsConstructor;
import org.example.context.UserContext;
import org.example.dto.Schedule.UpdateScheduleDTO;
import org.example.service.ScheduleService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/schedules")
public class UpdateScheduleController {
    private final ScheduleService scheduleService;
    @PutMapping("/{id}")
    public ResponseEntity<?> updateSchedule(@PathVariable("id") Long scheduleId, @RequestBody UpdateScheduleDTO dto) {
        String firebaseUid = UserContext.getFirebaseUid();

        if (firebaseUid == null) {
            return ResponseEntity.status(401).body("사용자 인증 실패");
        }
        scheduleService.updateSchedule(scheduleId, dto, firebaseUid);
        return ResponseEntity.ok().build();
    }
}
