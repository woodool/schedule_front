package org.example.domain.planning.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class FinalScheduleNotFoundException extends RuntimeException {
    public FinalScheduleNotFoundException(String message) {
        super(message);
    }
    
    public FinalScheduleNotFoundException(Integer roomId) {
        super("Final schedule not found for room with ID: " + roomId);
    }
} 