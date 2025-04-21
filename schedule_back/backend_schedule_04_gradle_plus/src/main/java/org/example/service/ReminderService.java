package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.dto.Reminder.AddReminderDTO;
import org.example.dto.Reminder.UpdateReminderDTO;
import org.example.entity.Reminder;
import org.example.repository.ReminderRepository;
import org.example.repository.UserRepository;
import org.springframework.stereotype.Service;
import com.google.cloud.Timestamp;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;


@Service
@RequiredArgsConstructor
public class ReminderService {
    private final ReminderRepository reminderRepository;
    private final UserRepository userRepository;

    public void addReminder(AddReminderDTO dto, String firebaseUid) {
        if (dto.getStartTime().isAfter(dto.getEndTime())) {
            throw new IllegalArgumentException("시작 시간이 종료 시간보다 늦을 수 없습니다.");
        }
        if (dto.getEndTime().isBefore(dto.getStartTime())) {
            throw new IllegalArgumentException("종료 시간이 시작 시간보다 빠를 수 없습니다.");
        }
        Reminder reminder = new Reminder(dto, firebaseUid);
        reminderRepository.save(reminder);

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

    public void updateReminder(Long reminderId, UpdateReminderDTO dto, String firebaseUid) {
        Reminder existingReminder = reminderRepository.findById(reminderId)
                .orElseThrow(() -> new RuntimeException("일정이 존재하지 않습니다."));

        if (!existingReminder.getFirebaseUid().equals(firebaseUid)) {
            throw new RuntimeException("수정 권한이 없습니다.");
        }
        if (dto.getStartTime().isAfter(dto.getEndTime())) {
            throw new IllegalArgumentException("시작 시간이 종료 시간보다 늦을 수 없습니다.");
        }
        if (dto.getEndTime().isBefore(dto.getStartTime())) {
            throw new IllegalArgumentException("종료 시간이 시작 시간보다 빠를 수 없습니다.");
        }

        existingReminder.setTitle(dto.getTitle());
        existingReminder.setStartTime(dto.getStartTime());
        existingReminder.setEndTime(dto.getEndTime());
        existingReminder.setRecurrenceDays(dto.getRecurrenceDays());
        existingReminder.setReminderMinutesBefore(dto.getReminderMinutesBefore());
        existingReminder.setReminderTime(dto.getReminderTime());

        reminderRepository.save(existingReminder);

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

