package org.example.domain.meeting.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ParticipantNotFoundException extends RuntimeException {
    public ParticipantNotFoundException(String message) {
        super(message);
    }
    
    public ParticipantNotFoundException(Integer roomId, String userId) {
        super("Participant not found with roomId: " + roomId + " and userId: " + userId);
    }
} 