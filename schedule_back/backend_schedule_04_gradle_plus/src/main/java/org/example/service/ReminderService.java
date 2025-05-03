package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.dto.ReminderDTO;
import org.example.entity.Reminder;
import org.example.entity.User;
import org.example.repository.ReminderRepository;
import org.example.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReminderService {
    private final ReminderRepository reminderRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<ReminderDTO> getReminders(String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        return reminderRepository.findByUser(user).stream()
                .map(ReminderDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public ReminderDTO createReminder(ReminderDTO reminderDTO, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        // 기본값 처리
        String recurrenceDays = reminderDTO.getRecurrenceDays() != null ? reminderDTO.getRecurrenceDays() : "0,0,0,0,0,0,0";
        Integer reminderMinutesBefore = reminderDTO.getReminderMinutesBefore() != null ? reminderDTO.getReminderMinutesBefore() : 0;
        
        // reminderTime은 현재시간 사용
        LocalDateTime calculatedReminderTime = LocalDateTime.now();

        Reminder reminder = Reminder.builder()
                .reminderTitle(reminderDTO.getReminderTitle())
                .recurrenceDays(recurrenceDays)
                .reminderMinutesBefore(reminderMinutesBefore)
                .reminderTime(calculatedReminderTime)
                .isActive(true)
                .checkedDate(null) // 초기에는 체크되지 않음
                .recurrenceStartDate(reminderDTO.getRecurrenceStartDate())
                .recurrenceEndDate(reminderDTO.getRecurrenceEndDate())
                .user(user)
                .build();

        return ReminderDTO.fromEntity(reminderRepository.save(reminder));
    }
    
    @Transactional
    public ReminderDTO updateReminder(Long reminderId, ReminderDTO reminderDTO, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
            .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Reminder reminder = reminderRepository.findById(reminderId)
            .orElseThrow(() -> new RuntimeException("수정할 리마인더를 찾을 수 없습니다."));

        // 🔥 user.getFirebaseUid()로 비교
        if (!reminder.getUser().getFirebaseUid().equals(firebaseUid)) {
            throw new RuntimeException("수정 권한이 없습니다.");
        }

        // 수정 내용 적용
        reminder.setReminderTitle(reminderDTO.getReminderTitle());
        reminder.setRecurrenceDays(reminderDTO.getRecurrenceDays());
        reminder.setReminderMinutesBefore(reminderDTO.getReminderMinutesBefore());
        reminder.setRecurrenceStartDate(reminderDTO.getRecurrenceStartDate());
        reminder.setRecurrenceEndDate(reminderDTO.getRecurrenceEndDate());
        
        // isActive 및 checkedDate 필드 업데이트
        if (reminderDTO.getIsActive() != null) {
            reminder.setIsActive(reminderDTO.getIsActive());
        }
        
        // checkedDate 필드 업데이트
        reminder.setCheckedDate(reminderDTO.getCheckedDate());

        // reminderTime 업데이트 (현재 시간 사용)
        reminder.setReminderTime(LocalDateTime.now());

        return ReminderDTO.fromEntity(reminder);
    }

    /**
     * 리마인더 체크박스 토글 메서드
     * 체크해도 isActive를 유지하고 checkedDate만 업데이트
     */
    @Transactional
    public ReminderDTO toggleReminderCheck(Long reminderId, Boolean isChecked, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Reminder reminder = reminderRepository.findById(reminderId)
                .orElseThrow(() -> new RuntimeException("리마인더를 찾을 수 없습니다."));

        // 권한 검증
        if (!reminder.getUser().getFirebaseUid().equals(firebaseUid)) {
            throw new RuntimeException("권한이 없습니다.");
        }

        if (isChecked) {
            // 체크됨: checkedDate만 기록하고 isActive는 유지
            reminder.setCheckedDate(LocalDateTime.now());
        } else {
            // 체크 해제: checkedDate만 제거하고 isActive는 유지
            reminder.setCheckedDate(null);
        }

        return ReminderDTO.fromEntity(reminderRepository.save(reminder));
    }

    @Transactional
    public void deleteReminder(Long id, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Reminder reminder = reminderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("리마인더를 찾을 수 없습니다."));

        if (!reminder.getUser().equals(user)) {
            throw new RuntimeException("권한이 없습니다.");
        }

        reminderRepository.delete(reminder);
    }
    
    @Transactional
    public void excludeOccurrence(Long reminderId, LocalDateTime excludeDate, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        Reminder reminder = reminderRepository.findById(reminderId)
                .orElseThrow(() -> new RuntimeException("리마인더를 찾을 수 없습니다."));

        // 권한 검증
        if (!reminder.getUser().getFirebaseUid().equals(firebaseUid)) {
            throw new RuntimeException("권한이 없습니다.");
        }
        
        // 반복 일정이 아니면 예외 발생
        if (reminder.getRecurrenceDays() == null || reminder.getRecurrenceDays().isEmpty() 
                || "0,0,0,0,0,0,0".equals(reminder.getRecurrenceDays())) {
            throw new RuntimeException("반복 리마인더가 아닙니다.");
        }
        
        // 날짜만 추출 (시간 제외)
        LocalDate excludeDateOnly = excludeDate.toLocalDate();
        
        // 제외할 날짜의 요일이 반복 요일에 포함되는지 확인
        int dayOfWeek = excludeDateOnly.getDayOfWeek().getValue(); // 1(월) ~ 7(일)
        
        boolean isValidDay = false;
        String recurrenceDays = reminder.getRecurrenceDays();
        
        // "1,0,1,0,1,0,0" 형식
        if (recurrenceDays.split(",").length == 7) {
            String[] days = recurrenceDays.split(",");
            if (days[dayOfWeek - 1].equals("1")) {
                isValidDay = true;
            }
        } 
        // "1,3,5" 형식
        else if (recurrenceDays.contains(",")) {
            String[] dayNumbers = recurrenceDays.split(",");
            for (String day : dayNumbers) {
                if (day.equals(String.valueOf(dayOfWeek))) {
                    isValidDay = true;
                    break;
                }
            }
        }
        
        if (!isValidDay) {
            throw new RuntimeException("제외할 날짜가 반복 요일에 포함되지 않습니다.");
        }
        
        // 제외된 날짜 목록 가져오기 및 업데이트
        String excludedDates = reminder.getExcludedDates();
        String excludeDateStr = excludeDateOnly.toString();
        
        if (excludedDates == null || excludedDates.isEmpty()) {
            // 첫 번째 제외 날짜인 경우
            reminder.setExcludedDates(excludeDateStr);
        } else {
            // 이미 제외 날짜가 있는 경우
            if (!excludedDates.contains(excludeDateStr)) {
                reminder.setExcludedDates(excludedDates + "," + excludeDateStr);
            }
        }
        
        reminderRepository.save(reminder);
    }
}
