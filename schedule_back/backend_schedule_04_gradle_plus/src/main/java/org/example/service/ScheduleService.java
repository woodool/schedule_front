package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.dto.PostponeRequestDTO;
import org.example.dto.ScheduleDTO;
import org.example.entity.Reminder;
import org.example.entity.Schedule;
import org.example.entity.User;
import org.example.repository.ScheduleRepository;
import org.example.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ScheduleService {
    private final ScheduleRepository scheduleRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<ScheduleDTO> getSchedules(String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        return scheduleRepository.findByUser(user).stream()
                .map(ScheduleDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public ScheduleDTO createSchedule(ScheduleDTO scheduleDTO, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Integer reminderMinutesBefore = scheduleDTO.getReminderMinutesBefore() != null
                ? scheduleDTO.getReminderMinutesBefore()
                : 0;
        LocalDateTime reminderTime = scheduleDTO.getStartTime() != null
                ? scheduleDTO.getStartTime().minusMinutes(reminderMinutesBefore)
                : LocalDateTime.now();

        // 인증받은 사용자의 firebaseUid를 엔티티에 세팅하여, 수정 시 권한체크에 사용한다.
        Schedule schedule = Schedule.builder()
                .title(scheduleDTO.getTitle())
                .description(scheduleDTO.getDescription())
                .startTime(scheduleDTO.getStartTime())
                .endTime(scheduleDTO.getEndTime())
                .categoryId(scheduleDTO.getCategoryId())
                .recurrenceDays(scheduleDTO.getRecurrenceDays())
                .priority(scheduleDTO.getPriority())
                .displayOnCalendar(scheduleDTO.getDisplayOnCalendar() != null ? scheduleDTO.getDisplayOnCalendar() : true)
                .reminderMinutesBefore(reminderMinutesBefore)
                .reminderTime(reminderTime)
                .firebaseUid(user.getFirebaseUid()) // 추가: firebaseUid 세팅
                .user(user)
                .build();

        return ScheduleDTO.fromEntity(scheduleRepository.save(schedule));
    }

    @Transactional
    public ScheduleDTO updateSchedule(Long scheduleId, ScheduleDTO scheduleDTO, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new RuntimeException("수정할 일정을 찾을 수 없습니다."));

        // firebaseUid를 비교하여, 수정 권한이 있는지 검증한다.
        if (schedule.getFirebaseUid() == null || !schedule.getFirebaseUid().equals(firebaseUid)) {
            throw new RuntimeException("수정 권한이 없습니다.");
        }

        // 각 필드 수정 (엔티티에 별도의 update() 메소드를 만들 필요 없이 setter로 직접 수정)
        schedule.setTitle(scheduleDTO.getTitle());
        schedule.setDescription(scheduleDTO.getDescription());
        schedule.setStartTime(scheduleDTO.getStartTime());
        schedule.setEndTime(scheduleDTO.getEndTime());
        schedule.setCategoryId(scheduleDTO.getCategoryId());
        schedule.setRecurrenceDays(scheduleDTO.getRecurrenceDays());
        schedule.setPriority(scheduleDTO.getPriority());
        schedule.setDisplayOnCalendar(scheduleDTO.getDisplayOnCalendar());
        schedule.setReminderMinutesBefore(scheduleDTO.getReminderMinutesBefore());

        Integer reminderMinutesBefore = scheduleDTO.getReminderMinutesBefore() != null ? scheduleDTO.getReminderMinutesBefore() : 0;
        LocalDateTime reminderTime = scheduleDTO.getStartTime() != null
                ? scheduleDTO.getStartTime().minusMinutes(reminderMinutesBefore)
                : LocalDateTime.now();
        schedule.setReminderTime(reminderTime);

        return ScheduleDTO.fromEntity(schedule);
    }

    @Transactional
    public ScheduleDTO postponeScheduleReminder(Long scheduleId, String firebaseUid , PostponeRequestDTO request) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new RuntimeException("일정을 찾을 수 없습니다."));

        switch (request.getMode()) {
            case "1일후":
                schedule.setReminderTime(schedule.getReminderTime().plusDays(1));
                break;
            case "7일후":
                schedule.setReminderTime(schedule.getReminderTime().plusDays(7));
                break;
            case "직접설정":
                if (request.getCustomReminderTime() != null) {
                    schedule.setReminderTime(request.getCustomReminderTime());
                } else {
                    throw new RuntimeException("customReminderTime이 필요합니다.");
                }
                break;
            default:
                throw new RuntimeException("잘못된 미루기 모드입니다.");
        }
        scheduleRepository.save(schedule);
        return ScheduleDTO.fromEntity(schedule);
    }

    @Transactional
    public void deleteSchedule(Long scheduleId, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new RuntimeException("일정을 찾을 수 없습니다."));

        if (!schedule.getUser().equals(user)) {
            throw new RuntimeException("권한이 없습니다.");
        }

        scheduleRepository.delete(schedule);
    }
}
