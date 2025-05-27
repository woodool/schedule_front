import 'package:flutter/material.dart';
import 'dart:math' show max; // min, max 함수를 사용하기 위한 import 수정
import 'dart:developer' as developer;
import '../../domain/models/planning_room.dart';
import '../../domain/models/planning_final.dart';
import '../../domain/models/planning_time_suggestion.dart';
import '../../domain/services/planning_service.dart';
import '../../../schedule/domain/models/schedule.dart';
import '../../../schedule/domain/services/schedule_service.dart';

/// 시간 슬롯 데이터를 위한 클래스 (ID와 시간 정보를 함께 저장)
class TimeSlotData {
  final int suggestionId;  // non-null 값으로 저장
  final TimeOfDay time;
  
  TimeSlotData(int? id, this.time) : suggestionId = id ?? -1;  // null인 경우 -1로 저장
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimeSlotData) return false;
    return suggestionId == other.suggestionId && 
           time.hour == other.time.hour && 
           time.minute == other.time.minute;
  }
  
  @override
  int get hashCode => suggestionId.hashCode ^ time.hashCode;
}

/// 방 상태를 나타내는 열거형
enum RoomState {
  ROOM,    // 일정잡기 방 기본 상태 (수정 가능)
  VOTING,  // 가능한 시간대 투표 중
  WAITING, // 본인 투표 완료 – 대기 화면
  RESULT;  // 최종 일정 확정

  @override
  String toString() {
    return name;  // enum의 이름을 문자열로 반환
  }
}

/// PlanningRoom 상태 관리 및 비즈니스 로직을 담당하는 컨트롤러
class PlanningRoomController extends ChangeNotifier {
  final PlanningRoom planningRoom;
  final String? userId;
  final Function(bool) onLoadingChanged;
  final Function(String?) onErrorChanged;
  final Function() onDataChanged;
  final Future<bool> Function()? onNeedPartialMatchConfirmation;
  
  final _planningService = PlanningService();
  
  // 상태 변수들
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCreator = false;
  DateTime _focusedDay;
  DateTime? _selectedDay;
  RoomState _roomState = RoomState.ROOM;  // 초기 상태를 ROOM로 변경
  PlanningFinal? _finalSchedule;
  
  // 데이터
  List<DateTime> _unavailableDates = [];
  List<DateTime> _recommendedDates = [];
  List<dynamic> _participants = [];
  
  // 투표 완료한 참가자 수
  int _votedParticipantsCount = 0;
  
  // TimeSlotData를 사용하도록 수정
  List<TimeSlotData> _availableTimeSlots = [];
  Set<TimeSlotData> _selectedTimeSlots = {};
  
  // 서버에서 받은 시간 제안 목록을 캐시
  List<PlanningTimeSuggestion> _timeSuggestionCache = [];
  
  // 날짜별 시간 슬롯 맵 (캐싱)
  Map<String, List<TimeSlotData>> _timeSlotsByDate = {};
  
  // 사용자의 투표 상태
  bool _hasUserVoted = false;
  
  // 상태 getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => userId;
  bool get isCreator => _isCreator;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  RoomState get roomState => _roomState;
  PlanningFinal? get finalSchedule => _finalSchedule;
  
  // 데이터 getters - TimeOfDay 인터페이스 호환성 유지
  List<DateTime> get unavailableDates => _unavailableDates;
  List<DateTime> get recommendedDates => _recommendedDates;
  List<dynamic> get participants => _participants;
  
  // 사용자 투표 상태
  bool get hasUserVoted => _hasUserVoted;
  set hasUserVoted(bool value) => _hasUserVoted = value;
  
  // 투표 완료한 참가자 수
  int get votedParticipantsCount => _votedParticipantsCount;
  
  /// 투표 완료한 참가자 수 설정
  set votedParticipantsCount(int value) {
    _votedParticipantsCount = value;
  }
  
  // 업데이트된 방 정보 - 날짜 변경 시 사용
  PlanningRoom? _updatedRoom;
  PlanningRoom? get updatedRoom => _updatedRoom;
  
  // UI와의 호환성을 위해 TimeOfDay 리스트로 변환
  List<TimeOfDay> get availableTimeSlots => 
      _availableTimeSlots.map((slot) => slot.time).toList();
  
  // UI와의 호환성을 위해 TimeOfDay 세트로 변환
  Set<TimeOfDay> get selectedTimeSlots => 
      _selectedTimeSlots.map((slot) => slot.time).toSet();
  
  // 토큰 요청 제한을 위한 플래그
  bool _isDisposed = false;
  
  // getter for roomId
  String? get roomId => planningRoom.roomId?.toString();
  
