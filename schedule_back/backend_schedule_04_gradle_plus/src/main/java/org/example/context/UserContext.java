package org.example.context;

public class UserContext {
    private static final ThreadLocal<String> firebaseUidHolder = new ThreadLocal<>();

    public static void setFirebaseUid(String uid) {
        firebaseUidHolder.set(uid);
    }

    public static String getFirebaseUid() {
        return firebaseUidHolder.get();
    }

    public static void clear() {
        firebaseUidHolder.remove();
    }
}

