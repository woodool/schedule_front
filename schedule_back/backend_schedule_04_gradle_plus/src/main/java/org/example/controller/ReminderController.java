package org.example.controller;

import lombok.RequiredArgsConstructor;
import org.example.dto.ReminderDTO;
import org.example.service.ReminderService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reminders")
@RequiredArgsConstructor
public class ReminderController {
    private final ReminderService reminderService;

    // ✅ 일정 ID와 몇 분 전 알림을 받을지 쿼리로 전달
    @PostMapping
    public ResponseEntity<?> createReminder(@RequestBody ReminderDTO dto) {
        try {
            reminderService.createReminderByScheduleDto(dto);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("리마인더 생성 실패: " + e.getMessage());
        }
    }

}