  PlanningRoomController({
    required this.planningRoom,
    required this.userId,
    required this.onLoadingChanged,
    required this.onErrorChanged,
    required this.onDataChanged,
    this.onNeedPartialMatchConfirmation,
  }) : _focusedDay = DateTime.now() {
    _isCreator = userId == planningRoom.createdBy;
    _roomState = _convertPhaseToRoomState(planningRoom.phase);
    
      // 초기화 시 최종 일정 먼저 확인
    _initializeWithFinalCheck();
  }
  
  /// 리소스를 정리하는 dispose 메소드
  @override
  void dispose() {
    // 컨트롤러가 소멸될 때 호출
    _isDisposed = true;
    // 필요한 리소스 정리 로직 추가
    print('PlanningRoomController가 정리되었습니다.');
    super.dispose();
  }
  
  /// 데이터 변경을 알리는 메서드 - UI 갱신에 사용
  void notifyDataChanged() {
    if (!_isDisposed) {
      onDataChanged();
    }
  }
  
  /// 최종 일정 확인 후 초기화를 진행하는 메서드
  Future<void> _initializeWithFinalCheck() async {
    if (planningRoom.roomId == null) {
      _initialize();
      return;
    }
    
    try {
      _setLoading(true);
      
      // 1. 먼저 참가자 목록 로드
      await _loadParticipants();
      
      if (_isDisposed) return;
      
      // 2. 최종 일정 확인 - 403 에러는 재시도하지 않음
      try {
        final finalSchedule = await _planningService.getFinalSchedule(planningRoom.roomId!);
        
        if (_isDisposed) return;
        
        if (finalSchedule != null) {
          _finalSchedule = finalSchedule;
          _roomState = RoomState.RESULT;
          print('👉 최종 일정이 확정된 상태 - RESULT 화면으로 진입');
          onDataChanged();
          _setLoading(false);
          return;
        }
      } catch (e) {
        // 403 에러는 정상적인 상황일 수 있으므로 무시하고 진행
        print('🔍 최종 일정 없음 또는 접근 권한 없음: $e');
      }

      // 3. 투표 상태 확인
      if (userId != null) {
        try {
          // 전체 투표 수 먼저 확인
          final votedCount = await _planningService.getVotedParticipantsCount(planningRoom.roomId!);
          _votedParticipantsCount = votedCount;
          
          // 현재 사용자의 투표 상태 확인
          final hasVoted = await _planningService.hasUserVoted(planningRoom.roomId!, userId!);
          _hasUserVoted = hasVoted;
          
          print('✅ 초기 투표 상태 확인 - 현재 사용자($userId) 투표: $_hasUserVoted, 전체 투표 수: $_votedParticipantsCount/${_participants.length}');
          
          // 모든 참가자가 투표를 완료했는지 확인
          if (_votedParticipantsCount >= _participants.length && _participants.isNotEmpty) {
            // 모든 참가자가 투표를 완료한 경우 최종 일정 선택 시도
            try {
              final finalSchedule = await _planningService.selectFinalScheduleByVotes(planningRoom.roomId!, true);
              if (finalSchedule != null) {
                _finalSchedule = finalSchedule;
                _roomState = RoomState.RESULT;
                print('👉 모든 참가자가 투표를 완료하여 최종 일정 확정 - RESULT 화면으로 진입');
                onDataChanged();
                _setLoading(false);
                return;
              }
            } catch (e) {
              print('⚠️ 최종 일정 선택 실패: $e');
            }
          }
          
          // 투표 상태에 따라 초기 화면 상태 설정
          if (_hasUserVoted) {
            // 현재 사용자가 이미 투표를 완료한 경우
            _roomState = RoomState.WAITING;
            print('👉 사용자($userId)가 투표를 완료한 상태 - WAITING 화면으로 진입');
            onDataChanged();
            _setLoading(false);
            return;
          } else if (_votedParticipantsCount > 0) {
            // 현재 사용자는 투표하지 않았고, 다른 참가자가 투표를 시작한 경우
            _roomState = RoomState.VOTING;
            print('👉 사용자($userId)는 미투표 상태이고 다른 참가자가 투표를 시작한 상태 - VOTING 화면으로 진입');
            // VOTING 상태로 전환 시 투표 가능한 시간대 로드
            await calculateAvailableTimes();
            return;
          }
          
          // 아무도 투표하지 않은 상태
          _roomState = RoomState.ROOM;
          print('👉 아직 투표가 시작되지 않은 상태 - ROOM 화면으로 진입');
          onDataChanged();
          _setLoading(false);
          return;
        } catch (e) {
          print('❌ 투표 상태 확인 중 오류: $e');
          _setError('투표 상태를 확인하는 중 오류가 발생했습니다.');
          _setLoading(false);
          return;
        }
      }
      
      // 4. 기본 상태로 설정 (아무도 투표하지 않은 상태)
      _roomState = RoomState.ROOM;
      print('👉 아직 투표가 시작되지 않은 상태 - ROOM 화면으로 진입');
      
      if (!_isDisposed) {
        _setLoading(false);
        onDataChanged();
      }
      
    } catch (e) {
      print('초기 상태 확인 중 오류: $e');
      _setLoading(false);
      onDataChanged();
    }
  }

