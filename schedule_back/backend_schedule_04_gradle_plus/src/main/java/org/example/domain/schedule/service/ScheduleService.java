package org.example.domain.schedule.service;

import lombok.RequiredArgsConstructor;
import org.example.domain.schedule.dto.*;
import org.example.domain.schedule.entity.Schedule;
import org.example.domain.schedule.exception.*;
import org.example.domain.schedule.mapper.ScheduleMapper;
import org.example.domain.schedule.repository.ScheduleRepository;
import org.example.domain.schedule.util.RecurrenceCalculator;
import org.example.domain.user.User;
import org.example.domain.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ScheduleService {
    private final ScheduleRepository repo;
    private final UserRepository userRepo;

    @Transactional
    public ScheduleResponseDTO create(CreateScheduleRequestDTO dto, String firebaseUid) {
        User user = userRepo.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new UnauthorizedException("사용자 없음"));
        
        // 디버그 로깅: 요일 패턴 확인
        if (dto.getRecurrenceDays() != null && !dto.getRecurrenceDays().isEmpty()) {
            System.out.println("일정 생성 - 반복 패턴: " + RecurrenceCalculator.debugDayPattern(dto.getRecurrenceDays()));
            System.out.println("  시작일: " + dto.getRecurrenceStartDate() + ", 종료일: " + dto.getRecurrenceEndDate());
        }
        
        Schedule s = ScheduleMapper.toEntity(dto, firebaseUid);
        s.setUser(user);
        Schedule saved = repo.save(s);
        
        System.out.println("일정 생성 완료 - ID: " + saved.getId() + ", 제목: " + saved.getTitle());
        
        return ScheduleResponseDTO.fromEntity(saved);
    }

    @Transactional
    public ScheduleResponseDTO update(Long id, UpdateScheduleRequestDTO dto, String firebaseUid) {
        Schedule existing = repo.findById(id)
                .orElseThrow(() -> new ScheduleNotFoundException("일정 없음: " + id));
        if (!existing.getFirebaseUid().equals(firebaseUid)) {
            throw new UnauthorizedException("권한 없음");
        }
        
        // 디버그 로깅: 요일 패턴 확인
        if (dto.getRecurrenceDays() != null && !dto.getRecurrenceDays().isEmpty()) {
            System.out.println("일정 수정 - 반복 패턴: " + RecurrenceCalculator.debugDayPattern(dto.getRecurrenceDays()));
            System.out.println("  시작일: " + dto.getRecurrenceStartDate() + ", 종료일: " + dto.getRecurrenceEndDate());
        }
        
        // 옵션이 null이면 기본값으로 ALL 사용
        RecurrenceOption opt = dto.getOption();
        if (opt == null) {
            opt = RecurrenceOption.ALL;
            System.out.println("옵션이 null로 전달됨 - 기본값 ALL로 대체");
        }
        
        LocalDateTime occ = dto.getOccurrenceDate();
        
        System.out.println("일정 수정 - 옵션: " + opt + ", 발생일: " + occ);
        switch (opt) {
            case SINGLE:
                // exclude 원본
                RecurrenceCalculator.addExcludedDate(existing, occ);
                repo.save(existing);
                // 새 일정 생성
                Schedule single = ScheduleMapper.toEntity(dto, firebaseUid);
                single.setUser(existing.getUser());
                Schedule savedSingle = repo.save(single);
                return ScheduleResponseDTO.fromEntity(savedSingle);

            case FUTURE:
                // 원본 종료일 잘라내기
                RecurrenceCalculator.cutRecurrenceEndDate(existing, occ);
                
                // 해당 당일 발생일을 원본 일정에서 제외
                // (발생일은 새 일정에서만 유효하도록)
                RecurrenceCalculator.addExcludedDate(existing, occ);
                
                repo.save(existing);
                // 이후 일정 새로 생성
                Schedule future = ScheduleMapper.toEntity(dto, firebaseUid);
                future.setRecurrenceStartDate(occ);
                future.setUser(existing.getUser());
                Schedule savedFuture = repo.save(future);
                
                System.out.println("FUTURE 옵션 수정: 원본 일정 ID=" + existing.getId() + 
                                 ", 새 일정 ID=" + savedFuture.getId() + 
                                 ", 기준일=" + occ);
                System.out.println("  원본 종료일 변경: " + existing.getRecurrenceEndDate() + 
                                 ", 제외된 날짜: " + existing.getExcludedDates());
                
                return ScheduleResponseDTO.fromEntity(savedFuture);

            case ALL:
                // 전체 수정
                ScheduleMapper.updateEntity(existing, dto);
                Schedule updated = repo.save(existing);
                return ScheduleResponseDTO.fromEntity(updated);

            default:
                throw new BadRequestException("잘못된 옵션");
        }
    }

    @Transactional(readOnly = true)
    public List<ScheduleResponseDTO> findAll(String firebaseUid) {
        User user = userRepo.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new UnauthorizedException("사용자 없음"));
        return repo.findByUser(user).stream()
                .map(ScheduleResponseDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public void delete(Long id, RecurrenceOption option, LocalDateTime occ, String firebaseUid) {
        Schedule s = repo.findById(id)
                .orElseThrow(() -> new ScheduleNotFoundException("일정 없음: " + id));
        if (!s.getFirebaseUid().equals(firebaseUid)) throw new UnauthorizedException("권한 없음");
        
        System.out.println("일정 삭제 요청 - ID: " + id + 
                          ", 옵션: " + option + 
                          ", 발생일자: " + occ + 
                          ", 제목: " + s.getTitle());
        
        if (s.getRecurrenceDays() != null && !s.getRecurrenceDays().isEmpty()) {
            System.out.println("  반복 일정 삭제 - 패턴: " + RecurrenceCalculator.debugDayPattern(s.getRecurrenceDays()));
            System.out.println("  기간: " + s.getRecurrenceStartDate() + " ~ " + s.getRecurrenceEndDate());
        }
        
        switch (option) {
            case SINGLE:
                System.out.println("  SINGLE 옵션: 단일 일정 제외 처리");
                if (occ == null) {
                    System.out.println("  경고: SINGLE 옵션에 발생일자가 지정되지 않음");
                    throw new BadRequestException("SINGLE 옵션에는 발생일자가 필요합니다");
                }
                RecurrenceCalculator.addExcludedDate(s, occ);
                System.out.println("  제외된 날짜 추가: " + occ.toLocalDate() + 
                                " (현재 제외 목록: " + s.getExcludedDates() + ")");
                repo.save(s);
                System.out.println("  일정 업데이트 완료 (제외 처리)");
                break;
                
            case FUTURE:
                System.out.println("  FUTURE 옵션: 해당일 및 이후 제외 처리");
                if (occ == null) {
                    System.out.println("  경고: FUTURE 옵션에 발생일자가 지정되지 않음");
                    throw new BadRequestException("FUTURE 옵션에는 발생일자가 필요합니다");
                }
                
                // 원본 종료일 변경
                RecurrenceCalculator.cutRecurrenceEndDate(s, occ);
                
                // 해당 당일도 제외 처리 (당일은 삭제 처리되어야 함)
                RecurrenceCalculator.addExcludedDate(s, occ);
                
                System.out.println("  종료일 변경: " + s.getRecurrenceEndDate());
                System.out.println("  제외된 날짜: " + s.getExcludedDates());
                
                repo.save(s);
                System.out.println("  일정 업데이트 완료 (종료일 변경 및 당일 제외)");
                break;
                
            case ALL:
                System.out.println("  ALL 옵션: 일정 완전 삭제");
                repo.delete(s);
                System.out.println("  일정 삭제 완료");
                break;
        }
    }

    @Transactional(readOnly = true)
    public List<ScheduleResponseDTO> search(String firebaseUid, String query) {
        User user = userRepo.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new UnauthorizedException("사용자 없음"));
        return repo.search(user, query).stream()
                .map(ScheduleResponseDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public ScheduleResponseDTO postpone(Long id, PostponeRequestDTO dto, String firebaseUid) {
    // 1) 조회 & 권한 체크
    Schedule s = repo.findById(id)
        .orElseThrow(() -> new ScheduleNotFoundException("일정 없음: " + id));
    if (!s.getFirebaseUid().equals(firebaseUid)) {
        throw new UnauthorizedException("권한이 없습니다.");
    }

    // 2) 반복 여부 판정
    boolean isRecurring = s.getRecurrenceDays() != null
                       && s.getRecurrenceDays().contains("1");

    if (isRecurring) {
        // – 원본 일정에서 해당 날짜 제외
        RecurrenceCalculator.addExcludedDate(s, s.getStartTime());
        repo.save(s);

        // – 새 일정(하나짜리) 생성: 반복 설정 제거, 날짜/알림시간 이동
        LocalDateTime newStart = shiftByMode(s.getStartTime(), dto);
        LocalDateTime newEnd   = shiftByMode(s.getEndTime(), dto);
        LocalDateTime newRem   = dto.getMode().equals("custom")
                                ? dto.getCustomReminderTime()
                                : s.getReminderTime().plusDays(dto.getMode().equals("7days") ? 7 : 1);

        // 이제는 요일이 월요일=1, ..., 일요일=7 형식으로 처리됩니다.
        Schedule oneOff = Schedule.builder()
            .firebaseUid(s.getFirebaseUid())
            .title(s.getTitle())
            .description(s.getDescription())
            .categoryId(s.getCategoryId())
            .startTime(newStart)
            .endTime(newEnd)
            .recurrenceDays("0,0,0,0,0,0,0") // 요일 패턴 초기화 (반복 없음)
            .reminderMinutesBefore(s.getReminderMinutesBefore())
            .reminderTime(newRem)
            .priority(s.getPriority())
            .displayOnCalendar(s.getDisplayOnCalendar())
            .user(s.getUser())
            .build();
        
        System.out.println("일정 미루기: 반복 일정에서 단일 일정으로 변환하여 " + 
                          dto.getMode() + " 모드로 미룸. 새 시작 시간: " + newStart);
        
        Schedule saved = repo.save(oneOff);
        return ScheduleResponseDTO.fromEntity(saved);
    } else {
        // – 일반 일정: same-entity에 시간만 이동
        s.setStartTime(shiftByMode(s.getStartTime(), dto));
        s.setEndTime(shiftByMode(s.getEndTime(), dto));
        s.setReminderTime(
            dto.getMode().equals("custom")
            ? dto.getCustomReminderTime()
            : s.getReminderTime().plusDays(dto.getMode().equals("7days") ? 7 : 1)
        );
        
        System.out.println("일정 미루기: 일반 일정을 " + dto.getMode() + 
                         " 모드로 미룸. 새 시작 시간: " + s.getStartTime());
        
        repo.save(s);
        return ScheduleResponseDTO.fromEntity(s);
        }
    }

// 날짜/모드에 따라 1일, 7일, custom 이동 처리
private LocalDateTime shiftByMode(LocalDateTime original, PostponeRequestDTO dto) {
    switch(dto.getMode()) {
        case "1day":   return original.plusDays(1);
        case "7days":  return original.plusDays(7);
        case "custom": return dto.getCustomReminderTime()
                                   .withHour(original.getHour())
                                   .withMinute(original.getMinute());
        default: throw new BadRequestException("잘못된 미루기 모드");
    }
    }

    //산진 일정 추가
    @Transactional
    public List<ScheduleResponseDTO> photoAddSchedule(PhotoListRequestDTO requestDTO, String firebaseUid) {
        User user = userRepo.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new UnauthorizedException("사용자 없음"));

        Integer reminderMinutesBefore = 10;
        List<Schedule> savedSchedules = new ArrayList<>();

        for (PhotoScheduleDTO dto : requestDTO.getPhotoListScheduleDTO()) {
            LocalDateTime reminderTime = dto.getStartTime() != null
                    ? dto.getStartTime().minusMinutes(reminderMinutesBefore)
                    : LocalDateTime.now();

            Schedule schedule = Schedule.builder()
                    .title(dto.getTitle())
                    .description(dto.getDescription())
                    .startTime(dto.getStartTime())
                    .endTime(dto.getEndTime())
                    .recurrenceDays(dto.getRecurrenceDays())
                    .recurrenceStartDate(dto.getRecurrenceStartDate())
                    .recurrenceEndDate(dto.getRecurrenceEndDate())
                    .reminderMinutesBefore(reminderMinutesBefore)
                    .reminderTime(reminderTime)
                    .firebaseUid(user.getFirebaseUid())
                    .user(user)
                    .build();

            Schedule savedSchedule = repo.save(schedule);
            savedSchedules.add(savedSchedule);
        }
        // 📌 List<ScheduleDTO>로 변환해서 반환
        return savedSchedules.stream()
                .map(ScheduleResponseDTO::fromEntity)
                .collect(Collectors.toList());
    }
}