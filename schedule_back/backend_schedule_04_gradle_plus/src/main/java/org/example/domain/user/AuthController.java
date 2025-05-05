package org.example.domain.user;

import lombok.RequiredArgsConstructor;
import org.example.domain.user.dto.UserRegisterDTO;
import org.example.domain.user.dto.UserLoginDTO;
import org.example.domain.user.User;
import org.example.domain.user.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody UserRegisterDTO registerDTO) {
        try {
            User user = userService.registerUser(registerDTO);
            return ResponseEntity.ok().body("회원가입이 완료되었습니다.");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody UserLoginDTO loginDTO) {
        try {
            User user = userService.loginUser(loginDTO);
            return ResponseEntity.ok().body("로그인이 완료되었습니다.");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
} 