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

import java.time.LocalDate;
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
                // reminderTime, startTime, endTime 모두 1일 후로 미루기
                schedule.setReminderTime(schedule.getReminderTime().plusDays(1));
                schedule.setStartTime(schedule.getStartTime().plusDays(1));
                schedule.setEndTime(schedule.getEndTime().plusDays(1));
                break;
            case "7일후":
                // reminderTime, startTime, endTime 모두 7일 후로 미루기
                schedule.setReminderTime(schedule.getReminderTime().plusDays(7));
                schedule.setStartTime(schedule.getStartTime().plusDays(7));
                schedule.setEndTime(schedule.getEndTime().plusDays(7));
                break;
            case "직접설정":
                if (request.getCustomReminderTime() != null) {
                    // 직접 설정된 시간으로 미루기
                    LocalDateTime customTime = request.getCustomReminderTime();
                    
                    // 기존 일정과 새 일정 사이의 일수 차이 계산
                    long daysDifference = java.time.temporal.ChronoUnit.DAYS.between(
                        schedule.getStartTime().toLocalDate(), 
                        customTime.toLocalDate()
                    );
                    
                    // reminderTime, startTime, endTime 모두 동일한 일수만큼 미루기
                    schedule.setReminderTime(customTime);
                    schedule.setStartTime(schedule.getStartTime().plusDays(daysDifference));
                    schedule.setEndTime(schedule.getEndTime().plusDays(daysDifference));
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

    @Transactional
    public void excludeOccurrence(Long scheduleId, LocalDateTime excludeDate, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new RuntimeException("일정을 찾을 수 없습니다."));

        // 권한 검증
        if (!schedule.getUser().equals(user)) {
            throw new RuntimeException("권한이 없습니다.");
        }
        
        // 반복 일정이 아니면 예외 발생
        if (schedule.getRecurrenceDays() == null || schedule.getRecurrenceDays().isEmpty()) {
            throw new RuntimeException("반복 일정이 아닙니다.");
        }
        
        // 날짜만 추출 (시간 제외)
        LocalDate excludeDateOnly = excludeDate.toLocalDate();
        
        // 제외할 날짜의 요일이 반복 요일에 포함되는지 확인
        int dayOfWeek = excludeDateOnly.getDayOfWeek().getValue(); // 1(월) ~ 7(일)
        if (!schedule.getRecurrenceDays().contains(String.valueOf(dayOfWeek))) {
            throw new RuntimeException("제외할 날짜가 반복 요일에 포함되지 않습니다.");
        }
        
        // 제외된 날짜 목록 가져오기 및 업데이트
        String excludedDates = schedule.getExcludedDates();
        String excludeDateStr = excludeDateOnly.toString();
        
        if (excludedDates == null || excludedDates.isEmpty()) {
            // 첫 번째 제외 날짜인 경우
            schedule.setExcludedDates(excludeDateStr);
        } else {
            // 이미 제외 날짜가 있는 경우
            if (!excludedDates.contains(excludeDateStr)) {
                schedule.setExcludedDates(excludedDates + "," + excludeDateStr);
            }
        }
        
        scheduleRepository.save(schedule);
    }
}
