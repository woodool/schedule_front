package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.entity.User;
import org.example.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;

    public void registerUser(String uid, String email, String username, String fcmToken) {
        if (userRepository.existsByFirebaseUid(uid)) {
            throw new IllegalStateException("이미 회원가입된 유저입니다.");
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalStateException("이미 등록된 이메일입니다.");
        }
        if (!userRepository.existsByFirebaseUid(uid)) {
            User user = new User(uid, email, username);
            user.setFcmToken(fcmToken);
            userRepository.save(user);
        }
    }

    // 이메일 중복 체크 메서드
    public boolean isEmailAlreadyRegistered(String email) {
        return userRepository.existsByEmail(email);
    }

    public User loginUser(String uid, String fcmToken) {
        // DB에 유저가 있는지 확인
        return userRepository.findByFirebaseUid(uid)
                .map(user -> {
                    user.setFcmToken(fcmToken); // 로그인 시 FCM 토큰 갱신
                    return userRepository.save(user);
                })
                .orElseThrow(() -> new RuntimeException("등록되지 않은 사용자입니다."));
    }
}
