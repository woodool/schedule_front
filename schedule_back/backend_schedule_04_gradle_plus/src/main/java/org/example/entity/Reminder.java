package org.example.entity;

import jakarta.persistence.*;

import lombok.*;
import org.example.dto.Reminder.AddReminderDTO;
import java.time.LocalDateTime;
import java.util.*;

@Entity
@Table(name = "reminder")
@Getter
@Setter
@NoArgsConstructor

public class Reminder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long reminderId;

    private String title;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    private List<Integer> recurrenceDays;

    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;
    private String firebaseUid;

    public Reminder(AddReminderDTO dto, String firebaseUid){
        this.title = dto.getTitle();
        this.startTime = dto.getStartTime();
        this.endTime = dto.getEndTime();
        this.recurrenceDays = dto.getRecurrenceDays();
        this.reminderMinutesBefore = dto.getReminderMinutesBefore();
        this.reminderTime = dto.getReminderTime();
        this.firebaseUid = firebaseUid;
    }
}
