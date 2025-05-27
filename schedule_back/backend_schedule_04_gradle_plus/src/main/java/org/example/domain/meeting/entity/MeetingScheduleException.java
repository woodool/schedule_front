package org.example.domain.meeting.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "meeting_schedule_exceptions")
public class MeetingScheduleException {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "exception_id")
    private Integer exceptionId;

    @Column(name = "schedule_id", nullable = false)
    private Integer scheduleId;

    @Column(name = "exception_date", nullable = false)
    private LocalDate exceptionDate;

    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted;

    @Column(name = "override_start_time")
    private LocalTime overrideStartTime;

    @Column(name = "override_end_time")
    private LocalTime overrideEndTime;

    @Column(name = "override_memo")
    private String overrideMemo;

    @Column(name = "apply_to_future", nullable = false)
    private Boolean applyToFuture;
} 