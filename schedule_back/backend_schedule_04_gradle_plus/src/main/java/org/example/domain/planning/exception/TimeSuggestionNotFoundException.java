package org.example.domain.planning.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class TimeSuggestionNotFoundException extends RuntimeException {
    public TimeSuggestionNotFoundException(String message) {
        super(message);
    }
    
    public TimeSuggestionNotFoundException(Integer suggestionId) {
        super("Time suggestion not found with ID: " + suggestionId);
    }
} 