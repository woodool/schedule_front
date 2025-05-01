package org.example.controller;

import lombok.RequiredArgsConstructor;
import org.example.dto.ReminderDTO;
import org.example.service.ReminderService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
} 