package org.example.domain.schedule.util;

import org.example.domain.schedule.entity.Schedule;
import org.example.domain.schedule.dto.RecurrenceOption;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

public class RecurrenceCalculator {
    /** 단일 편집 또는 삭제: excludedDates에 occurrence 추가 */
    public static void addExcludedDate(Schedule s, LocalDateTime occurrence) {
        LocalDate d = occurrence.toLocalDate();
        Set<String> set = new LinkedHashSet<>();
        if (s.getExcludedDates() != null) {
            set.addAll(Arrays.asList(s.getExcludedDates().split(",")));
        }
        set.add(d.toString());
        s.setExcludedDates(String.join(",", set));
    }

    /** FUTURE: 원본 종료일 = occurrence -1 */
    public static void cutRecurrenceEndDate(Schedule s, LocalDateTime occurrence) {
        LocalDate d = occurrence.toLocalDate().minusDays(1);
        s.setRecurrenceEndDate(d.atStartOfDay());
    }

    /** 전체 삭제: handled in service */

    /**
     * 요일 패턴 변환 유틸리티
     * Java의 DayOfWeek는 1(월요일)~7(일요일) 값 사용.
     * 백엔드는 요일 데이터를 0부터 시작하는 배열 인덱스로 처리함.
     * 
     * @param javaWeekday DayOfWeek.getValue()의 반환값 (1~7)
     * @return 배열 인덱스 (0~6)
     */
    public static int convertWeekdayToArrayIndex(int javaWeekday) {
        // Java: 1(월요일)~7(일요일) -> 배열 인덱스: 0(월요일)~6(일요일)
        return javaWeekday - 1;
    }

    /**
     * 요일이 포함된 일정인지 확인하는 유틸리티
     * 
     * @param recurrenceDays 요일 패턴 문자열 (예: "1,0,1,0,0,0,0")
     * @param javaWeekday Java DayOfWeek 값 (1~7)
     * @return 해당 요일이 포함되어 있는지 여부
     */
    public static boolean isDayIncluded(String recurrenceDays, int javaWeekday) {
        if (recurrenceDays == null || recurrenceDays.isEmpty()) {
            return false;
        }

        String[] days = recurrenceDays.split(",");
        if (days.length == 7) {
            int arrayIndex = convertWeekdayToArrayIndex(javaWeekday);
            return "1".equals(days[arrayIndex]);
        } else {
            // 직접 요일 번호로 저장된 경우 (예: "1,3,5")
            return Arrays.asList(days).contains(String.valueOf(javaWeekday));
        }
    }

    /**
     * 요일 패턴 문자열 디버그 출력용 유틸리티
     * 
     * @param recurrenceDays 요일 패턴 문자열 (예: "0,0,0,0,1,0,0")
     * @return 디버그 정보 문자열
     */
    public static String debugDayPattern(String recurrenceDays) {
        if (recurrenceDays == null || recurrenceDays.isEmpty()) {
            return "요일 패턴 없음";
        }
        
        String[] days = recurrenceDays.split(",");
        if (days.length != 7) {
            return "잘못된 요일 패턴 형식: " + recurrenceDays;
        }
        
        StringBuilder sb = new StringBuilder("요일 패턴(") 
            .append(recurrenceDays)
            .append("):");
            
        String[] dayNames = {"월", "화", "수", "목", "금", "토", "일"};
        for (int i = 0; i < 7; i++) {
            if ("1".equals(days[i])) {
                sb.append(" ").append(dayNames[i]);
            }
        }
        
        return sb.toString();
    }
    
    /**
     * 현재 백엔드의 요일 인덱스 배열은 [월,화,수,목,금,토,일] 순서임을 명확히 함
     */
    public static final String[] BACKEND_DAY_NAMES = {"월", "화", "수", "목", "금", "토", "일"};
    
    /**
     * 요일 인덱스를 사람이 읽을 수 있는 형태로 변환 (디버그용)
     */
    public static String getWeekdayName(int javaWeekday) {
        // javaWeekday: 1(월)~7(일)
        switch(javaWeekday) {
            case 1: return "월요일";
            case 2: return "화요일";
            case 3: return "수요일";
            case 4: return "목요일";
            case 5: return "금요일";
            case 6: return "토요일";
            case 7: return "일요일";
            default: return "잘못된 요일(" + javaWeekday + ")";
        }
    }

    // TODO: 더 복잡한 로직 필요 시 구현
}