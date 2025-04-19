package org.example.util;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.IOException;

@Component
public class FirebaseUtil {

    @Value("${firebase.config.path}")
    private String firebaseConfigPath;

    @PostConstruct
    public void initialize() {
        // Firebase가 이미 초기화되었는지 확인
        if (FirebaseApp.getApps().isEmpty()) {
            try {
                // 서비스 계정 JSON 파일을 사용해 Firebase 초기화
                FileInputStream serviceAccount = new FileInputStream(firebaseConfigPath);
                FirebaseOptions options = new FirebaseOptions.Builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                // FirebaseApp 초기화
                FirebaseApp.initializeApp(options);
                System.out.println("Firebase Initialized Successfully!");
            } catch (IOException e) {
                e.printStackTrace();
                System.err.println("Error initializing Firebase: " + e.getMessage());
            }
        }
    }
}
