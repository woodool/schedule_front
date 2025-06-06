package org.example.domain.user;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    @GetMapping("/{firebaseUid}")
    public ResponseEntity<User> getUserInfo(@PathVariable String firebaseUid) {
        User user = userService.getUserByFirebaseUid(firebaseUid);
        return ResponseEntity.ok(user);
    }
} 