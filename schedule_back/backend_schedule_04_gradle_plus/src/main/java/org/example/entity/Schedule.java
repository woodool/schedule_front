package org.example.entity;

import jakarta.persistence.*;

import lombok.*;
import org.example.dto.Schedule.AddScheduleDTO;

import java.time.LocalDateTime;
import java.util.*;

@Entity
@Table(name = "schedules")
@Getter
@Setter
@NoArgsConstructor
public class Schedule {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long scheduleId;

    private String title;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    @ElementCollection
    @CollectionTable(name = "schedule_recurrence_days", joinColumns = @JoinColumn(name = "schedule_id"))
    private List<Integer> recurrenceDays;

    private Integer reminderMinutesBefore;
    private LocalDateTime reminderTime;

    private Long categoryId;

    private int priority;

    @Column(name = "description")
    private String description;

    private boolean displayOnCalendar;

    private String firebaseUid;

    public Schedule(AddScheduleDTO dto, String firebaseUid){
        this.title = dto.getTitle();
        this.startTime = dto.getStartTime();
        this.endTime = dto.getEndTime();
        this.recurrenceDays = dto.getRecurrenceDays();
        this.reminderMinutesBefore = dto.getReminderMinutesBefore();
        this.reminderTime = dto.getReminderTime();
        this.categoryId = dto.getCategoryId();
        this.priority = dto.getPriority();
        this.description = dto.getDescription();
        this.displayOnCalendar = dto.isDisplayOnCalendar();
        this.firebaseUid = firebaseUid;
    }


}
