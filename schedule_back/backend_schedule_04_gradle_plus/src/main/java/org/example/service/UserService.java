package org.example.service;

import org.example.entity.User;
import org.example.repository.UserRepository;
import org.example.util.UserValidator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class UserService {
    private final UserRepository userRepository;
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // 로그인: 사용자 조회 (없으면 null 반환)
    @Transactional(readOnly = true)
    public Optional<User> login(String firebaseUid) {
        logger.info("로그인 시도: firebaseUid={}", firebaseUid);
        return userRepository.findById(firebaseUid);
    }

    // 회원가입: 새 사용자 생성 (이미 존재하면 예외 발생)
    @Transactional
    public User registerUser(String firebaseUid, String username, String email) {
        // 유효성 검사
        UserValidator.validateUser(firebaseUid, username, email);

        // 중복 가입 방지
        if (userRepository.existsById(firebaseUid)) {
            logger.warn("이미 가입된 사용자: firebaseUid={}", firebaseUid);
            throw new IllegalStateException("이미 가입된 사용자입니다.");
        }

        // 새 사용자 등록
        User newUser = new User(firebaseUid, username, email);
        User savedUser = userRepository.save(newUser);
        logger.info("새 사용자 등록: {}", savedUser);
        return savedUser;
    }

    // 자동 로그인: 존재하면 반환, 없으면 새로 등록 후 반환
    @Transactional
    public User autoLogin(String firebaseUid, String username, String email) {
        logger.info("자동 로그인 시도: firebaseUid={}", firebaseUid);

        return userRepository.findById(firebaseUid).orElseGet(() -> {
            logger.info("새 사용자 자동 등록: firebaseUid={}", firebaseUid);
            UserValidator.validateUser(firebaseUid, username, email);
            User newUser = new User(firebaseUid, username, email);
            return userRepository.save(newUser);
        });
    }
}
