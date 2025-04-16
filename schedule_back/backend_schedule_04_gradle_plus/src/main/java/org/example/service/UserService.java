package org.example.service;

import lombok.RequiredArgsConstructor;
import org.example.entity.User;
import org.example.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;

    public void registerUser(String uid, String email, String username) {
        // DB에 이미 유저가 있는지 확인 후 저장
        if (!userRepository.existsByFirebaseUid(uid)) {
            User user = new User(uid, email, username);
            userRepository.save(user);
        }
    }

    public User loginUser(String uid) {
        // DB에 유저가 있는지 확인
        return userRepository.findByFirebaseUid(uid)
                .orElseThrow(() -> new RuntimeException("등록되지 않은 사용자입니다."));
    }
}
