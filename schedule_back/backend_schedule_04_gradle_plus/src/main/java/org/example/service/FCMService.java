package org.example.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;

import java.io.FileInputStream;
import java.io.IOException;

@Service
public class FCMService {

    @EventListener(ContextRefreshedEvent.class)  // ✅ Spring Boot 3.x에서 @PostConstruct 대신 사용
    public void init() {
        try (FileInputStream serviceAccount = new FileInputStream("C:/Firebaseservicekeys/shcedule04-firebase-adminsdk-fbsvc-a4866598d2.json")) {
            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
            }

        } catch (IOException e) {
            throw new RuntimeException("🚨 Firebase 초기화 실패: " + e.getMessage(), e);
        }
    }

    public void sendPushNotification(String firebaseUid, String title, String message) {
        Notification notification = Notification.builder()
                .setTitle(title)
                .setBody(message)
                .build();

        Message fcmMessage = Message.builder()
                .setToken(firebaseUid)
                .setNotification(notification)
                .putData("sound", "default")
                .build();

        try {
            String response = FirebaseMessaging.getInstance().send(fcmMessage);
            System.out.println("✅ 푸시 알림 전송 성공: " + response);
        } catch (Exception e) {
            System.err.println("🚨 푸시 알림 전송 실패: " + e.getMessage());
        }
    }
}
