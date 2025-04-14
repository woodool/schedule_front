package org.example.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL) // null 값인 필드는 JSON 응답에서 제외
public class UserRequestDTO {
    private String firebaseUid;
    private String username;
    private String email;
}
