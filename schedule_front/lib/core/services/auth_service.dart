import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 로그인한 사용자의 Firebase ID 토큰을 가져옵니다.
  static Future<String> getIdToken() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('사용자가 로그인되어 있지 않습니다.');
    }
    
    final String? idToken = await user.getIdToken(true);
    if (idToken == null) {
      throw Exception('토큰을 가져올 수 없습니다.');
    }
    return idToken;
  }

  // 현재 로그인한 사용자의 UID를 가져옵니다.
  static String? getCurrentUserId() {
    final User? user = _auth.currentUser;
    return user?.uid;
  }

  // 로그인 상태를 확인합니다.
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }
} 