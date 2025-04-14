package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.dto.ScheduleDTO;
import org.example.entity.Schedule;
import org.example.repository.ScheduleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.example.repository.ReminderRepository;
import org.example.repository.CategoryRepository;
import org.example.entity.Category;

import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final ReminderService reminderService;
    private final ReminderRepository reminderRepository;
    private final CategoryRepository categoryRepository;

    // 일정 전체 조회
    public List<Schedule> fetchUserSchedule() {
        try {
            return scheduleRepository.findAll(); // 전체 일정 가져오기
        } catch (Exception e) {
            System.err.println("PSQL 일정 불러오기 실패: " + e.getMessage());
            return List.of();
        }
    }

    // 일정 추가
    @Transactional
    public Schedule addSchedule(String firebaseUid, ScheduleDTO dto) {
        if (firebaseUid == null || firebaseUid.isBlank()) {
            throw new IllegalArgumentException("Firebase UID는 필수입니다.");
        }

        if (dto == null) {
            throw new IllegalArgumentException("DTO는 null일 수 없습니다.");
        }

        if (dto.getCategoryId() == null) {
            throw new IllegalArgumentException("카테고리 ID는 null일 수 없습니다.");

        }

        if (dto.getStartTime() == null || dto.getEndTime() == null) {
            throw new IllegalArgumentException("시작 시간과 종료 시간은 필수입니다.");
        }

        Category category = categoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new IllegalArgumentException("카테고리를 찾을 수 없습니다."));

        Schedule schedule = Schedule.fromDTO(firebaseUid, dto, category);

        // 스케줄 저장
        Schedule saved = scheduleRepository.save(schedule);

        // 리마인더 추가
        // 스케줄 저장 후 리마인더 처리
        if (dto.getReminderMinutesBefore() != null) {
            reminderService.createReminder(saved, dto.getReminderMinutesBefore());
        }
        return saved;
    }

    public List<Schedule> getToDoList(String firebaseUid) {
        return scheduleRepository.findPriorityOrHasAdditionalReminders(firebaseUid);
    }

    @Transactional
    public Schedule removeReminder(Long scheduleId, int minutesBefore) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("일정을 찾을 수 없습니다."));

        // 일정에서 특정 리마인더 삭제
        reminderService.removeReminder(schedule, minutesBefore);
        return scheduleRepository.save(schedule);
    }



    // 일정 수정
    @Transactional
    public Schedule updateSchedule(Long scheduleId, ScheduleDTO dto) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("일정을 찾을 수 없습니다."));

        if (dto.getTitle() != null) schedule.setTitle(dto.getTitle());
        if (dto.getDescription() != null) schedule.setDescription(dto.getDescription());
        if (dto.getStartTime() != null) schedule.setStartTime(dto.getStartTime());
        if (dto.getEndTime() != null) schedule.setEndTime(dto.getEndTime());
        schedule.setPriority(dto.getPriority());
        schedule.setRecurring(dto.isRecurring());
        schedule.setRecurrenceDays(dto.getRecurrenceDays());
        schedule.setReminderMinutesBefore(dto.getReminderMinutesBefore());
        schedule.setDisplayOnCalendar(dto.isDisplayOnCalendar());

        if (dto.getCategoryId() != null) {
            Category category = categoryRepository.findById(dto.getCategoryId())
                    .orElseThrow(() -> new IllegalArgumentException("카테고리를 찾을 수 없습니다."));
            schedule.setCategory(category);
        }

        return scheduleRepository.save(schedule);
    }


    // 일정 삭제
    @Transactional
    public void deleteSchedule(Long scheduleId) {
        if (!scheduleRepository.existsById(scheduleId)) {
            throw new IllegalArgumentException("삭제할 일정이 존재하지 않습니다.");
        }
        scheduleRepository.deleteById(scheduleId);
    }


    // 일정 나열 (필터)
    public List<Schedule> getSchedules(String firebaseUid, LocalDateTime start, LocalDateTime end) {
        if (start.isAfter(end)) {
            throw new IllegalArgumentException("시작 시간은 종료 시간보다 이전이어야 합니다.");
        }
        return scheduleRepository.findByFirebaseUidAndStartTimeBetween(firebaseUid, start, end);
    }

    // 일정 미루기
    @Transactional
    public Schedule postponeSchedule(Long scheduleId, int days) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("일정을 찾을 수 없습니다."));
        schedule.postponeSchedule(days);
        return scheduleRepository.save(schedule);
    }
}
