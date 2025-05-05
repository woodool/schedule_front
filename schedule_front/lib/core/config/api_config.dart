class ApiConfig {
  // 기본 URL 
  // static const String baseUrl = 'http://192.168.219.101:8080/api';
  // static const String baseUrl = 'http://172.16.7.130:8080/api';
  // static const String baseUrl = 'http://192.168.219.101:8080/api';
  // static const String baseUrl = 'http://172.30.1.87:8080/api';
  static const String baseUrl = 'http://172.30.1.89:8080/api';

  // 엔드포인트
  static String get userEndpoint => '$baseUrl/users/me';
  static String get remindersEndpoint => '$baseUrl/reminders';
  static String get schedulesEndpoint => '$baseUrl/schedules';
  static String get authLoginEndpoint => '$baseUrl/auth/login';
  static String get authRegisterEndpoint => '$baseUrl/auth/register';
  
  // 특정 ID를 가진 리소스 URL 생성
  static String reminderById(String id) => '$remindersEndpoint/$id';
  static String scheduleById(String id) => '$schedulesEndpoint/$id';
} 