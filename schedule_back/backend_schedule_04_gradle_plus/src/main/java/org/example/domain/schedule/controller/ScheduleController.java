package org.example.domain.schedule.controller;

import lombok.RequiredArgsConstructor;
import org.example.domain.schedule.dto.*;
import org.example.domain.schedule.service.ScheduleService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import org.example.domain.schedule.dto.PostponeRequestDTO;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/schedules")
@RequiredArgsConstructor
public class ScheduleController {
    private final ScheduleService service;

    // 1. 생성
    @PostMapping
    public ResponseEntity<ScheduleResponseDTO> create(
            @RequestBody CreateScheduleRequestDTO dto,
            Authentication auth) {
        String uid = auth.getName();
        ScheduleResponseDTO res = service.create(dto, uid);
        return ResponseEntity.ok(res);
    }

    // 2. 수정
    @PutMapping("/{id}")
    public ResponseEntity<ScheduleResponseDTO> update(
            @PathVariable Long id,
            @RequestBody UpdateScheduleRequestDTO dto,
            Authentication auth) {
        String uid = auth.getName();
        ScheduleResponseDTO res = service.update(id, dto, uid);
        return ResponseEntity.ok(res);
    }

    // 3. 불러오기
    @GetMapping
    public ResponseEntity<List<ScheduleResponseDTO>> list(Authentication auth) {
        String uid = auth.getName();
        return ResponseEntity.ok(service.findAll(uid));
    }

    // 4. 삭제
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id,
            @RequestParam RecurrenceOption option,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime fromDate,
            Authentication auth) {
        String uid = auth.getName();
        
        // // 디버그 로깅
        // System.out.println("일정 삭제 컨트롤러 - ID: " + id + 
        //                   ", 옵션: " + option + 
        //                   ", 발생일자: " + (fromDate != null ? fromDate : "지정되지 않음") + 
        //                   ", 사용자: " + uid);
                          
        // if ((option == RecurrenceOption.SINGLE || option == RecurrenceOption.FUTURE) && fromDate == null) {
        //     System.out.println("  경고: " + option + " 옵션에는 발생일자가 필요합니다.");
        //     return ResponseEntity.badRequest().build();
        // }
        
        service.delete(id, option, fromDate, uid);
        return ResponseEntity.ok().build();
    }

    // 5. 검색
    @GetMapping("/search")
    public ResponseEntity<List<ScheduleResponseDTO>> search(
            @RequestParam String q,
            Authentication auth) {
        String uid = auth.getName();
        return ResponseEntity.ok(service.search(uid, q));
    }

    /** 6) 기간별 조회 기능 */
    @GetMapping("/range")
    public ResponseEntity<List<ScheduleResponseDTO>> getSchedulesInRange(
            @RequestParam String startDate,
            @RequestParam String endDate,
            Authentication auth) {
        String uid = auth.getName();
        // 문자열을 LocalDate로 변환
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        
        System.out.println("기간별 일정 조회 요청: " + startDate + " ~ " + endDate + " (사용자: " + uid + ")");
        
        // 모든 일정을 가져와서 필터링하는 임시 구현
        List<ScheduleResponseDTO> allSchedules = service.findAll(uid);
        
        // 시작일과 종료일 사이에 있는 일정만 필터링 (추후 서비스 레이어로 이동 필요)
        List<ScheduleResponseDTO> result = allSchedules.stream()
            .filter(s -> {
                // LocalDateTime을 문자열로 변환 후 split
                LocalDate scheduleDate = LocalDate.parse(s.getStartTime().toString().split("T")[0]);
                return !scheduleDate.isBefore(start) && !scheduleDate.isAfter(end);
            })
            .collect(Collectors.toList());
            
        System.out.println("기간별 일정 조회 결과: " + result.size() + "개");
        
        return ResponseEntity.ok(result);
    }

    /** 7) 미루기 기능 */
    @PutMapping("/{id}/postpone")
    public ResponseEntity<ScheduleResponseDTO> postpone(
            @PathVariable Long id,
            @RequestBody PostponeRequestDTO dto,
            Authentication auth) {
        String uid = auth.getName();
        ScheduleResponseDTO result = service.postpone(id, dto, uid);
        return ResponseEntity.ok(result);
    }

    /** 8) 사진 추가 기능 */
    @PostMapping("/bulk")
    public ResponseEntity<List<ScheduleResponseDTO>> photoAddSchedule(
            @RequestBody PhotoListRequestDTO requestDTO,
            Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(service.photoAddSchedule(requestDTO, firebaseUid));
    }

    /** 9) 자동 일정 배치 기능 */
    @PostMapping("/suggestions")
    public ResponseEntity<List<AutoScheduleResponseDTO>> getAutoScheduleSuggestions(
            @RequestBody AutoScheduleRequestDTO request,
            Authentication authentication) {
        String firebaseUid = authentication.getName();
        return ResponseEntity.ok(service.generateSuggestions(request, firebaseUid));
    }

    @PostMapping("/confirm")
    public ResponseEntity<String> confirmSchedule(
            @RequestBody AutoScheduleResponseDTO selected,
            Authentication authentication) {
        String firebaseUid = authentication.getName();
        service.saveConfirmedSchedule(selected, firebaseUid);
        return ResponseEntity.ok("일정 저장 완료");
    }
}
