package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.dto.ReminderDTO;
import org.example.entity.Reminder;
import org.example.entity.User;
import org.example.repository.ReminderRepository;
import org.example.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
        LocalDateTime calculatedReminderTime = reminderDTO.getStartTime() != null ?
                reminderDTO.getStartTime().minusMinutes(reminderMinutesBefore) :
                LocalDateTime.now();

        Reminder reminder = Reminder.builder()
                .title(reminderDTO.getTitle())
                .startTime(reminderDTO.getStartTime())
                .endTime(reminderDTO.getEndTime())
                .recurrenceDays(recurrenceDays)
                .reminderMinutesBefore(reminderMinutesBefore)
                .reminderTime(calculatedReminderTime)
                .isActive(true)
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
        reminder.setTitle(reminderDTO.getTitle());
        reminder.setStartTime(reminderDTO.getStartTime());
        reminder.setEndTime(reminderDTO.getEndTime());
        reminder.setRecurrenceDays(reminderDTO.getRecurrenceDays());
        reminder.setReminderMinutesBefore(reminderDTO.getReminderMinutesBefore());

        Integer reminderMinutesBefore = reminderDTO.getReminderMinutesBefore() != null ? reminderDTO.getReminderMinutesBefore() : 0;
        LocalDateTime reminderTime = reminderDTO.getStartTime() != null
            ? reminderDTO.getStartTime().minusMinutes(reminderMinutesBefore)
            : LocalDateTime.now();
        reminder.setReminderTime(reminderTime);

        return ReminderDTO.fromEntity(reminder);
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
}
