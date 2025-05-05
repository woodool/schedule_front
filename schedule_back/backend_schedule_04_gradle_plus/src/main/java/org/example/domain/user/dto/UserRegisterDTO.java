package org.example.domain.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserRegisterDTO {
    private String username;
    private String email;
    private String password;
    private String firebaseToken;
} 