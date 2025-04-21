package org.example.controller.Schedule;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.dto.Schedule.AddScheduleDTO;
import org.example.context.UserContext;
import org.example.service.ScheduleService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/schedules")
public class AddScheduleController {
    private final ScheduleService scheduleService;

    @PostMapping
    public ResponseEntity<?> addSchedule(@Valid @RequestBody AddScheduleDTO dto) {
        String firebaseUid = UserContext.getFirebaseUid();

        if (firebaseUid == null) {
            return ResponseEntity.status(401).body("사용자 인증 실패");
        }

        scheduleService.addSchedule(dto, firebaseUid);
        return ResponseEntity.ok().build();
    }
}
