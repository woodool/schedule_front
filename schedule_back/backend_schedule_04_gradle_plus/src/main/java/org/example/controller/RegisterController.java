package org.example.controller;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.auth.UserRecord;
import lombok.RequiredArgsConstructor;
import org.example.dto.User.FirebaseAuthRequestDTO;
import org.example.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/auth")
public class RegisterController {
    private final UserService userService;
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody FirebaseAuthRequestDTO request) {
        String idToken = request.getIdToken();
        try {
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            String firebaseUid = decodedToken.getUid();
            String email = decodedToken.getEmail();

            UserRecord userRecord = FirebaseAuth.getInstance().getUser(firebaseUid);
            String username = userRecord.getDisplayName();

            userService.registerUser(firebaseUid, email, username);

            return ResponseEntity.ok("회원가입 완료");
        } catch (FirebaseAuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("회원가입 실패: " + e.getMessage());
        }
    }
}

