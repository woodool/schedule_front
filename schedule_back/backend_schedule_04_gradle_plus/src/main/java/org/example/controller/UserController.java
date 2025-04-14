package org.example.controller;

import org.example.dto.UserRequestDTO;
import org.example.entity.User;
import org.example.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    // 로그인
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody UserRequestDTO request) {
        if (request.getFirebaseUid() == null || request.getFirebaseUid().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("firebaseUid가 필요합니다."); // String 반환
        }

        Optional<User> user = userService.login(request.getFirebaseUid());
        if (user.isPresent()) {
            return ResponseEntity.ok(user.get()); // User 객체 반환
        } else {
            return ResponseEntity.status(401).body("사용자를 찾을 수 없습니다."); // String 반환
        }
    }


    // 회원가입
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody UserRequestDTO request) {
        if (request.getFirebaseUid() == null || request.getFirebaseUid().trim().isEmpty() ||
                request.getUsername() == null || request.getUsername().trim().isEmpty() ||
                request.getEmail() == null || request.getEmail().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("firebaseUid, username, email이 필요합니다.");
        }

        try {
            User newUser = userService.registerUser(request.getFirebaseUid(), request.getUsername(), request.getEmail());
            return ResponseEntity.ok(newUser);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 자동 로그인 (없으면 회원가입 후 반환)
    @PostMapping("/auto-login")
    public ResponseEntity<User> autoLogin(@RequestBody UserRequestDTO request) {
        if (request.getFirebaseUid() == null || request.getFirebaseUid().trim().isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        // FirebaseUid가 없을 경우 자동으로 "Unknown User", "unknown@example.com"을 기본값으로 사용
        String username = request.getUsername() != null && !request.getUsername().trim().isEmpty() ? request.getUsername() : "Unknown User";
        String email = request.getEmail() != null && !request.getEmail().trim().isEmpty() ? request.getEmail() : "unknown@example.com";

        User user = userService.autoLogin(request.getFirebaseUid(), username, email);

        return ResponseEntity.ok(user);
    }
}
