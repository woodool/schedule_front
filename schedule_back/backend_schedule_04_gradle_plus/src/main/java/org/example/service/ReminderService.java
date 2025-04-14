package org.example.service;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;

import org.example.entity.Reminder;
import org.example.entity.Schedule;
import org.example.repository.ScheduleRepository;
import org.springframework.stereotype.Service;
import org.example.repository.ReminderRepository;

import java.util.concurrent.TimeUnit;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import org.springframework.context.annotation.DependsOn;
import org.example.dto.ReminderDTO;

@Service
@RequiredArgsConstructor
@DependsOn("FCMService")
public class ReminderService {
    private final ReminderRepository reminderRepository;
    private final FCMService fcmService;  // FCM 서비스 주입
    private final ScheduleRepository scheduleRepository;
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

    public void saveReminder(Reminder reminder) {
        reminderRepository.save(reminder);
    }

    @Transactional
    public void createReminderByScheduleDto(ReminderDTO dto) {
        // 일정 조회 또는 필요한 경우 새로 생성
        Schedule schedule = scheduleRepository.findById(dto.getScheduleId())
                .orElseThrow(() -> new IllegalArgumentException("일정을 찾을 수 없습니다."));

        schedule.setTitle(dto.getTitle());
        schedule.setStartTime(LocalDateTime.parse(dto.getStartTime()));
        schedule.setEndTime(LocalDateTime.parse(dto.getEndTime()));
        schedule.setRecurring(dto.isRecurring());

        scheduleRepository.save(schedule);  // 업데이트 반영

        createReminder(schedule, dto.getReminderMinutesBefore());
    }

    // 새로운 리마인더 예약
    public void createReminder(Schedule schedule, Integer reminderMinutesBefore) {
        if (schedule.getStartTime() != null && reminderMinutesBefore != null && reminderMinutesBefore >= 0) {
            LocalDateTime reminderTime = schedule.getStartTime().minusMinutes(reminderMinutesBefore);
            Reminder reminder = new Reminder(schedule, reminderMinutesBefore, reminderTime);
            saveReminder(reminder);
            scheduleExistingReminder(reminder);
        }
    }

    // 리마인더 삭제 메서드
    public void removeReminder(Schedule schedule, int minutesBefore) {
        if (schedule == null || schedule.getStartTime() == null) {
            System.err.println("🚨 삭제할 리마인더가 없는 일정입니다.");
            return;
        }

        // 리마인더 시간 계산
        LocalDateTime reminderTime = schedule.getStartTime().minusMinutes(minutesBefore);

        // 해당 시간에 맞는 리마인더 찾기
        Reminder reminder = reminderRepository.findByScheduleAndReminderTime(schedule, reminderTime);

        if (reminder != null) {
            reminderRepository.delete(reminder);  // 리마인더 삭제
            System.out.println("✅ 리마인더 삭제됨: " + reminderTime);
        } else {
            System.err.println("🚨 해당 시간의 리마인더를 찾을 수 없습니다.");
        }
    }

    // 기존 알림을 복원하는 메서드 (앱 실행 시 호출)
    @Transactional
    public void rescheduleAllActiveReminders() {
        List<Reminder> reminders = reminderRepository.findAll();

        for (Reminder reminder : reminders) {
            if (reminder.getReminderTime() != null && reminder.getReminderTime().isAfter(LocalDateTime.now())) {
                scheduleExistingReminder(reminder);
            } else {
                reminderRepository.delete(reminder); // 과거 알림은 삭제
            }
        }
    }

    // 리마인더 예약 (알림 시간 기준)
    public void scheduleExistingReminder(Reminder reminder) {
        if (reminder == null || reminder.getSchedule() == null || reminder.getReminderTime() == null) {
            System.err.println("🚨 잘못된 리마인더: reminder, schedule, 또는 reminderTime이 null입니다.");
            return;
        }

        LocalDateTime reminderTime = reminder.getReminderTime();
        long delay = Duration.between(LocalDateTime.now(), reminderTime).toMillis();

        if (delay > 0) {
            scheduler.schedule(() -> sendNotification(reminder.getSchedule()), delay, TimeUnit.MILLISECONDS);
            System.out.println("✅ 알림 예약됨: " + reminderTime);
        } else {
            System.out.println("⏳ 알림 시간이 이미 지나 삭제됨: " + reminderTime);
            reminderRepository.delete(reminder);
        }
    }

    private void sendNotification(Schedule schedule) {
        String firebaseUid = schedule.getFirebaseUid();
        String title = "📅 일정 알림";
        String message = "🔔 " + schedule.getTitle() + " 알림 시간입니다!";

        fcmService.sendPushNotification(firebaseUid, title, message);
    }
}
