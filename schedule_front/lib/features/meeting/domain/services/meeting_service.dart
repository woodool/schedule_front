import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meeting_room.dart';
import '../models/meeting_announcement.dart';
import 'package:schedule/core/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schedule/core/services/auth_service.dart';
import 'package:flutter/material.dart' show TimeOfDay;

class MeetingService {
  final String baseUrl = '${ApiConfig.baseUrl}/meetings';
  
  // 토큰 캐싱 변수
  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  static bool _isTokenRefreshing = false;
  static Future<String?>? _tokenRefreshFuture;

  // HTTP 헤더 생성
  Future<Map<String, String>> _getHeaders({String contentType = 'application/json'}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      final token = await user.getIdToken(true);  // true를 추가하여 강제로 새 토큰 발급
      print('현재 사용자 UID: ${user.uid}');
      print('토큰: ${token!.substring(0, 50)}...'); // 토큰의 일부만 출력
      
      // 현재 사용자의 역할 확인
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role') ?? 'member';
      
      final headers = {
        'Content-Type': contentType,
        'Authorization': 'Bearer $token',
        'Firebase-UID': user.uid,
        'User-Role': userRole, // 역할 정보 추가
      };
      
      print('요청 헤더: $headers');
      return headers;
    } catch (e) {
      print('헤더 생성 중 오류: $e');
      rethrow;
    }
  }

  // 모임방 생성
  Future<MeetingRoom> createMeetingRoom(MeetingRoom room) async {
    try {
      print('모임방 생성 요청 처리 중...');
      print('요청 URL: $baseUrl');
      
      final headers = await _getHeaders();
      final requestBody = room.toJson();
      
      // 헤더 디버깅 출력
      headers.forEach((key, value) {
        final displayValue = key == 'Authorization' 
            ? '${value.substring(0, 30)}...' 
            : value;
        print('헤더 - $key: $displayValue');
      });
      
      print('요청 본문: $requestBody');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과');
        },
      );
      
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 201) {
        if (response.body.isEmpty) {
          // 생성된 모임방 정보 조회 시도
          await Future.delayed(const Duration(milliseconds: 500));
          final rooms = await getMeetingRooms();
          
          // 방금 생성한 모임방 찾기
          final createdRoom = rooms.firstWhere(
            (r) => r.meetingName == room.meetingName && 
                   r.createdBy == room.createdBy,
            orElse: () => room,
          );
          
          return createdRoom;
        }
        
        return MeetingRoom.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('모임방 생성 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('모임방 생성 중 오류: $e');
      rethrow;
    }
  }

  // 모임방 목록 조회
  Future<List<MeetingRoom>> getMeetingRooms() async {
    try {
      print('모임방 목록 조회 시작...');
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과');
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }
        
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => MeetingRoom.fromJson(json)).toList();
      } else {
        throw Exception('모임방 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('모임방 목록 조회 중 오류: $e');
      rethrow;
    }
  }

  // 특정 모임방 조회
  Future<MeetingRoom> getMeetingRoom(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$roomId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return MeetingRoom.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('모임방 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('모임방 조회 중 오류: $e');
      rethrow;
    }
  }

  // 모임방 수정
  Future<MeetingRoom> updateMeetingRoom(MeetingRoom room) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${room.roomId}'),
        headers: await _getHeaders(),
        body: jsonEncode(room.toJson()),
      );

      if (response.statusCode == 200) {
        return MeetingRoom.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('모임 정보 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('모임 정보 수정 중 오류: $e');
      rethrow;
    }
  }

  // 모임방 삭제
  Future<void> deleteMeetingRoom(int roomId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$roomId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 204) {
        throw Exception('모임방 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('모임방 삭제 중 오류: $e');
      rethrow;
    }
  }

  // 초대 코드로 모임방 참가
  Future<MeetingRoom> joinMeetingRoom(String inviteCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/join/$inviteCode'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return MeetingRoom.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('모임방 참가 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('모임방 참가 중 오류: $e');
      rethrow;
    }
  }

  // 참가자 목록 조회
  Future<List<Map<String, dynamic>>> getMeetingParticipants(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$roomId/participants'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception('참가자 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('참가자 목록 조회 중 오류: $e');
      rethrow;
    }
  }

  // 공지사항 목록 조회
  Future<List<MeetingAnnouncement>> getMeetingAnnouncements(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$roomId/announcements'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => MeetingAnnouncement.fromJson(json)).toList();
      } else {
        throw Exception('공지사항 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('공지사항 목록 조회 중 오류: $e');
      rethrow;
    }
  }

  // 공지사항 추가
  Future<MeetingAnnouncement> addMeetingAnnouncement(int roomId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$roomId/announcements'),
        headers: await _getHeaders(),
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        return MeetingAnnouncement.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('공지사항 추가 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('공지사항 추가 중 오류: $e');
      rethrow;
    }
  }

  // 사용자의 모임방 권한 확인
  Future<String?> checkUserRole(int roomId) async {
    try {
      final participants = await getMeetingParticipants(roomId);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      print('참가자 목록: $participants');
      print('현재 사용자 UID: ${user.uid}');

      final userParticipant = participants.firstWhere(
        (p) => p['userId'] == user.uid,
        orElse: () => {},
      );

      print('사용자 권한 정보: $userParticipant');
      
      // 역할 정보 저장
      final prefs = await SharedPreferences.getInstance();
      final role = userParticipant['role'] as String?;
      if (role != null) {
        await prefs.setString('user_role', role);
      }
      
      return role; // 원래 역할 그대로 반환
    } catch (e) {
      print('권한 확인 중 오류: $e');
      return null;
    }
  }

  // 공지사항 수정
  Future<void> updateAnnouncement(int roomId, String announcement) async {
    try {
      print('공지사항 수정 시작 - roomId: $roomId');
      print('공지사항 내용: $announcement');
      
      // 권한 체크 추가
      final role = await checkUserRole(roomId);
      if (role == null) {
        throw Exception('모임방에 참여하지 않은 사용자입니다');
      }
      
      final headers = await _getHeaders(contentType: 'text/plain');
      print('요청 헤더: $headers');
      
      final response = await http.put(
        Uri.parse('$baseUrl/$roomId/announcement'),
        headers: headers,
        body: announcement,
      );

      print('공지사항 수정 응답 - 상태 코드: ${response.statusCode}');
      print('공지사항 수정 응답 - 본문: ${response.body}');

      if (response.statusCode == 200) {
        print('공지사항 수정 성공');
      } else if (response.statusCode == 403) {
        throw Exception('공지사항 수정 권한이 없습니다');
      } else {
        print('공지사항 수정 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('공지사항 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('공지사항 수정 중 오류: $e');
      rethrow;
    }
  }

  // 공지사항 삭제
  Future<void> deleteMeetingAnnouncement(int announcementId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/announcements/$announcementId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 204) {
        throw Exception('공지사항 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('공지사항 삭제 중 오류: $e');
      rethrow;
    }
  }

  // 일정 추가
  Future<void> addToUserSchedule(int roomId) async {
    try {
      final headers = await _getHeaders();
      
      // 모임방 정보 가져오기
      final meetingRoom = await getMeetingRoom(roomId);
      
      // 시간을 HH:mm:ss 형식으로 변환
      String formatTime(DateTime time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      }

      // 시작 시간과 종료 시간 설정 (종료 시간은 시작 시간 + 1시간)
      final startTime = DateTime(
        meetingRoom.startDate.year,
        meetingRoom.startDate.month,
        meetingRoom.startDate.day,
        meetingRoom.timeOfDay.hour,
        meetingRoom.timeOfDay.minute,
      );
      
      final endTime = startTime.add(const Duration(hours: 1));
      
      // 일정 데이터 생성
      final scheduleData = {
        'roomId': roomId,
        'scheduleDate': meetingRoom.startDate.toIso8601String().split('T')[0],
        'startTime': formatTime(startTime),
        'endTime': formatTime(endTime),
        'memo': '모임: ${meetingRoom.meetingName}'
      };

      print('일정 추가 요청 데이터: $scheduleData');

      // 1. 모임 일정에 추가
      final response = await http.post(
        Uri.parse('$baseUrl/$roomId/schedules'),
        headers: headers,
        body: jsonEncode(scheduleData),
      );

      print('모임 일정 추가 응답 - 상태 코드: ${response.statusCode}');
      print('모임 일정 추가 응답 - 본문: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('모임 일정 추가 실패: ${response.statusCode}');
      }

      // 2. 개인 일정에도 추가
      final personalScheduleData = {
        'title': meetingRoom.meetingName,
        'description': '모임 일정',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'displayOnCalendar': true,
        'scheduleType': 'MEETING',
        'priority': 1,
        'reminderMinutesBefore': 30,
      };

      final personalResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/schedules'),
        headers: headers,
        body: jsonEncode(personalScheduleData),
      );

      print('개인 일정 추가 응답 - 상태 코드: ${personalResponse.statusCode}');
      print('개인 일정 추가 응답 - 본문: ${personalResponse.body}');

      if (personalResponse.statusCode != 201 && personalResponse.statusCode != 200) {
        throw Exception('개인 일정 추가 실패: ${personalResponse.statusCode}');
      }

    } catch (e) {
      print('일정 추가 중 오류: $e');
      rethrow;
    }
  }

  // 공지사항 조회
  Future<String?> getAnnouncement(int roomId) async {
    try {
      print('공지사항 조회 시작 - roomId: $roomId');
      final headers = await _getHeaders(contentType: 'text/plain');
      
      final response = await http.get(
        Uri.parse('$baseUrl/$roomId/announcement'),
        headers: headers,
      );

      print('공지사항 조회 응답 - 상태 코드: ${response.statusCode}');
      print('공지사항 조회 응답 - 본문: ${response.body}');

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 403) {
        print('공지사항 조회 권한 없음');
        return null;
      } else if (response.statusCode == 404) {
        print('공지사항이 없습니다');
        return null;
      } else {
        print('공지사항 조회 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('공지사항 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('공지사항 조회 중 오류: $e');
      rethrow;
    }
  }

  // 메모 조회
  Future<String?> getMemo(int roomId) async {
    try {
      print('메모 조회 시작 - roomId: $roomId');
      final headers = await _getHeaders(contentType: 'text/plain');
      
      final response = await http.get(
        Uri.parse('$baseUrl/$roomId/memo'),
        headers: headers,
      );

      print('메모 조회 응답 - 상태 코드: ${response.statusCode}');
      print('메모 조회 응답 - 본문: ${response.body}');

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 403) {
        print('메모 조회 권한 없음');
        return null;
      } else if (response.statusCode == 404) {
        print('메모가 없습니다');
        return null;
      } else {
        print('메모 조회 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('메모 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('메모 조회 중 오류: $e');
      rethrow;
    }
  }

  // 메모 수정
  Future<void> updateMemo(int roomId, String memo) async {
    try {
      print('메모 수정 시작 - roomId: $roomId');
      print('메모 내용: $memo');
      
      // 권한 체크 추가
      final role = await checkUserRole(roomId);
      if (role == null) {
        throw Exception('모임방에 참여하지 않은 사용자입니다');
      }
      
      final headers = await _getHeaders(contentType: 'text/plain');
      print('요청 헤더: $headers');
      
      final response = await http.put(
        Uri.parse('$baseUrl/$roomId/memo'),
        headers: headers,
        body: memo,
      );

      print('메모 수정 응답 - 상태 코드: ${response.statusCode}');
      print('메모 수정 응답 - 본문: ${response.body}');

      if (response.statusCode == 200) {
        print('메모 수정 성공');
      } else if (response.statusCode == 403) {
        throw Exception('메모 수정 권한이 없습니다');
      } else {
        print('메모 수정 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('메모 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('메모 수정 중 오류: $e');
      rethrow;
    }
  }

  // 일정 조회
  Future<List<Map<String, dynamic>>> getMeetingSchedules(int roomId) async {
    try {
      print('일정 조회 시작 - roomId: $roomId');
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/$roomId/schedules'),
        headers: headers,
      );

      print('일정 조회 응답 - 상태 코드: ${response.statusCode}');
      print('일정 조회 응답 - 본문: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        print('일정 조회 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('일정 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('일정 조회 중 오류: $e');
      rethrow;
    }
  }

  // 특정 기간의 일정 조회
  Future<List<Map<String, dynamic>>> getMeetingSchedulesByDateRange(
    int roomId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('기간별 일정 조회 시작 - roomId: $roomId');
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse(
          '$baseUrl/$roomId/schedules/range?'
          'startDate=${startDate.toIso8601String().split('T')[0]}&'
          'endDate=${endDate.toIso8601String().split('T')[0]}'
        ),
        headers: headers,
      );

      print('기간별 일정 조회 응답 - 상태 코드: ${response.statusCode}');
      print('기간별 일정 조회 응답 - 본문: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        print('기간별 일정 조회 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('기간별 일정 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('기간별 일정 조회 중 오류: $e');
      rethrow;
    }
  }

  // 사용자 정보 조회
  Future<Map<String, dynamic>> getUserInfo(String firebaseUid) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$firebaseUid'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('사용자 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 정보 조회 중 오류: $e');
      rethrow;
    }
  }

  // 참가자 정보 업데이트 (username 포함)
  Future<List<Map<String, dynamic>>> getParticipantsWithUserInfo(int roomId) async {
    try {
      final participants = await getMeetingParticipants(roomId);
      
      // 각 참가자의 사용자 정보 조회
      final updatedParticipants = await Future.wait(
        participants.map((participant) async {
          try {
            final userInfo = await getUserInfo(participant['userId']);
            return {
              ...participant,
              'username': userInfo['username'],
              'email': userInfo['email'],
            };
          } catch (e) {
            print('참가자 정보 조회 실패: ${participant['userId']} - $e');
            return participant;
          }
        }),
      );
      
      return updatedParticipants;
    } catch (e) {
      print('참가자 정보 업데이트 중 오류: $e');
      rethrow;
    }
  }
} 