  /// 참가자 목록 로드
  Future<void> _loadParticipants() async {
    if (planningRoom.roomId == null) {
      _participants = [];
      return;
    }
    
    try {
      final participants = await _planningService.getPlanningParticipants(planningRoom.roomId!);
      
      if (_isDisposed) return;
      
      print('👥 참가자 목록 로드 완료 - ${participants.length}명');
      for (var participant in participants) {
        print('  - ${participant['username']} (${participant['userId']})');
      }
      
      _participants = participants;
    } catch (e) {
      print('❌ 참가자 목록 로드 실패: $e');
      _participants = [];
    }
  }

  /// 기본 초기화 함수 - 사용자와 참가자 정보 로드
  Future<void> _initialize() async {
    if (userId != null) {
      _isCreator = planningRoom.createdBy == userId;
    }
    
    try {
      await _loadParticipants();
      _roomState = RoomState.ROOM;
      print('👉 기본 초기화 완료 - ROOM 화면으로 진입');
    } catch (e) {
      print('초기화 실패: $e');
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        onDataChanged();
      }
    }
  }
  
  /// 방 상태 확인 - 투표 및 최종 일정 체크
  Future<void> _checkRoomState() async {
    if (planningRoom.roomId == null || userId == null) return;
    
    try {
      // 1. 최종 일정 확인
      final finalSchedule = await _planningService.getFinalSchedule(planningRoom.roomId!);
      
      if (finalSchedule != null) {
        _finalSchedule = finalSchedule;
        _roomState = RoomState.RESULT;
        return;
      }
      
      // 2. 사용자의 투표 여부 확인
      final serverHasUserVoted = await _planningService.hasUserVoted(planningRoom.roomId!, userId!);
      
      print('🔍 _checkRoomState: 서버 투표 상태 확인됨 = $serverHasUserVoted, 현재 상태 = $_hasUserVoted');
      
      // 상태가 다르면 업데이트
      if (serverHasUserVoted != _hasUserVoted) {
        _hasUserVoted = serverHasUserVoted;
        if (_hasUserVoted) {
          _roomState = RoomState.WAITING;
        }
      }
      
      // 3. 투표 진행 상태 확인
      final isVoting = await _planningService.isVotingInProgress(planningRoom.roomId!);
      if (isVoting && _roomState != RoomState.WAITING) {
        _roomState = RoomState.VOTING;
      }
      
    } catch (e) {
      print('❌ 방 상태 확인 중 오류: $e');
      _setError('방 상태를 확인하는 중 오류가 발생했습니다.');
    }
  }
  
  /// 참가자 투표 수를 계산하는 메서드
  Future<void> _calculateVotedParticipantsCount() async {
    if (planningRoom.roomId == null || _isDisposed) return;
    
    try {
      // 서버에서 최신 투표 완료 참가자 수 가져오기
      final votedCount = await _planningService.getVotedParticipantsCount(planningRoom.roomId!);
      
      if (_isDisposed) return;
      
      // 값이 변경되었을 때만 업데이트
      if (_votedParticipantsCount != votedCount) {
        _votedParticipantsCount = votedCount;
        print('✅ 업데이트된 투표 완료 참가자 수: $_votedParticipantsCount/${_participants.length}');
        
        // 상태 변경 알림
        onDataChanged();
      }
    } catch (e) {
      print('⚠️ 투표 완료 참가자 수 계산 중 오류: $e');
    }
  }
  
  /// 사용자의 투표 상태를 확인하고 업데이트합니다.
  Future<void> checkAndUpdateVoteStatus() async {
    if (planningRoom.roomId == null || userId == null || _isDisposed) {
      return;
    }
    
    try {
      _setLoading(true);
      
      // 사용자의 투표 여부 확인
      final hasVoted = await _planningService.hasUserVoted(planningRoom.roomId!, userId!);
      
      // 이전 상태 기록
      final previousState = _hasUserVoted;
      
      // 상태가 변경된 경우에만 업데이트
      if (hasVoted != previousState) {
        _hasUserVoted = hasVoted;
        if (!_isDisposed) {
          onDataChanged();
        }
      }
    } catch (e) {
      print('❌ 투표 상태 확인 중 오류: $e');
      _setError('투표 상태를 확인하는 중 오류가 발생했습니다.');
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }
  
  /// 일정 잡기 버튼 클릭 시 호출되는 메소드 - 추천 시간대 계산
  Future<void> calculateAvailableTimes() async {
    if (planningRoom.roomId == null || _isDisposed) return;
    
    print('📊 추천 시간대 계산 시작 - 날짜 범위: ${planningRoom.startDate} ~ ${planningRoom.endDate}');
    _setLoading(true);
    _setError(null); // 기존 에러 메시지 초기화
    
    try {
      // 1. 시간대 조회 API 호출 (계산 API 호출하지 않음)
      var timeSuggestions = await _planningService.getPlanningTimeSuggestions(planningRoom.roomId!);
      
      // dispose 체크 추가
      if (_isDisposed) return;
      
      // 서버 응답을 캐시에 저장
      _timeSuggestionCache = timeSuggestions;
      
      // 날짜별 시간 슬롯 맵 초기화 (캐싱)
      _timeSlotsByDate.clear();
      
      print('📋 서버에서 총 ${timeSuggestions.length}개의 시간 제안을 로드했습니다');
      
      if (timeSuggestions.isEmpty) {
        // 시간대가 없는 경우에만 계산 API 호출
        print('🔍 기존 시간대가 없어 새로 계산을 시작합니다.');
        await _planningService.calculateAvailableTimeSlots(planningRoom.roomId!);
        
        if (_isDisposed) return;
        
        // 계산 후 다시 조회
        timeSuggestions = await _planningService.getPlanningTimeSuggestions(planningRoom.roomId!);
        _timeSuggestionCache = timeSuggestions;
      }
      
      if (timeSuggestions.isNotEmpty) {
        // PlanningTimeSuggestion 객체에서 날짜 추출
        List<DateTime> dates = timeSuggestions.map((suggestion) => 
          suggestion.suggestionDate
        ).toList();
        
        // 날짜 범위 내에 있는 추천 날짜만 필터링
        dates = dates.where((date) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          final startDateOnly = DateTime(
            planningRoom.startDate.year,
            planningRoom.startDate.month,
            planningRoom.startDate.day
          );
          final endDateOnly = DateTime(
            planningRoom.endDate.year,
            planningRoom.endDate.month,
            planningRoom.endDate.day
          );
          
          final isInRange = !dateOnly.isBefore(startDateOnly) && !dateOnly.isAfter(endDateOnly);
          return isInRange;
        }).toList();
        
        // 모든 시간 제안을 날짜별로 그룹화하고 각 날짜의 사용 가능한 시간 목록 생성
        for (var suggestion in timeSuggestions) {
          String dateKey = '${suggestion.suggestionDate.year}-${suggestion.suggestionDate.month.toString().padLeft(2, '0')}-${suggestion.suggestionDate.day.toString().padLeft(2, '0')}';
          
          if (!_timeSlotsByDate.containsKey(dateKey)) {
            _timeSlotsByDate[dateKey] = [];
          }
          
          // 시작 시간과 ID를 함께 TimeSlotData로 저장
          _timeSlotsByDate[dateKey]!.add(
            TimeSlotData(suggestion.suggestionId, suggestion.startTime)
          );
        }
        
        // 각 날짜의 시간 슬롯을 오름차순으로 정렬
        for (var key in _timeSlotsByDate.keys) {
          _timeSlotsByDate[key]!.sort((a, b) {
            if (a.time.hour != b.time.hour) {
              return a.time.hour.compareTo(b.time.hour); // 시간 기준 오름차순
            }
            return a.time.minute.compareTo(b.time.minute); // 분 기준 오름차순
          });
          
          print('📅 날짜 $key에 ${_timeSlotsByDate[key]!.length}개 시간대 로드됨');
        }
        
        // dispose 체크 추가
        if (_isDisposed) return;
        
        if (dates.isNotEmpty) {
          // 중복 제거 및 정렬
          _recommendedDates = _removeDuplicateDates(dates);
          
          // 날짜가 선택되었을 때 해당 날짜의 사용 가능한 시간 슬롯을 업데이트하는 로직을 추가
          if (_selectedDay != null) {
            _updateAvailableTimeSlotsForSelectedDay(_selectedDay!);
          } else if (_recommendedDates.isNotEmpty) {
            // 선택된 날짜가 없으면 첫 번째 추천 날짜를 선택
            _selectedDay = _recommendedDates.first;
            _updateAvailableTimeSlotsForSelectedDay(_selectedDay!);
          }
          
          _setLoading(false);
          onDataChanged();
        } else {
          _recommendedDates = [];
          _setError('설정된 기간 내에 가능한 시간이 없습니다. 날짜 범위를 변경해보세요.');
          _setLoading(false);
          onDataChanged();
        }
      } else {
        _recommendedDates = [];
        final String reasonMessage = _participants.isEmpty 
            ? '참가자가 없거나 모든 참가자의 일정이 충돌하여 공통 가능 시간이 없습니다.' 
            : '모든 참가자가 공통으로 가능한 시간이 없습니다.';
            
        if (!_isDisposed) {
          _setError('$reasonMessage 날짜 범위를 변경하거나 다른 참가자를 초대해보세요.');
          _setLoading(false);
          onDataChanged();
        }
      }
    } catch (e) {
      _recommendedDates = [];
      
      // dispose 체크 추가
      if (!_isDisposed) {
        _setError('추천 시간을 로드하지 못했습니다: $e');
        _setLoading(false);
      }
    }
  }
  
  /// 부분 일치 사용 여부를 묻는 다이얼로그 표시 (UI에 위임)
  Future<bool> _showPartialMatchDialog() async {
    // dispose 체크 추가
    if (_isDisposed) return false;
    
    // UI에 위임된 다이얼로그 표시 콜백이 있으면 호출
    if (onNeedPartialMatchConfirmation != null) {
      return onNeedPartialMatchConfirmation!();
    }
    // 콜백이 없으면 기본값 false 반환
    return false;
  }
  
  /// 중복 날짜 제거 및 정렬 헬퍼 메소드
  List<DateTime> _removeDuplicateDates(List<DateTime> dates) {
    // 날짜 문자열로 변환하여 Set에 추가 (중복 제거)
    Set<String> dateStrings = {};
    List<DateTime> uniqueDates = [];
    
    for (var date in dates) {
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (!dateStrings.contains(dateStr)) {
        dateStrings.add(dateStr);
        uniqueDates.add(DateTime(date.year, date.month, date.day));
      }
    }
    
    // 날짜순 정렬
    uniqueDates.sort((a, b) => a.compareTo(b));
    return uniqueDates;
  }
  
  /// 날짜 선택 처리
  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    
    // 날짜가 변경되면 해당 날짜의 가능한 시간을 업데이트
    _updateAvailableTimeSlotsForSelectedDay(selectedDay);
    
    // 선택된 시간 슬롯 초기화 (날짜가 변경되면 시간 선택도 초기화)
    _selectedTimeSlots.clear();
    
    onDataChanged();
  }
  
  // 선택한 날짜의 가능한 시간 업데이트 (캐시 사용)
  void _updateAvailableTimeSlotsForSelectedDay(DateTime selectedDay) {
    final dateKey = '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
    
    if (_timeSlotsByDate.containsKey(dateKey)) {
      _availableTimeSlots = _timeSlotsByDate[dateKey]!;
      print('✅ 날짜 $dateKey에 ${_availableTimeSlots.length}개 시간대 로드 (캐시 사용)');
    } else {
      // 캐시에 해당 날짜 데이터가 없으면 서버에서 다시 로드
      _loadAvailableTimeSlotsForSelectedDay(selectedDay);
    }
  }
  
  // 선택한 날짜의 가능한 시간 로드 (서버에서 다시 로드)
  Future<void> _loadAvailableTimeSlotsForSelectedDay(DateTime selectedDay) async {
    if (planningRoom.roomId == null || _isDisposed) return;
    
    try {
      final String dateStr = '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
      print('🔍 날짜($dateStr)에 대한 가능한 시간대 로드 중...');
      
      // 서버에서 가능한 시간대 로드
      var timeSuggestions = await _planningService.getPlanningTimeSuggestions(planningRoom.roomId!);
      
      if (_isDisposed) return;
      
      // 서버 응답을 캐시에 저장
      _timeSuggestionCache = timeSuggestions;
      print('📋 서버에서 총 ${timeSuggestions.length}개의 시간 제안을 로드했습니다.');
      
      // 날짜별 시간 슬롯 맵 초기화 (캐싱)
      _timeSlotsByDate.clear();
      
      // 날짜별로 시간 제안 그룹화
      for (var suggestion in timeSuggestions) {
        String key = '${suggestion.suggestionDate.year}-${suggestion.suggestionDate.month.toString().padLeft(2, '0')}-${suggestion.suggestionDate.day.toString().padLeft(2, '0')}';
        
        if (!_timeSlotsByDate.containsKey(key)) {
          _timeSlotsByDate[key] = [];
        }
        
        _timeSlotsByDate[key]!.add(
          TimeSlotData(suggestion.suggestionId, suggestion.startTime)
        );
      }
      
      // 각 날짜의 시간 슬롯을 오름차순으로 정렬
      for (var key in _timeSlotsByDate.keys) {
        _timeSlotsByDate[key]!.sort((a, b) {
          if (a.time.hour != b.time.hour) {
            return a.time.hour.compareTo(b.time.hour);
          }
          return a.time.minute.compareTo(b.time.minute);
        });
      }
      
      if (_isDisposed) return;
      
      // 선택한 날짜의 시간 슬롯 업데이트
      if (_timeSlotsByDate.containsKey(dateStr)) {
        _availableTimeSlots = _timeSlotsByDate[dateStr]!;
        print('✅ 날짜 $dateStr에 ${_availableTimeSlots.length}개 시간대 로드됨');
        
        // 로드된 시간대 로깅
        if (_availableTimeSlots.isNotEmpty) {
          print('🕒 로드된 시간대:');
          for (var slotData in _availableTimeSlots) {
            print('   ID=${slotData.suggestionId}, 시간=${slotData.time.hour.toString().padLeft(2, '0')}:${slotData.time.minute.toString().padLeft(2, '0')}');
          }
        }
      } else {
        _availableTimeSlots = [];
        print('⚠️ 날짜 $dateStr에 가능한 시간대가 없습니다.');
      }
      
      onDataChanged();
    } catch (e) {
      print('❌ 날짜에 맞는 시간 슬롯 로딩 실패: $e');
      _availableTimeSlots = [];
      onDataChanged();
    }
  }
  
  /// 시간대 선택 토글
  void toggleTimeSlot(TimeOfDay timeSlot) {
    // 전달된 TimeOfDay와 일치하는 TimeSlotData 찾기
    TimeSlotData? matchingSlot;
    for (var slotData in _availableTimeSlots) {
      if (slotData.time.hour == timeSlot.hour && slotData.time.minute == timeSlot.minute) {
        matchingSlot = slotData;
        break;
      }
    }
    
    if (matchingSlot != null) {
      // 선택 상태 토글
      if (_selectedTimeSlots.any((slot) => slot.time.hour == timeSlot.hour && slot.time.minute == timeSlot.minute)) {
        _selectedTimeSlots.removeWhere((slot) => slot.time.hour == timeSlot.hour && slot.time.minute == timeSlot.minute);
        print('🔄 시간대 선택 해제: ${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}, ID=${matchingSlot.suggestionId}');
      } else {
        _selectedTimeSlots.add(matchingSlot);
        print('✅ 시간대 선택: ${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}, ID=${matchingSlot.suggestionId}');
      }
      onDataChanged();
    } else {
      print('⚠️ 선택한 시간(${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')})에 해당하는 TimeSlotData를 찾을 수 없습니다.');
    }
  }
  
  /// 투표 제출
  Future<PlanningFinal?> submitVotes() async {
    if (_selectedTimeSlots.isEmpty) {
      showErrorSnackBar('투표할 시간대를 선택해주세요.');
      return null;
    }
    
    if (planningRoom.roomId == null) {
      showErrorSnackBar('방 정보를 찾을 수 없습니다.');
      return null;
    }
    
    if (userId == null) {
      showErrorSnackBar('로그인이 필요합니다.');
      return null;
    }

    try {
      log('🔄 투표 등록 시작 - 방 ID: ${planningRoom.roomId}, 사용자: $userId');
      log('📊 선택된 시간대 수: ${_selectedTimeSlots.length}');
      
      _setLoading(true);
      
      int successCount = 0;
      int failCount = 0;
      List<String> errorMessages = [];

      // 각 선택된 시간대에 대해 투표 진행
      for (var timeSlot in _selectedTimeSlots) {
        try {
          await _planningService.voteForSuggestion(
            planningRoom.roomId!,
            timeSlot.suggestionId,
            userId!,
            true,
          );
          successCount++;
        } catch (e) {
          log('❌ 개별 시간대 투표 실패: $e');
          errorMessages.add(e.toString());
          failCount++;
        }
      }
      
      log('📊 투표 결과: $successCount 성공, $failCount 실패');
      
      if (failCount > 0) {
        final errorDetail = errorMessages.isNotEmpty 
            ? ': ${errorMessages.first}'
            : '';
        throw Exception('투표 처리 중 오류가 발생했습니다$errorDetail');
      }

      // 투표 성공 후 상태 업데이트
      _hasUserVoted = true;
      _roomState = RoomState.WAITING;
      
      // 투표 완료 참가자 수 업데이트
      await _calculateVotedParticipantsCount();
      
      // 모든 참가자가 투표를 완료했는지 확인
      if (_votedParticipantsCount >= _participants.length && _participants.isNotEmpty) {
        // 최종 일정 선택 시도
        try {
          final finalSchedule = await _planningService.selectFinalScheduleByVotes(planningRoom.roomId!, true);
          if (finalSchedule != null) {
            _finalSchedule = finalSchedule;
            _roomState = RoomState.RESULT;
            return finalSchedule;
          }
        } catch (e) {
          log('⚠️ 최종 일정 선택 실패: $e');
          // 403 에러의 경우 투표 완료 상태 유지
        }
      }

      onDataChanged();
      return null;
    } catch (e) {
      log('❌ 투표 처리 중 오류 발생: $e');
      showErrorSnackBar(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 투표 취소하기
  Future<void> cancelVote() async {
    if (planningRoom.roomId == null || userId == null) {
      throw Exception('방 정보가 없거나 로그인 상태가 아닙니다.');
    }
    
    try {
      _setLoading(true);
      print('🔄 투표 취소 시작 - 방 ID: ${planningRoom.roomId}, 사용자: $userId');
      
      // 서버에서 사용자가 실제로 투표했는지 다시 확인
      final hasVoted = await _planningService.hasUserVoted(planningRoom.roomId!, userId!);
      
      if (!hasVoted) {
        print('⚠️ 투표 취소 불필요: 이미 투표하지 않은 상태');
        return;
      }
      
      // 서버에 투표 취소 요청
      await _planningService.cancelVote(planningRoom.roomId!, userId!);
      
      print('✅ 투표 취소 성공');
      
      // 상태 업데이트
      _hasUserVoted = false;
      _selectedTimeSlots.clear();
      
      // 투표 완료 참가자 수 업데이트
      await _calculateVotedParticipantsCount();
      
      // 투표 상태에 따라 화면 전환
      if (_votedParticipantsCount > 0) {
        print('👉 다른 참가자의 투표가 있는 상태 - VOTING 화면으로 전환');
        _roomState = RoomState.VOTING;
        // VOTING 상태로 전환 시 투표 가능한 시간대 로드
        await calculateAvailableTimes();
      } else {
        print('👉 모든 투표가 취소된 상태 - ROOM 화면으로 전환');
        _roomState = RoomState.ROOM;
      }
      
      if (!_isDisposed) {
        onDataChanged();
      }
    } catch (e) {
      print('❌ 투표 취소 중 오류: $e');
      _setError('투표를 취소하는 중 오류가 발생했습니다.');
      rethrow;
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!_isDisposed) {
      onLoadingChanged(loading);
    }
  }
  
  /// 에러 메시지 설정
  void _setError(String? message) {
    _errorMessage = message;
    if (!_isDisposed) {
      onErrorChanged(message);
    }
  }
  
  /// 월 변경 처리
  void changeMonth(DateTime focusedDay) {
    _focusedDay = focusedDay;
    onDataChanged();
  }
  
  /// 날짜 범위 업데이트
  Future<PlanningRoom> updateRoomDateRange(DateTime startDate, DateTime endDate) async {
    if (planningRoom.roomId == null) {
      throw Exception('방 ID가 없습니다.');
    }
    
    if (_isDisposed) {
      throw Exception('컨트롤러가 이미 dispose되었습니다.');
    }
    
    _setLoading(true);
    
    try {
      print('🔄 날짜 범위 업데이트 시작 - 방 ID: ${planningRoom.roomId}');
      print('📅 새 날짜 범위: $startDate ~ $endDate');
      
      // 기존 방 정보를 복사하여 날짜만 변경
      final updatedRoom = planningRoom.copyWith(
        startDate: startDate,
        endDate: endDate,
      );
      
      // 서버에 업데이트 요청
      final result = await _planningService.updatePlanningRoom(planningRoom.roomId!, updatedRoom);
      
      // planningRoom은 final이므로 직접 수정할 수 없음
      // 대신 업데이트된 방 정보를 저장
      _updatedRoom = result;
      
      print('✅ 날짜 범위 업데이트 성공: ${result.startDate} ~ ${result.endDate}');
      
      // 날짜 범위가 변경되었으므로 추천 날짜와 가능한 시간대를 새로 계산
      // 캘린더, 추천일자 등의 정보를 모두 초기화
      _unavailableDates = [];
      _recommendedDates = [];
      _timeSlotsByDate.clear();
      _availableTimeSlots = [];
      _selectedTimeSlots.clear();
      _timeSuggestionCache = []; // 캐시된 시간 제안도 초기화
      
      // 초기 날짜 설정 (시작일로)
      _selectedDay = result.startDate;
      _focusedDay = result.startDate;
      
      print('🔷 내부 상태 초기화 완료 - 새 날짜 범위에 맞게 데이터 재설정');
      
      // dispose 체크 추가
      if (_isDisposed) {
        throw Exception('컨트롤러가 이미 dispose되었습니다.');
      }
      
      // 상태 업데이트
      _setLoading(false);
      onDataChanged();
      
      return result;
    } catch (e) {
      print('❌ 날짜 범위 업데이트 실패: $e');
      
      // dispose 체크 추가
      if (!_isDisposed) {
        _setError('날짜 범위 업데이트에 실패했습니다: $e');
        _setLoading(false);
      }
      throw e;
    }
  }
  
  // 로깅 헬퍼 메서드
  void log(String message) {
    developer.log(message, name: 'PlanningRoomController');
  }

  // 스낵바 헬퍼 메서드들
  void showErrorSnackBar(String message) {
    onErrorChanged(message);
  }

  void showSuccessSnackBar(String message) {
    onErrorChanged(message);  // 성공 메시지도 에러 채널을 통해 전달
  }

  /// 투표 시작 메서드
  Future<void> startVoting() async {
    try {
      _setLoading(true);
      _roomState = RoomState.VOTING;
      await calculateAvailableTimes();
      onDataChanged();
    } catch (e) {
      _setError('투표 시작 중 오류가 발생했습니다: $e');
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  /// 내 일정에 등록하는 메서드
  Future<void> registerToMySchedule() async {
    if (_finalSchedule == null) {
      _setError('최종 일정이 없습니다.');
      return;
    }

    try {
      _setLoading(true);
      
      // 최종 일정의 시작/종료 시간 계산
      final finalStartTime = DateTime(
        _finalSchedule!.finalDate.year,
        _finalSchedule!.finalDate.month,
        _finalSchedule!.finalDate.day,
        _finalSchedule!.startTime.hour,
        _finalSchedule!.startTime.minute,
      );
      
      final finalEndTime = DateTime(
        _finalSchedule!.finalDate.year,
        _finalSchedule!.finalDate.month,
        _finalSchedule!.finalDate.day,
        _finalSchedule!.endTime.hour,
        _finalSchedule!.endTime.minute,
      );
      
      // 최종 일정을 Schedule 객체로 변환
      final schedule = Schedule(
        title: planningRoom.roomName,
        description: '모임 일정: ${planningRoom.roomName}',
        startTime: finalStartTime,
        endTime: finalEndTime,
        displayOnCalendar: true,
        scheduleType: 'MEETING',  // 모임 일정으로 표시
        priority: 1,  // 높은 우선순위
      );
      
      // ScheduleService를 통해 일정 등록
      final scheduleService = ScheduleService();
      await scheduleService.createSchedule(schedule);
      
      print('✅ 모임 일정 등록 완료: ${schedule.title}');
      print('  시작: ${schedule.startTime}');
      print('  종료: ${schedule.endTime}');
      
      if (!_isDisposed) {
        onDataChanged();
      }
    } catch (e) {
      print('❌ 일정 등록 중 오류: $e');
      _setError('일정 등록 중 오류가 발생했습니다: $e');
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // Phase를 RoomState로 변환하는 메서드
  RoomState _convertPhaseToRoomState(RoomPhase phase) {
    switch (phase) {
      case RoomPhase.ROOM:
        return RoomState.ROOM;
      case RoomPhase.VOTING:
        return RoomState.VOTING;
      case RoomPhase.WAITING:
        return RoomState.WAITING;
      case RoomPhase.RESULT:
        return RoomState.RESULT;
    }
  }

  // 최종 일정 로드 메서드
  Future<void> _loadFinalSchedule() async {
    try {
      _setLoading(true);
      
      // 최종 일정과 참가자 목록을 병렬로 로드
      final futures = await Future.wait([
        _planningService.getFinalSchedule(planningRoom.roomId!),
        _loadParticipants(),
      ]);
      
      final finalSchedule = futures[0] as PlanningFinal?;
      
      if (finalSchedule != null) {
        _finalSchedule = finalSchedule;
        print('✅ 최종 일정 로드 완료');
        print('👥 참가자 목록 로드 완료 - ${_participants.length}명');
        onDataChanged();
      }
    } catch (e) {
      log('❌ 최종 일정 로드 실패: $e');
      showErrorSnackBar('최종 일정을 불러오는데 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }
} 