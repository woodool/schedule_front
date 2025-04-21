package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.dto.Schedule.AddScheduleDTO;
import org.example.dto.Schedule.UpdateScheduleDTO;
import org.example.entity.Schedule;
import org.example.repository.ScheduleRepository;
import org.example.repository.UserRepository;
import org.springframework.stereotype.Service;
import com.google.cloud.Timestamp;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;


@Service
@RequiredArgsConstructor
public class ScheduleService {
    private final ScheduleRepository scheduleRepository;
    private final UserRepository userRepository;

    public void addSchedule(AddScheduleDTO dto, String firebaseUid) {
        if (dto.getStartTime().isAfter(dto.getEndTime())) {
            throw new IllegalArgumentException("시작 시간이 종료 시간보다 늦을 수 없습니다.");
        }
        if (dto.getEndTime().isBefore(dto.getStartTime())) {
            throw new IllegalArgumentException("종료 시간이 시작 시간보다 빠를 수 없습니다.");
        }

        Schedule schedule = new Schedule(dto, firebaseUid);
        scheduleRepository.save(schedule);

        // 알림 전송
        userRepository.findByFirebaseUid(firebaseUid).ifPresent(user -> {
            String targetToken = user.getFcmToken();
            String title = dto.getTitle();
            LocalDateTime reminderTime = dto.getReminderTime();
            Date date = Date.from(reminderTime.atZone(ZoneId.systemDefault()).toInstant());
            Timestamp firebaseTimestamp = Timestamp.of(date);
            FCMService notifier = FCMService.getInstance();
            notifier.scheduleNotification(targetToken, title, "", firebaseTimestamp);
        });
    }

    public void updateSchedule(Long scheduleId, UpdateScheduleDTO dto, String firebaseUid) {
        Schedule existingSchedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new RuntimeException("일정이 존재하지 않습니다."));

        if (!existingSchedule.getFirebaseUid().equals(firebaseUid)) {
            throw new RuntimeException("수정 권한이 없습니다.");
        }

        if (dto.getStartTime().isAfter(dto.getEndTime())) {
            throw new IllegalArgumentException("시작 시간이 종료 시간보다 늦을 수 없습니다.");
        }
        if (dto.getEndTime().isBefore(dto.getStartTime())) {
            throw new IllegalArgumentException("종료 시간이 시작 시간보다 빠를 수 없습니다.");
        }

        existingSchedule.setTitle(dto.getTitle());
        existingSchedule.setStartTime(dto.getStartTime());
        existingSchedule.setEndTime(dto.getEndTime());
        existingSchedule.setRecurrenceDays(dto.getRecurrenceDays());
        existingSchedule.setReminderMinutesBefore(dto.getReminderMinutesBefore());
        existingSchedule.setReminderTime(dto.getReminderTime());
        existingSchedule.setCategoryId(dto.getCategoryId());
        existingSchedule.setPriority(dto.getPriority());
        existingSchedule.setDescription(dto.getDescription());
        existingSchedule.setDisplayOnCalendar(dto.isDisplayOnCalendar());

        scheduleRepository.save(existingSchedule);

        // 알림 전송
        userRepository.findByFirebaseUid(firebaseUid).ifPresent(user -> {
            String targetToken = user.getFcmToken();
            String title = dto.getTitle();
            LocalDateTime reminderTime = dto.getReminderTime();
            Date date = Date.from(reminderTime.atZone(ZoneId.systemDefault()).toInstant());
            Timestamp firebaseTimestamp = Timestamp.of(date);
            FCMService notifier = FCMService.getInstance();
            notifier.scheduleNotification(targetToken, title, "", firebaseTimestamp);
        });
    }

}
