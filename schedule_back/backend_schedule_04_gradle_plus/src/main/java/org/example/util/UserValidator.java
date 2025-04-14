package org.example.util;

import org.springframework.util.StringUtils;

public class UserValidator {

    // 사용자 입력값 유효성 검사
    public static void validateUser(String firebaseUid, String username, String email) {
        if (!StringUtils.hasText(firebaseUid)) {
            throw new IllegalArgumentException("firebaseUid는 필수입니다.");
        }
        if (!StringUtils.hasText(username)) {
            throw new IllegalArgumentException("username은 필수입니다.");
        }
        if (!StringUtils.hasText(email)) {
            throw new IllegalArgumentException("email은 필수입니다.");
        }
    }
}
