package org.example.domain.planning.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class PlanningNotFoundException extends RuntimeException {
    public PlanningNotFoundException(String message) {
        super(message);
    }
    
    public PlanningNotFoundException(Integer roomId) {
        super("Planning room not found with ID: " + roomId);
    }
} 