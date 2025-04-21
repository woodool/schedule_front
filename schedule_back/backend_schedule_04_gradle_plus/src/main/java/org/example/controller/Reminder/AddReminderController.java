package org.example.controller.Reminder;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.dto.Reminder.AddReminderDTO;
import org.example.context.UserContext;
import org.example.service.ReminderService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/reminder")
public class AddReminderController {
    private final ReminderService reminderService;

    @PostMapping
    public ResponseEntity<?> addReminder(@Valid @RequestBody AddReminderDTO dto) {
        String firebaseUid = UserContext.getFirebaseUid();

        if (firebaseUid == null) {
            return ResponseEntity.status(401).body("사용자 인증 실패");
        }

        reminderService.addReminder(dto, firebaseUid);
        return ResponseEntity.ok().build();
    }
}
