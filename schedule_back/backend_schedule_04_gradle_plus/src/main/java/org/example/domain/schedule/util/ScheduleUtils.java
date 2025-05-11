package org.example.domain.schedule.util;

import org.example.domain.schedule.entity.Schedule;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

public class ScheduleUtils {
    public static List<LocalTime[]> findEmptySlots(List<Schedule> schedules, LocalDate date) {
        List<Schedule> sameDaySchedules = schedules.stream()
                .filter(s -> s.getStartTime().toLocalDate().equals(date))
                .sorted(Comparator.comparing(Schedule::getStartTime))
                .collect(Collectors.toList());

        List<LocalTime[]> result = new ArrayList<>();
        LocalTime current = LocalTime.of(8, 0); // 하루 시작

        for (Schedule s : sameDaySchedules) {
            LocalTime start = s.getStartTime().toLocalTime();
            if (current.isBefore(start)) {
                result.add(new LocalTime[]{current, start});
            }
            current = s.getEndTime().toLocalTime().isAfter(current) ? s.getEndTime().toLocalTime() : current;
        }

        if (current.isBefore(LocalTime.of(23, 0))) {
            result.add(new LocalTime[]{current, LocalTime.of(23, 0)});
        }

        return result;
    }
}

