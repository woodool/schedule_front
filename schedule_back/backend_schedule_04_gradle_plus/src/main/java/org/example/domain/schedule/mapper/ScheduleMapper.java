package org.example.domain.schedule.mapper;

import org.example.domain.schedule.dto.*;
import org.example.domain.schedule.entity.Schedule;
import java.time.LocalDateTime;

public class ScheduleMapper {
    public static Schedule toEntity(CreateScheduleRequestDTO dto, String firebaseUid) {
        Schedule s = Schedule.builder()
                .firebaseUid(firebaseUid)
                .title(dto.getTitle())
                .description(dto.getDescription())
                .categoryId(dto.getCategoryId())
                .startTime(dto.getStartTime())
                .endTime(dto.getEndTime())
                .recurrenceDays(dto.getRecurrenceDays())
                .recurrenceStartDate(dto.getRecurrenceStartDate())
                .recurrenceEndDate(dto.getRecurrenceEndDate())
                .excludedDates(dto.getExcludedDates())
                .reminderMinutesBefore(dto.getReminderMinutesBefore())
                .reminderTime(LocalDateTime.now().minusMinutes(
                    dto.getReminderMinutesBefore() != null ? dto.getReminderMinutesBefore() : 0))
                .priority(dto.getPriority())
                .displayOnCalendar(dto.getDisplayOnCalendar())
                .build();
        return s;
    }
    
    public static Schedule toEntity(UpdateScheduleRequestDTO dto, String firebaseUid) {
        Schedule s = Schedule.builder()
                .firebaseUid(firebaseUid)
                .title(dto.getTitle())
                .description(dto.getDescription())
                .categoryId(dto.getCategoryId())
                .startTime(dto.getStartTime())
                .endTime(dto.getEndTime())
                .recurrenceDays(dto.getRecurrenceDays())
                .recurrenceStartDate(dto.getRecurrenceStartDate())
                .recurrenceEndDate(dto.getRecurrenceEndDate())
                .excludedDates(dto.getExcludedDates())
                .reminderMinutesBefore(dto.getReminderMinutesBefore())
                .reminderTime(LocalDateTime.now().minusMinutes(
                    dto.getReminderMinutesBefore() != null ? dto.getReminderMinutesBefore() : 0))
                .priority(dto.getPriority())
                .displayOnCalendar(dto.getDisplayOnCalendar())
                .build();
        return s;
    }

    public static void updateEntity(Schedule existing, UpdateScheduleRequestDTO dto) {
        existing.setTitle(dto.getTitle());
        existing.setDescription(dto.getDescription());
        existing.setCategoryId(dto.getCategoryId());
        existing.setStartTime(dto.getStartTime());
        existing.setEndTime(dto.getEndTime());
        existing.setRecurrenceDays(dto.getRecurrenceDays());
        existing.setRecurrenceStartDate(dto.getRecurrenceStartDate());
        existing.setRecurrenceEndDate(dto.getRecurrenceEndDate());
        existing.setExcludedDates(dto.getExcludedDates());
        existing.setReminderMinutesBefore(dto.getReminderMinutesBefore());
        existing.setReminderTime(LocalDateTime.now().minusMinutes(
            dto.getReminderMinutesBefore() != null ? dto.getReminderMinutesBefore() : 0));
        existing.setPriority(dto.getPriority());
        existing.setDisplayOnCalendar(dto.getDisplayOnCalendar());
    }
}