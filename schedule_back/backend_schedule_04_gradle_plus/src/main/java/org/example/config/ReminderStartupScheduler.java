package org.example.config;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.stereotype.Component;
import org.example.service.ReminderService;

@Slf4j
@Component
@RequiredArgsConstructor
public class ReminderStartupScheduler implements ApplicationListener<ContextRefreshedEvent> {

    private final ReminderService reminderService;

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        log.info("🔁 서버 시작됨 - 기존 알림 재예약 작업 시작");
        reminderService.rescheduleAllActiveReminders();
        log.info("✅ 기존 알림 재예약 완료");
    }
}
