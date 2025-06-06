import 'package:flutter/material.dart';
import 'package:schedule/features/common_widgets/add_button.dart';
import 'package:schedule/features/planning/presentation/pages/create_planning_page.dart';
import 'package:schedule/features/planning/domain/services/planning_service.dart';
import 'package:schedule/features/meeting/domain/services/meeting_service.dart';
import 'package:schedule/features/schedule/domain/services/schedule_service.dart';
import 'package:schedule/features/planning/domain/models/planning_room.dart';
import 'package:schedule/features/meeting/domain/models/meeting_room.dart';
import 'package:schedule/features/planning/presentation/pages/planning_room_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});
//cfd7b54
  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  bool _isScheduleSelected = true;
  final ScheduleService _scheduleService = ScheduleService();
  final PlanningService _planningService = PlanningService();
  final MeetingService _meetingService = MeetingService();
  bool _isLoading = false;
  String? _errorMessage;
  
  // 일정 계획 방 목록
  List<PlanningRoom> _planningRooms = [];
  
  // 모임 방 목록
  List<MeetingRoom> _meetingRooms = [];
  
  // 각 방에 대한 참여자 수를 저장할 맵
  Map<int, int> _participantCounts = {};
  
  // 현재 로그인한 사용자 ID
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRooms();
    });
  }

  // Firebase에서 현재 사용자 ID를 가져오는 함수
  Future<void> _getCurrentUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _currentUserId = user?.uid;
      });
      print('🔑 현재 로그인한 사용자 ID: $_currentUserId');
    } catch (e) {
      print('⚠️ 사용자 ID 가져오기 실패: $e');
    }
  }
  
  // 방 목록을 로드하는 함수
  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_isScheduleSelected) {
        // 일정 계획 방 목록 가져오기
        final rooms = await _planningService.getPlanningRooms();
        final participantCounts = <int, int>{};
        
        for (var room in rooms) {
          if (room.roomId != null) {
            try {
              final participants = await _planningService.getPlanningParticipants(room.roomId!);
              participantCounts[room.roomId!] = participants.length;
            } catch (e) {
              print('일정 방 참여자 수 조회 실패: $e');
              participantCounts[room.roomId!] = 0;
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _planningRooms = rooms;
            _participantCounts = participantCounts;
            _isLoading = false;
          });
        }
      } else {
        // 모임 방 목록 가져오기
        print('모임 방 목록 가져오기 시작');
        final rooms = await _meetingService.getMeetingRooms();
        print('가져온 모임 방 수: ${rooms.length}');
        final participantCounts = <int, int>{};
        
        for (var room in rooms) {
          if (room.roomId != null) {
            try {
              final participants = await _meetingService.getMeetingParticipants(room.roomId!);
              participantCounts[room.roomId!] = participants.length;
              print('모임 방 ${room.roomId}의 참여자 수: ${participants.length}');
            } catch (e) {
              print('모임 방 참여자 수 조회 실패: $e');
              participantCounts[room.roomId!] = 0;
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _meetingRooms = rooms;
            _participantCounts = participantCounts;
            _isLoading = false;
          });
          print('모임 방 목록 상태 업데이트 완료');
        }
      }
    } catch (e) {
      print('방 목록 로드 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '방 목록을 불러오는데 실패했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  // 일정 잡기 페이지로 이동하는 메서드
  void _navigateToCreatePlanningPage() async {
    final result = await context.push('/create-planning');
    
    if (mounted) {
      await _loadRooms();
      
      if (result != null && result is PlanningRoom) {
        final participantCount = _participantCounts[result.roomId] ?? 0;
        if (mounted) {
          context.push('/planning/room', extra: {
            'planningRoom': result,
            'participantCount': participantCount,
            'userId': FirebaseAuth.instance.currentUser?.uid,
          });
        }
      }
    }
  }
  
  // 모임 만들기 페이지로 이동하는 메서드
  void _navigateToCreateMeetingPage() async {
    final result = await context.push('/create-meeting');
    
    if (mounted) {
      await _loadRooms();
      
      if (result != null && result is MeetingRoom) {
        final participantCount = _participantCounts[result.roomId] ?? 0;
        if (mounted) {
          context.push('/meeting/room', extra: {
            'meetingRoom': result,
            'participantCount': participantCount,
            'userId': FirebaseAuth.instance.currentUser?.uid,
          });
        }
      }
    }
  }
  
  // 특정 방으로 이동하는 메서드
  void _navigateToRoomDetail(dynamic room) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방 정보가 없거나 로그인 상태가 아닙니다')),
      );
      return;
    }
    
    int participantCount = _participantCounts[room.roomId] ?? 0;
    
    if (_isScheduleSelected) {
      context.push('/planning/room', extra: {
        'planningRoom': room,
        'participantCount': participantCount,
        'userId': userId,
      }).then((_) => _loadRooms());
    } else {
      context.push('/meeting/room', extra: {
        'meetingRoom': room,
        'participantCount': participantCount,
        'userId': userId,
      }).then((_) => _loadRooms());
    }
  }
  
  // 초대 코드 입력 다이얼로그를 표시하는 메서드
  void _showInviteCodeDialog() {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 코드 입력'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: '초대 코드를 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _joinRoomWithCode(code);
              }
            },
            child: const Text('참가'),
          ),
        ],
      ),
    );
  }
  
  // 초대 코드로 방에 참가하는 메서드
  Future<void> _joinRoomWithCode(String code) async {
    try {
      print('초대코드로 방 참여 시도: $code');
      setState(() => _isLoading = true);
      
      if (_isScheduleSelected) {
        print('일정 방 참여 시도');
        final room = await _planningService.joinPlanningRoom(code);
        print('일정 방 참여 성공: ${room.roomId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정 방에 성공적으로 참가했습니다!')),
          );
        }
      } else {
        print('모임 방 참여 시도');
        final room = await _meetingService.joinMeetingRoom(code);
        print('모임 방 참여 성공: ${room.roomId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모임 방에 성공적으로 참가했습니다!')),
          );
        }
      }
      
      print('방 목록 새로고침 시작');
      setState(() => _isLoading = false);
      await _loadRooms();
      print('방 목록 새로고침 완료');
    } catch (e) {
      print('방 참여 실패: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '방 참가에 실패했습니다: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('방 참가 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 흰색으로 설정
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40), // 상단 여백 조정
            // 상단 이미지
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: size.width * 0.33,
                child: Image.asset(
                  'assets/images/meetingimage.png',
                  width: size.width - 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 탭 선택 영역 (흰색 배경, 보라색 테두리)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: 335, // 정확히 335 너비로 제한
                height: 48, // 정확히 48 높이로 제한
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDFE6FF), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isScheduleSelected = true;
                            });
                            _loadRooms();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isScheduleSelected ? const Color(0xFFDFE6FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Center(
                              child: Text(
                                '일정 잡기',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _isScheduleSelected ? FontWeight.w600 : FontWeight.w400,
                                  height: 1.4,
                                  letterSpacing: -0.025,
                                  color: _isScheduleSelected ? Colors.black : const Color(0xFF505050),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isScheduleSelected = false;
                            });
                            _loadRooms();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isScheduleSelected ? const Color(0xFFDFE6FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Center(
                              child: Text(
                                '모임',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: !_isScheduleSelected ? FontWeight.w600 : FontWeight.w400,
                                  height: 1.4,
                                  letterSpacing: -0.025,
                                  color: !_isScheduleSelected ? Colors.black : const Color(0xFF505050),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 방 목록 영역 (흰색 배경)
            Expanded(
              child: Container(
                width: size.width,
                color: Colors.white, // 목록 부분은 흰색 배경
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _isScheduleSelected
                      ? (_planningRooms.isEmpty
                          ? const Center(child: Text('일정 방이 없습니다.'))
                          : _buildRoomsList(_planningRooms))
                      : (_meetingRooms.isEmpty
                          ? const Center(child: Text('모임 방이 없습니다.'))
                          : _buildRoomsList(_meetingRooms)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AddButton(
        items: [
          AddButtonItem(
            label: '모임방 만들기',
            iconPath: 'assets/images/meeting.png',
            onPressed: _navigateToCreateMeetingPage,
            description: '모임방을 만들어보세요',
          ),
          AddButtonItem(
            label: '일정 잡기',
            iconPath: 'assets/images/bookmark.png',
            onPressed: _navigateToCreatePlanningPage,
            description: '등록된 일정을 기반으로 최적의 날을 잡아드립니다',
          ),
          AddButtonItem(
            label: '초대코드 입력',
            iconPath: 'assets/images/link.png',
            onPressed: _showInviteCodeDialog,
            description: '일정 잡기 또는 모임 초대코드를 입력해 참가해보세요',
          ),
        ],
      ),
    );
  }
  
  // 방 목록을 표시하는 위젯을 생성하는 메서드
  Widget _buildRoomsList(List<dynamic> rooms) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final participantCount = _participantCounts[room.roomId] ?? 0;
        
        return InkWell(
          onTap: () => _navigateToRoomDetail(room),
          onLongPress: () => _showDeleteRoomDialog(room),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isScheduleSelected ? room.roomName : room.meetingName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$participantCount명',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 방 삭제 다이얼로그 표시
  void _showDeleteRoomDialog(dynamic room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('방 삭제'),
        content: Text('\'${_isScheduleSelected ? room.roomName : room.meetingName}\' 방을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom(room);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
  
  // 방 삭제 처리
  Future<void> _deleteRoom(dynamic room) async {
    if (room.roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방 ID가 유효하지 않습니다.')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_isScheduleSelected) {
        await _planningService.deletePlanningRoom(room.roomId);
      } else {
        await _meetingService.deleteMeetingRoom(room.roomId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('방이 삭제되었습니다.')),
        );
        _loadRooms();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('방 삭제 실패: $e')),
        );
      }
    }
  }
} 