package org.example.controller.Reminder;

import lombok.RequiredArgsConstructor;
import org.example.context.UserContext;
import org.example.dto.Reminder.UpdateReminderDTO;
import org.example.service.ReminderService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/reminder")
public class UpdateReminderController {
    private final ReminderService reminderService;
    @PutMapping("/{id}")
    public ResponseEntity<?> updateReminder(@PathVariable("id") Long reminderId, @RequestBody UpdateReminderDTO dto) {
        String firebaseUid = UserContext.getFirebaseUid();

        if (firebaseUid == null) {
            return ResponseEntity.status(401).body("사용자 인증 실패");
        }
        reminderService.updateReminder(reminderId, dto, firebaseUid);
        return ResponseEntity.ok().build();
    }
}
