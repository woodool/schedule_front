package org.example.domain.meeting.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MeetingParticipantId implements Serializable {
    private Integer roomId;
    private String userId;
} 