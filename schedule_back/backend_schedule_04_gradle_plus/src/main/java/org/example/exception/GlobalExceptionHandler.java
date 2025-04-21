package org.example.exception;

import com.google.firebase.auth.FirebaseAuthException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(FirebaseAuthException.class)
    public ResponseEntity<?> handleFirebaseAuthException(FirebaseAuthException e) {
        String message = e.getMessage();
        Map<String, Object> response = new HashMap<>();
        response.put("status", "fail");

        if (message.contains("USER_NOT_FOUND")) {
            response.put("message", "사용자를 찾을 수 없습니다. 회원가입이 필요합니다.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        } else if (message.contains("INVALID_EMAIL")) {
            response.put("message", "유효하지 않은 이메일 형식입니다.");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        } else if (message.contains("INVALID_PASSWORD")) {
            response.put("message", "비밀번호가 잘못되었습니다.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        } else if (message.contains("EXPIRED_ID_TOKEN") || message.contains("REVOKED_ID_TOKEN")) {
            response.put("message", "로그인 세션이 만료되었습니다. 다시 로그인해주세요.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        } else {
            response.put("message", "로그인 실패: " + message);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<?> handleIllegalStateException(IllegalStateException e) {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "fail");
        response.put("message", e.getMessage());

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<?> handleInvalidArgument(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ex.getMessage());
    }


    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<?> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "fail");

        List<String> errors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .toList();

        response.put("message", errors);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<?> handleRuntimeException(RuntimeException ex) {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "fail");
        response.put("message", ex.getMessage());

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }
}

