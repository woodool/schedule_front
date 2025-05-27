import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/planning_room.dart';
import '../models/planning_time_suggestion.dart';
import '../models/planning_suggestion_vote.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schedule/core/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schedule/core/services/auth_service.dart';
import '../models/planning_final.dart';

/// 일정 계획방 관련 서비스를 제공하는 클래스
class PlanningService {
  // 중앙 집중식 API 설정 사용
  final String baseUrl;
  
  PlanningService() : baseUrl = ApiConfig.baseUrl;
    
  // 토큰 캐싱 변수 (정적으로 선언하여 앱 전체에서 공유)
  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  
  // 토큰 요청 중인지 나타내는 플래그 (중복 요청 방지)
  static bool _isTokenRefreshing = false;
  // 동시에 여러 요청이 대기할 때 사용할 Future
  static Future<String?>? _tokenRefreshFuture;
  
  // HTTP 헤더 생성 - Bearer 토큰 방식으로 변경 (스케줄 서비스 방식으로 통일)
  Future<Map<String, String>> _getHeaders({bool forceRefresh = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ 로그인된 사용자 없음');
        return {
          'Content-Type': 'application/json',
        };
      }
      
      // 1. 캐시된 토큰이 유효한 경우 즉시 반환 (중복 요청 방지)
      if (!forceRefresh && _cachedToken != null && _tokenExpiry != null) {
        // 토큰이 만료 10분 전이 아니면 캐시된 토큰 사용
        final now = DateTime.now();
        if (now.isBefore(_tokenExpiry!.subtract(Duration(minutes: 10)))) {
          return {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_cachedToken',
          };
        }
      }
      
      // 2. 이미 토큰 갱신 중인 경우 진행 중인 요청을 재사용
      if (_isTokenRefreshing) {
        print('⏳ 이미 진행 중인 토큰 갱신 작업이 있습니다. 기다리는 중...');
        
        // 이미 진행 중인 토큰 갱신 결과 기다리기
        if (_tokenRefreshFuture != null) {
          await _tokenRefreshFuture;
          
          // 다른 요청에 의해 토큰이 갱신되었는지 확인
          if (_cachedToken != null) {
            print('✅ 다른 요청에 의해 갱신된 토큰 사용');
            return {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_cachedToken',
            };
          }
        }
      }
      
      // 3. 새로운 토큰 요청 시작
      _isTokenRefreshing = true;
      
      try {
        // 동시에 여러 요청이 이 코드에 들어올 경우 재사용할 Future 생성
        _tokenRefreshFuture = _refreshToken(user, forceRefresh);
        final token = await _tokenRefreshFuture;
      
      if (token == null || token.isEmpty) {
        print('⚠️ 토큰이 비어있습니다');
        throw Exception('인증 토큰을 가져올 수 없습니다');
      }
      
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      } finally {
        // 토큰 갱신 완료 표시 (성공하든 실패하든 플래그 초기화)
        _isTokenRefreshing = false;
        _tokenRefreshFuture = null;
      }
    } catch (e) {
      print('❌ 인증 토큰 가져오기 실패: $e');
      
      // 오류 발생 시 플래그 초기화
      _isTokenRefreshing = false;
      _tokenRefreshFuture = null;
      
      // 로그인 상태가 아닌 경우 기본 헤더
      return {
        'Content-Type': 'application/json',
      };
    }
  }
  
  // 토큰 갱신 로직 분리 (재사용성 증가)
  Future<String?> _refreshToken(User user, bool forceRefresh) async {
    try {
      if (!forceRefresh) {
        print('🔄 인증 토큰 요청 중...');
      } else {
        print('🔄 인증 토큰 강제 갱신 요청');
      }
      
      final token = await user.getIdToken(forceRefresh);
      
      // 토큰 캐싱 및 만료 시간 설정 (기본 1시간)
      _cachedToken = token;
      _tokenExpiry = DateTime.now().add(Duration(hours: 1));
      
      print('✅ 토큰 획득 성공');
      
      return token;
    } catch (e) {
      print('❌ 토큰 갱신 실패: $e');
      throw e;
    }
  }
  
  /// 새로운 일정 계획방 생성
  Future<PlanningRoom> createPlanningRoom(PlanningRoom planningRoom) async {
    final headers = await _getHeaders();
    final requestBody = planningRoom.toJson();
    
    try {
      print('방 생성 요청 처리 중...');
      
      // 헤더 디버깅 출력
      headers.forEach((key, value) {
        final displayValue = key == 'Authorization' 
            ? '${value.substring(0, 30)}...' 
            : value;
        print('헤더 - $key: $displayValue');
      });
      
      print('요청 본문: $requestBody');
      
      // 타임아웃 설정을 5초로 변경
      final response = await http.post(
        Uri.parse('$baseUrl/planning/rooms'),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('방 생성 요청 타임아웃 - 서버 연결 확인 필요');
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정과 서버 실행 상태를 확인해주세요.');
        },
      );
      
      print('방 생성 응답 수신: ${response.statusCode}');
      print('응답 본문: ${response.body}');
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('인증 오류: ${response.statusCode}');
        throw Exception('로그인이 필요하거나 권한이 없습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 201) {
        // 정상 응답 처리
        try {
          final responseData = json.decode(response.body);
          
          // 초대 코드 및 roomId를 포함한 응답 객체 확인
          if (responseData['inviteCode'] != null && responseData['roomId'] != null) {
            // 서버에서 받은 데이터로 PlanningRoom 객체 생성
            final responseRoom = PlanningRoom.fromJson(responseData);
            
            // 기존 객체에서 필요한 정보가 누락된 경우 원본 객체 정보 보존
            if (responseRoom.roomName.isEmpty && planningRoom.roomName.isNotEmpty) {
              return planningRoom.copyWith(
                roomId: responseRoom.roomId,
                inviteCode: responseRoom.inviteCode,
                createdBy: responseRoom.createdBy ?? FirebaseAuth.instance.currentUser?.uid,
                createdAt: responseRoom.createdAt ?? DateTime.now(),
              );
            }
            
            return responseRoom;
          } else {
            print('잘못된 응답 형식: inviteCode 또는 roomId 누락');
            // 잘못된 응답 형식의 경우 예외 발생
            throw Exception('서버 응답 형식이 올바르지 않습니다. 다시 시도해주세요.');
          }
        } catch (e) {
          print('응답 파싱 오류: $e');
          // JSON 파싱 오류 등 예외가 발생한 경우 예외 throw
          throw Exception('서버 응답을 처리하는 중 오류가 발생했습니다.');
        }
      } else if (response.statusCode >= 500) {
        print('서버 오류: ${response.statusCode}');
        throw Exception('서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        print('API 오류: ${response.statusCode}');
        throw Exception('일정 계획방 생성에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      print('방 생성 중 오류 발생: $e');
      
      // 네트워크 오류, 파싱 오류 등의 경우 예외를 그대로 전달
      throw e;
    }
  }
  
  Future<PlanningRoom> fetchPlanningRoom(int roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/planning/rooms/$roomId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) throw Exception('Failed to load room');
    final jsonMap = json.decode(response.body) as Map<String, dynamic>;
    return PlanningRoom.fromJson(jsonMap);
  }

  Future<String> startVoting(int roomId) async {
    final headers = await _getHeaders();
    
    try {
      print('🔄 투표 시작 요청 - 방 ID: $roomId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/planning/rooms/$roomId/start-voting'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      print('📊 투표 시작 응답: ${response.statusCode}, 본문: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['phase'] as String;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('투표를 시작할 권한이 없습니다. 방장만 시작할 수 있습니다.');
      } else {
        throw Exception('투표 시작에 실패했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ 투표 시작 중 오류: $e');
      throw e;
    }
  }

  Future<String> fetchRoomPhase(int roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/planning/rooms/$roomId/phase'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) throw Exception('Failed to load phase');
    return json.decode(response.body) as String;
  }
  
  /// 일정 계획방 목록 조회
  Future<List<PlanningRoom>> getPlanningRooms() async {
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/planning/rooms/user'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('로그인이 필요하거나 권한이 없습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => PlanningRoom.fromJson(json)).toList();
      } else {
        throw Exception('일정 계획방 목록을 불러오는데 실패했습니다.');
      }
    } catch (e) {
      print('방 목록 조회 중 오류: $e');
      throw e;
    }
  }
  
  /// ID로 일정 계획방 조회
  Future<PlanningRoom> getPlanningRoomById(int roomId) async {
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/planning/rooms/$roomId'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('로그인이 필요하거나 권한이 없습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 200) {
        return PlanningRoom.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('요청한 일정 계획방을 찾을 수 없습니다.');
      } else {
        throw Exception('일정 계획방 정보를 불러오는데 실패했습니다.');
      }
    } catch (e) {
      print('방 정보 조회 중 오류: $e');
      throw e;
    }
  }
  
  /// 일정 계획방 수정
  Future<PlanningRoom> updatePlanningRoom(int roomId, PlanningRoom planningRoom) async {
    final headers = await _getHeaders();
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/planning/rooms/$roomId'),
        headers: headers,
        body: json.encode(planningRoom.toJson()),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('로그인이 필요하거나 권한이 없습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 200) {
        return PlanningRoom.fromJson(json.decode(response.body));
      } else {
        throw Exception('일정 계획방 수정에 실패했습니다.');
      }
    } catch (e) {
      print('방 수정 중 오류: $e');
      throw e;
    }
  }
  
  /// 초대 코드로 일정 계획방 참가
  Future<PlanningRoom> joinPlanningRoom(String inviteCode) async {
    final headers = await _getHeaders();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/planning/rooms/join/$inviteCode'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('로그인이 필요하거나 권한이 없습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 200) {
        return PlanningRoom.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('유효하지 않은 초대 코드입니다.');
      } else {
        throw Exception('일정 계획방 참가에 실패했습니다.');
      }
    } catch (e) {
      print('방 참가 중 오류: $e');
      throw e;
    }
  }
  
  /// 일정 계획방의 참가자 목록 조회
  Future<List<Map<String, dynamic>>> getPlanningParticipants(int roomId) async {
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/planning/rooms/$roomId/participants'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        
        // 응답 데이터 로깅
        print('🔍 참가자 목록 응답 데이터 원본: ${response.body}');
        
        // Firebase로 개별 사용자 정보 조회 (추가 요청)
        List<Map<String, dynamic>> enrichedUserInfoList = [];
        
        // 참가자 정보 처리 및 보강
        for (var json in jsonList) {
          // Map으로 변환하되, 없는 필드는 기본값으로 설정
          final Map<String, dynamic> userInfo = Map<String, dynamic>.from(json);
          
          // 백엔드에서 받은 username 필드 디버그 확인
          print('🧑 백엔드에서 받은 사용자 정보: $userInfo');
          print('👤 username 필드 확인: ${userInfo['username']}');
          print('📝 userId 필드 확인: ${userInfo['userId']}');
          
          try {
            // Firebase UID가 있으면 사용자 정보 추가 조회 시도
            final String? firebaseUid = userInfo['firebaseUid']?.toString();
            if (firebaseUid != null && firebaseUid.isNotEmpty) {
              print('🔍 Firebase UID로 사용자 정보 조회 시도: $firebaseUid');
              
              try {
                // 헤더 가져오기
                final headers = await _getHeaders();
                
                // 사용자 정보 API 호출
                final userResponse = await http.get(
                  Uri.parse('${ApiConfig.baseUrl}/user/$firebaseUid'),
                  headers: headers,
                ).timeout(const Duration(seconds: 3));
                
                if (userResponse.statusCode == 200) {
                  final userData = json.decode(userResponse.body);
                  print('✅ 사용자 정보 조회 성공: $userData');
                  
                  // 사용자 정보에서 username 필드 추출
                  if (userData['username'] != null && userData['username'].toString().isNotEmpty) {
                    userInfo['username'] = userData['username'];
                    print('👤 사용자 정보에서 username 추출: ${userInfo['username']}');
                  }
                }
              } catch (e) {
                print('⚠️ 사용자 정보 조회 실패: $e');
                // 오류 발생 시 기존 정보 사용
              }
            }
          } catch (e) {
            print('⚠️ 사용자 정보 추가 조회 오류: $e');
          }
          
          // 사용자 이름이 비었거나 null이면 다른 필드로 대체 시도
          if (userInfo['username'] == null || userInfo['username'].toString().isEmpty) {
            // 백엔드가 User.java의 username 필드를 사용하도록 수정
            if (userInfo['email'] != null) {
              // 이메일의 @ 앞부분을 임시 이름으로 사용
              final email = userInfo['email'].toString();
              final atIndex = email.indexOf('@');
              if (atIndex > 0) {
                userInfo['username'] = email.substring(0, atIndex);
              } else {
                userInfo['username'] = email;
              }
            } else {
              userInfo['username'] = '사용자';
            }
          }
          
          // 디버그 로그
          print('✏️ 최종 처리된 사용자 데이터: $userInfo');
          enrichedUserInfoList.add(userInfo);
        }
        
        return enrichedUserInfoList;
      } else if (response.statusCode == 404) {
        // 참가자가 없거나 방이 없는 경우 빈 리스트 반환
        print('⚠️ 참가자 목록을 찾을 수 없음 (404): 방 ID=$roomId');
        return [];
      } else {
        print('❌ 참가자 목록 조회 실패: HTTP ${response.statusCode}, 응답: ${response.body}');
        throw Exception('참가자 목록을 불러오는데 실패했습니다.');
      }
    } catch (e) {
      print('❌ 참가자 목록 조회 중 오류 발생: $e');
      // 네트워크 오류 등의 경우 빈 리스트 반환
      return [];
    }
  }
  
  /// 가능한 시간대 계산
  Future<List<PlanningTimeSuggestion>> calculateAvailableTimeSlots(int roomId) async {
    try {
      // 토큰 강제 갱신 (인증 문제 해결을 위해)
      var headers = await _getHeaders(forceRefresh: true);
      print('🔑 일정 계산을 위해 인증 토큰 갱신됨');
      
      // 1. 먼저 계산 API를 직접 호출하여 시간대를 계산
      try {
        print('🔍 가능한 시간대 계산 API 호출 (일정 충돌 확인 포함)');
        
        // excludeScheduledTimes=true 파라미터 추가 (참가자들의 기존 일정 제외)
        final calcResponse = await http.post(
          Uri.parse('$baseUrl/planning/rooms/$roomId/calculate-available-times?excludeScheduledTimes=true'),
          headers: headers,
        ).timeout(const Duration(seconds: 15));
        
        print('📊 계산 API 응답: ${calcResponse.statusCode}, 본문: ${calcResponse.body}');
        
        if (calcResponse.statusCode == 401 || calcResponse.statusCode == 403) {
          print('⚠️ 권한 오류: ${calcResponse.statusCode}');
          
          // 먼저 참가자 여부 확인
          final participantsResponse = await http.get(
            Uri.parse('$baseUrl/planning/rooms/$roomId/participants'),
            headers: headers,
          );
          
          if (participantsResponse.statusCode == 200) {
            final participants = json.decode(participantsResponse.body) as List;
            final currentUser = FirebaseAuth.instance.currentUser;
            
            if (currentUser != null) {
              final isParticipant = participants.any((p) => p['userId'] == currentUser.uid);
              if (!isParticipant) {
                throw Exception('해당 방의 참가자가 아닙니다. 먼저 방에 참가해주세요.');
              }
            }
          }
          
          // 토큰 재갱신 시도
          print('🔄 인증 오류 발생, 토큰 재갱신 시도');
          headers = await _getHeaders(forceRefresh: true);
          
          // 토큰 재갱신 후 다시 시도
          final retryCalcResponse = await http.post(
            Uri.parse('$baseUrl/planning/rooms/$roomId/calculate-available-times?excludeScheduledTimes=true'),
            headers: headers,
          ).timeout(const Duration(seconds: 15));
          
          if (retryCalcResponse.statusCode == 200 || retryCalcResponse.statusCode == 201) {
            try {
              List<dynamic> jsonList = json.decode(retryCalcResponse.body);
              print('📋 계산된 시간대 수: ${jsonList.length}');
              
              if (jsonList.isNotEmpty) {
                final suggestions = jsonList.map((json) => 
                  PlanningTimeSuggestion.fromJson(json as Map<String, dynamic>)
                ).toList();
                return suggestions;
              }
            } catch (e) {
              print('⚠️ 재시도 응답 파싱 오류: $e');
            }
          } else {
            print('❌ 재시도 실패: ${retryCalcResponse.statusCode}');
            throw Exception('시간대 계산에 실패했습니다. 다시 시도해주세요.');
          }
        } else if (calcResponse.statusCode == 200 || calcResponse.statusCode == 201) {
          try {
            List<dynamic> jsonList = json.decode(calcResponse.body);
            print('📋 계산된 시간대 수: ${jsonList.length}');
            
            if (jsonList.isNotEmpty) {
              final suggestions = jsonList.map((json) => 
                PlanningTimeSuggestion.fromJson(json as Map<String, dynamic>)
              ).toList();
              return suggestions;
            }
          } catch (e) {
            print('⚠️ 응답 파싱 오류: $e');
          }
        }
      } catch (e) {
        print('⚠️ 계산 API 호출 오류: $e');
        throw e;
      }
      
      // 2. 시간대 조회 API 호출
      print('🔍 시간대 조회 API 호출');
      final response = await http.get(
        Uri.parse('$baseUrl/planning/rooms/$roomId/suggestions'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      print('📊 조회 API 응답: ${response.statusCode}, 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        print('📋 조회된 시간대 수: ${jsonList.length}');
        
        if (jsonList.isEmpty) {
          return [];
        }
        
        try {
          final suggestions = jsonList.map((json) => 
            PlanningTimeSuggestion.fromJson(json as Map<String, dynamic>)
          ).toList();
          return suggestions;
        } catch (e) {
          throw Exception('시간대 제안 정보를 변환하는 중 오류가 발생했습니다: $e');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('로그인이 필요하거나 권한이 없습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 404) {
        return []; // 시간대 제안이 없는 경우 빈 배열 반환
      } else {
        throw Exception('시간대 제안 목록을 조회하는데 실패했습니다.');
      }
    } catch (e) {
      print('❌ 시간대 계산 중 오류 발생: $e');
      throw Exception('시간대 계산 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 일부 인원(percentage%)이 가능한 시간대 계산
  Future<List<PlanningTimeSuggestion>> calculatePartialAvailableTimeSlots(int roomId, int percentage) async {
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/planning/rooms/$roomId/suggestions/partial?percentage=$percentage'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('로그인이 필요하거나 권한이 없습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        
        try {
          final suggestions = jsonList.map((json) => 
            PlanningTimeSuggestion.fromJson(json as Map<String, dynamic>)
          ).toList();
          return suggestions;
        } catch (e) {
          throw Exception('부분 일치 시간대 정보를 변환하는 중 오류가 발생했습니다: $e');
        }
      } else {
        throw Exception('부분 가능한 시간대를 계산하는데 실패했습니다.');
      }
    } catch (e) {
      // 오류 시 빈 배열 반환
      return [];
    }
  }
  
  /// 시간대 제안에 투표
  Future<void> voteForTimeSuggestion(int suggestionId, bool voteFlag) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/planning/suggestions/$suggestionId/votes?voteFlag=$voteFlag'),
      headers: headers,
    );
    
    if (response.statusCode != 201) {
      throw Exception('투표에 실패했습니다.');
    }
  }
  
  /// 모든 참가자의 투표 완료 여부 확인
  Future<bool> checkAllVotesCompleted(int roomId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/planning/rooms/$roomId/check-votes-completed'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as bool;
    } else {
      throw Exception('투표 완료 확인에 실패했습니다.');
    }
  }
  
  /// 투표수에 따라 최종 일정 자동 선택
  Future<PlanningFinal?> selectFinalScheduleByVotes(int roomId, [bool useEarliestOnTie = false]) async {
    // 토큰 강제 갱신
    final headers = await _getHeaders(forceRefresh: true);
    
    try {
      // 동률 처리 방식 파라미터 추가
      String url = '$baseUrl/planning/rooms/$roomId/select-final-by-votes';
      
      // 동률 시 가장 빠른 시간 선택 옵션이 활성화되면 쿼리 파라미터 추가
      if (useEarliestOnTie) {
        url += '?useEarliestOnTie=true';
      }
      
      print('🔄 최종 일정 자동 선택 요청: $url');
      print('📊 요청 헤더: ${headers.toString()}');  // 헤더 디버깅 출력 추가
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      print('📊 최종 일정 선택 응답: ${response.statusCode}, 본문: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return PlanningFinal.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('투표 결과가 없거나 기한이 만료되었습니다.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('일정 선택에 실패했습니다. 권한이 없거나 서버 오류가 발생했습니다.');
      } else {
        throw Exception('최종 일정 선택에 실패했습니다.');
      }
    } catch (e) {
      print('최종 일정 선택 중 오류: $e');
      throw e;
    }
  }
  
  /// 최종 일정 조회
  Future<PlanningFinal?> getFinalSchedule(int roomId) async {
    try {
      // 토큰 강제 갱신으로 시작
      var headers = await _getHeaders(forceRefresh: true);
      print('🔍 최종 일정 조회 시작 - 방 ID: $roomId');
      
      var response = await http.get(
        Uri.parse('$baseUrl/planning/rooms/$roomId/final'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );

      print('📊 최종 일정 조회 응답: ${response.statusCode}, 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 최종 일정 데이터 수신: $data');
        return PlanningFinal.fromJson(data);
      } else if (response.statusCode == 404) {
        print('ℹ️ 최종 일정이 아직 없습니다: roomId=$roomId');
        return null;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('🔄 인증 오류 발생, 토큰 재갱신 후 재시도');
        
        // 토큰 재갱신
        headers = await _getHeaders(forceRefresh: true);
        
        // 재시도
        response = await http.get(
          Uri.parse('$baseUrl/planning/rooms/$roomId/final'),
          headers: headers,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
          },
        );
        
        print('📊 재시도 응답: ${response.statusCode}, 본문: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ 재시도 후 최종 일정 데이터 수신: $data');
          return PlanningFinal.fromJson(data);
        } else if (response.statusCode == 404) {
          print('ℹ️ 재시도 후에도 최종 일정이 없음: roomId=$roomId');
          return null;
        } else {
          print('❌ 재시도 실패: ${response.statusCode}');
          throw Exception('최종 일정 조회 실패 (재시도): ${response.statusCode} - ${response.body}');
        }
      } else {
        print('❌ 최종 일정 조회 실패: ${response.statusCode}');
        throw Exception('최종 일정 조회 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ 최종 일정 조회 중 오류: $e');
      throw Exception('최종 일정을 불러오는데 실패했습니다: $e');
    }
  }
  
  /// 서버 연결 상태 확인
  Future<bool> checkServerConnection() async {
    try {
      // 기본적으로 토큰 갱신하지 않음
      final headers = await _getHeaders(forceRefresh: false);
      
      // 루트 URL로 먼저 시도 (실제 서버가 응답함을 확인)
      print('🔄 서버 루트 URL 확인 시도: ${baseUrl.replaceAll('/api', '')}');
      
      final rootResponse = await http.get(
        Uri.parse(baseUrl.replaceAll('/api', '')),  // api 경로 제외한 기본 URL
        headers: headers, // 헤더 추가
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ 루트 URL 확인 타임아웃');
          return http.Response('', 408);
        },
      );
      
      print('📡 루트 URL 응답 상태 코드: ${rootResponse.statusCode}');
      
      // 루트 URL에 응답이 있으면 서버 연결 성공
      if (rootResponse.statusCode == 200 || 
          rootResponse.statusCode == 401 || 
          rootResponse.statusCode == 403) {
        print('✅ 서버 연결 확인됨 (루트 URL 응답)');
        return true;
      }
      
      // 일반 헬스 체크 시도
      print('🔄 서버 상태 확인 요청: $baseUrl/health');
      
      // 핑 응답 대기 시간을 짧게 설정
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ 서버 상태 확인 타임아웃');
          return http.Response('', 408); // 타임아웃 상태 코드
        },
      );
      
      print('📡 서버 응답 상태 코드: ${response.statusCode}');
      print('📄 서버 응답 본문: ${response.body}');
      
      // 모든 2xx 상태 코드는 성공으로 간주
      bool isConnected = response.statusCode >= 200 && response.statusCode < 300;
      
      // 401/403은 서버가 동작 중이지만 인증 문제가 있는 것이므로 연결은 성공으로 간주
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('🔒 인증은 필요하지만 서버 연결은 확인됨');
        isConnected = true;
      }
      
      // health 엔드포인트가 실패한 경우, 대체 연결 확인 시도
      if (!isConnected) {
        print('🔄 대체 서버 상태 확인 시도');
        bool alternativeCheck = await _checkAlternativeEndpoint();
        if (alternativeCheck) {
          print('✅ 대체 엔드포인트로 서버 연결 확인됨');
          return true;
        }
      }
      
      print(isConnected ? '✅ 서버 연결 성공' : '❌ 서버 연결 실패');
      
      return isConnected;
    } catch (e) {
      print('❌ 서버 연결 확인 중 오류: $e');
      
      // 예외 발생 시 대체 연결 확인 시도
      print('🔄 대체 서버 상태 확인 시도');
      bool alternativeCheck = await _checkAlternativeEndpoint();
      return alternativeCheck;
    }
  }
  
  /// 대체 엔드포인트로 서버 연결 확인
  Future<bool> _checkAlternativeEndpoint() async {
    try {
      // 보통 인증이 필요없는 엔드포인트로 시도
      final endpoints = [
        baseUrl.replaceAll('/api', ''),           // 루트 URL (api 경로 제외)
        '$baseUrl',                               // API 루트 URL
        '${baseUrl.replaceAll('/api', '')}/api',  // API 루트 URL 대체 방식
        '$baseUrl/actuator/health',               // Spring Boot Actuator 헬스 체크
        '$baseUrl/ping',                          // 일반적인 핑 엔드포인트
        '${baseUrl.replaceAll('/api', '')}/actuator/health', // 루트 URL + Actuator
      ];
      
      for (final endpoint in endpoints) {
        try {
          print('🔄 대체 엔드포인트 시도: $endpoint');
          final response = await http.get(
            Uri.parse(endpoint),
          ).timeout(const Duration(seconds: 3));
          
          print('📡 응답 상태 코드: ${response.statusCode}');
          
          // 200, 401, 403 모두 서버가 실행 중이라는 증거
          if (response.statusCode == 200 || response.statusCode == 401 || response.statusCode == 403) {
            print('✅ 서버 연결 확인됨 (경로: $endpoint)');
            return true;
          }
        } catch (e) {
          print('⚠️ 대체 엔드포인트 실패: $endpoint - $e');
          // 계속 다음 엔드포인트 시도
        }
      }
      
      print('❌ 모든 대체 엔드포인트 확인 실패');
      return false;
    } catch (e) {
      print('❌ 대체 연결 확인 중 오류: $e');
      return false;
    }
  }
  
  /// 일정 계획방의 시간대 제안 목록 조회
  Future<List<PlanningTimeSuggestion>> getPlanningTimeSuggestions(int roomId) async {
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/planning/rooms/$roomId/suggestions'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        
        try {
          final suggestions = jsonList.map((json) {
            return PlanningTimeSuggestion.fromJson(json as Map<String, dynamic>);
          }).toList();
          
          return suggestions;
        } catch (e) {
          throw Exception('시간대 제안 정보를 변환하는 중 오류가 발생했습니다: $e');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('로그인이 필요하거나 권한이 없습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 404) {
        return []; // 시간대 제안이 없는 경우 빈 배열 반환
      } else {
        throw Exception('시간대 제안 목록을 조회하는데 실패했습니다.');
      }
    } catch (e) {
      throw Exception('시간대 제안 목록을 조회하는 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 사용자가 해당 방에서 투표를 했는지 확인
  Future<bool> hasUserVoted(int roomId, String userId) async {
    try {
      final token = await AuthService.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/planning/rooms/$roomId/user-votes/$userId/count'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final voteCount = int.tryParse(response.body) ?? 0;
        print('📊 사용자 $userId의 투표 수: $voteCount');
        return voteCount > 0;
      }
      return false;
    } catch (e) {
      print('투표 여부 확인 중 오류: $e');
      return false;
    }
  }
  
  /// 일정 계획방 삭제하기
  Future<bool> deletePlanningRoom(int roomId) async {
    final headers = await _getHeaders();
    
    try {
      print('🗑️ 방 $roomId 삭제 요청');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/planning/rooms/$roomId'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      print('📊 방 삭제 응답 코드: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ 방 삭제 성공');
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('방을 삭제할 권한이 없습니다. 방장만 삭제할 수 있습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('삭제할 방을 찾을 수 없습니다.');
      } else {
        throw Exception('방 삭제에 실패했습니다. (코드: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ 방 삭제 중 오류: $e');
      throw e;
    }
  }

  /// 일정 계획방에서 사용자의 모든 투표 삭제 (투표 취소)
  Future<void> cancelVote(int roomId, String userId) async {
    try {
      // 먼저 사용자의 투표 수 확인
      final voteCount = await countUserVotesInRoom(roomId, userId);
      print('📊 사용자 $userId의 투표 수: $voteCount');
      
      if (voteCount == 0) {
        print('⚠️ 취소할 투표가 없습니다.');
        return;
      }
      
      // 토큰 강제 갱신 (인증 문제 해결을 위해)
      final headers = await _getHeaders(forceRefresh: true);
      print('🔄 투표 취소 시작 - 방 ID: $roomId, 사용자: $userId');
      
      // 해당 방의 사용자 투표를 한 번에 삭제
      final response = await http.delete(
        Uri.parse('$baseUrl/planning/rooms/$roomId/user-votes/$userId'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      print('📊 투표 취소 응답: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ 투표 취소 성공');
      } else if (response.statusCode == 404) {
        print('⚠️ 취소할 투표가 없습니다.');
      } else if (response.statusCode == 403) {
        throw Exception('투표를 취소할 권한이 없습니다. 본인의 투표만 취소할 수 있습니다.');
      } else {
        throw Exception('투표 취소에 실패했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ 투표 취소 중 오류: $e');
      throw e;
    }
  }
  
  /// 방에서 투표를 완료한 참가자 수를 조회
  Future<int> getVotedParticipantsCount(int roomId) async {
    final headers = await _getHeaders();
    
    try {
      // 참가자 전체 목록 조회
      final participantsResponse = await http.get(
        Uri.parse('$baseUrl/planning/rooms/$roomId/participants'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('서버 연결에 실패했습니다. 네트워크 설정을 확인해주세요.');
        },
      );
      
      if (participantsResponse.statusCode != 200) {
        throw Exception('참가자 목록을 조회할 수 없습니다.');
      }
      
      final List<dynamic> participants = json.decode(participantsResponse.body);
      if (participants.isEmpty) {
        return 0;
      }
      
      // 각 참가자별로 투표 여부 확인
      int votedCount = 0;
      
      for (var participant in participants) {
        final userId = participant['userId'];
        if (userId == null) continue;
        
        try {
          final voteCountResponse = await http.get(
            Uri.parse('$baseUrl/planning/rooms/$roomId/user-votes/$userId/count'),
            headers: headers,
          );
          
          if (voteCountResponse.statusCode == 200) {
            final voteCount = int.tryParse(voteCountResponse.body) ?? 0;
            if (voteCount > 0) {
              votedCount++;
            }
          }
        } catch (e) {
          print('⚠️ 참가자 $userId의 투표 상태 조회 실패: $e');
          // 계속 진행
        }
      }
      
      return votedCount;
    } catch (e) {
      print('❌ 투표 완료 참가자 수 조회 중 오류: $e');
      throw e;
    }
  }

  Future<bool> isVotingInProgress(int roomId) async {
    try {
      final token = await AuthService.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/planning/rooms/$roomId/voting-status'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isVoting'] ?? false;
      }
      return false;
    } catch (e) {
      print('투표 진행 상태 확인 중 오류: $e');
      return false;
    }
  }

  // 투표 관련 메서드
  Future<List<PlanningSuggestionVote>> getVotesForSuggestion(int roomId, int suggestionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/planning/rooms/$roomId/suggestions/$suggestionId/votes'),
      headers: await _getHeaders(),
    );
    return (json.decode(response.body) as List)
        .map((json) => PlanningSuggestionVote.fromJson(json))
        .toList();
  }

  Future<PlanningSuggestionVote> voteForSuggestion(int roomId, int suggestionId, String userId, bool voteFlag) async {
    final headers = await _getHeaders();
    headers['Content-Type'] = 'application/json';  // Content-Type 헤더 추가
    
    try {
      print('📤 투표 요청 - 방: $roomId, 제안: $suggestionId, 사용자: $userId, 투표: $voteFlag');
      
      final response = await http.post(
        Uri.parse('$baseUrl/planning/rooms/$roomId/suggestions/$suggestionId/votes'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'voteFlag': voteFlag,
        }),
      );

      print('📥 투표 응답 - 상태 코드: ${response.statusCode}');
      print('📄 응답 본문: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          print('✅ 응답 데이터 파싱 성공: $responseData');
          return PlanningSuggestionVote.fromJson(responseData);
        } catch (e) {
          print('❌ 응답 데이터 파싱 실패: $e');
          throw Exception('투표 응답을 처리하는 중 오류가 발생했습니다: $e');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('로그인이 필요하거나 권한이 없습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('해당 시간대를 찾을 수 없습니다.');
      } else {
        print('❌ 투표 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('투표 처리 중 오류가 발생했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ 투표 처리 중 예외 발생: $e');
      throw Exception('투표 처리 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> deleteVote(int roomId, int suggestionId, String userId) async {
    await http.delete(
      Uri.parse('$baseUrl/planning/rooms/$roomId/suggestions/$suggestionId/votes/user'),
      headers: await _getHeaders(),
    );
  }

  Future<int> countUserVotesInRoom(int roomId, String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/planning/rooms/$roomId/user-votes/$userId/count'),
      headers: await _getHeaders(),
    );
    return int.parse(response.body);
  }

  Future<bool> checkUserVoted(int roomId, String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/planning/rooms/$roomId/user-votes/$userId/check'),
      headers: await _getHeaders(),
    );
    return json.decode(response.body) as bool;
  }

  Future<void> deleteUserVotesInRoom(int roomId, String userId) async {
    await http.delete(
      Uri.parse('$baseUrl/planning/rooms/$roomId/user-votes/$userId'),
      headers: await _getHeaders(),
    );
  }
} 