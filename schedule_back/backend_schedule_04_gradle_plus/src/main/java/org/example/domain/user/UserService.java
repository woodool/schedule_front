package org.example.domain.user;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import lombok.RequiredArgsConstructor;
import org.example.domain.user.dto.UserRegisterDTO;
import org.example.domain.user.dto.UserLoginDTO;
import org.example.domain.user.User;
import org.example.domain.user.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final FirebaseAuth firebaseAuth;

    @Transactional
    public User registerUser(UserRegisterDTO registerDTO) {
        // Firebase 토큰 검증
        FirebaseToken decodedToken;
        try {
            decodedToken = firebaseAuth.verifyIdToken(registerDTO.getFirebaseToken());
        } catch (FirebaseAuthException e) {
            throw new RuntimeException("Firebase 토큰 검증 실패", e);
        }

        // 이미 존재하는 사용자 확인
        if (userRepository.existsByFirebaseUid(decodedToken.getUid())) {
            throw new RuntimeException("이미 존재하는 사용자입니다.");
        }

        // 사용자 생성
        User user = new User(
            decodedToken.getUid(),
            registerDTO.getUsername(),
            registerDTO.getEmail(),
            passwordEncoder.encode(registerDTO.getPassword())
        );

        return userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public User loginUser(UserLoginDTO loginDTO) {
        // Firebase 토큰 검증
        FirebaseToken decodedToken;
        try {
            decodedToken = firebaseAuth.verifyIdToken(loginDTO.getFirebaseToken());
        } catch (FirebaseAuthException e) {
            throw new RuntimeException("Firebase 토큰 검증 실패", e);
        }

        // 사용자 조회
        return userRepository.findByFirebaseUid(decodedToken.getUid())
                .orElseThrow(() -> new RuntimeException("등록되지 않은 사용자입니다."));
    }
} 