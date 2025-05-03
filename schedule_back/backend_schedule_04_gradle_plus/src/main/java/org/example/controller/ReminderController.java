package org.example.controller;

import lombok.RequiredArgsConstructor;
import org.example.dto.ReminderDTO;
import org.example.service.ReminderService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reminders")
@RequiredArgsConstructor
public class ReminderController {
    private final ReminderService reminderService;

    @GetMapping
    public ResponseEntity<List<ReminderDTO>> getReminders(Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(reminderService.getReminders(firebaseUid));
    }

    @PostMapping
    public ResponseEntity<ReminderDTO> createReminder(@RequestBody ReminderDTO reminderDTO, Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(reminderService.createReminder(reminderDTO, firebaseUid));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteReminder(@PathVariable Long id, Authentication authentication) {
        try {
            String firebaseUid = authentication.getName();
            reminderService.deleteReminder(id, firebaseUid);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<ReminderDTO> updateReminder(@PathVariable Long id, @RequestBody ReminderDTO reminderDTO, Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(reminderService.updateReminder(id, reminderDTO, firebaseUid));
    }
    
    /**
     * 리마인더 체크박스 토글 엔드포인트
     */
    @PutMapping("/{id}/toggle-check")
    public ResponseEntity<ReminderDTO> toggleCheck(
            @PathVariable("id") Long reminderId,
            @RequestBody Map<String, Boolean> payload,
            Authentication authentication) {
        try {
            String firebaseUid = authentication.getName();
            Boolean isChecked = payload.get("isChecked");
            
            if (isChecked == null) {
                return ResponseEntity.badRequest().body(null);
            }
            
            ReminderDTO updatedReminder = reminderService.toggleReminderCheck(reminderId, isChecked, firebaseUid);
            return ResponseEntity.ok(updatedReminder);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(null);
        }
    }
    
    @PostMapping("/{id}/exclude-occurrence")
    public ResponseEntity<?> excludeOccurrence(
            @PathVariable("id") Long reminderId,
            @RequestBody Map<String, String> payload,
            Authentication authentication) {
        try {
            String firebaseUid = authentication.getName();
            String excludeDateStr = payload.get("excludeDate");
            
            if (excludeDateStr == null) {
                return ResponseEntity.badRequest().body("excludeDate is required");
            }
            
            LocalDateTime excludeDate = LocalDateTime.parse(excludeDateStr);
            reminderService.excludeOccurrence(reminderId, excludeDate, firebaseUid);
            
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
} 