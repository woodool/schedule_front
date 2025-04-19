package org.example.service;

import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.Timestamp;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.WriteResult;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class FCMService {

    private final Firestore firestore = FirestoreClient.getFirestore();

    public void scheduleNotification(String fcmToken, String title, String body, Timestamp firebaseTimestamp) {
        Map<String, Object> notificationData = new HashMap<>();
        notificationData.put("targetToken", fcmToken);
        notificationData.put("title", title);
        notificationData.put("body", body);
        notificationData.put("scheduledTime", firebaseTimestamp);

        DocumentReference docRef = firestore.collection("scheduledNotifications").document();

        ApiFuture<WriteResult> future = docRef.set(notificationData);
        try {
            WriteResult result = future.get();
            System.out.println("Scheduled notification saved at: " + result.getUpdateTime());
        } catch (Exception e) {
            System.err.println("Error saving scheduled notification: " + e.getMessage());
        }
    }
}
