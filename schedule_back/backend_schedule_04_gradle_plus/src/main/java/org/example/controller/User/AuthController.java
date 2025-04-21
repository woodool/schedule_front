package org.example.controller.User;

import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import lombok.RequiredArgsConstructor;
import org.example.dto.User.FirebaseAuthRequestDTO;
import org.example.entity.User;
import org.example.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final UserService userService;
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody FirebaseAuthRequestDTO request) throws FirebaseAuthException {
        // Firebase ID 토큰을 검증하고 로그인 처리
        String idToken = request.getIdToken();
        FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
        String firebaseUid = decodedToken.getUid();

        User user = userService.loginUser(firebaseUid, request.getFcmToken());
        return ResponseEntity.ok("로그인 성공 - 사용자: " + user.getUsername());
    }
}
