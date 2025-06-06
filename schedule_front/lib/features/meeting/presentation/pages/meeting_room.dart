import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/meeting_room.dart';
import '../../domain/models/meeting_announcement.dart';
import '../../domain/services/meeting_service.dart';

class MeetingRoomPage extends StatefulWidget {
  final MeetingRoom meetingRoom;
  final int participantCount;
  final String userId;
  
  const MeetingRoomPage({
    super.key,
    required this.meetingRoom,
    required this.participantCount,
    required this.userId,
  });

  @override
  State<MeetingRoomPage> createState() => _MeetingRoomPageState();
}

class _MeetingRoomPageState extends State<MeetingRoomPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MeetingService _meetingService = MeetingService();
  late MeetingRoom _meetingRoom;
  late TextEditingController _descriptionController;
  late TextEditingController _announcementController;
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isEditing = false;
  bool _isLoadingAnnouncements = false;
  String? _announcementError;
  List<MeetingAnnouncement> _announcements = [];
  List<Map<String, dynamic>> _participants = [];
  bool _isRegistering = false;
  bool _isRegistered = false;
  String _registrationMessage = '';

  @override
  void initState() {
    super.initState();
    _meetingRoom = widget.meetingRoom;
    _initializeControllers();
    _selectedDate = _meetingRoom.startDate;
    _selectedTime = _meetingRoom.timeOfDay;
    
    // 초기 데이터 로드
    _loadInitialData();
  }

  void _initializeControllers() {
    _descriptionController = TextEditingController(text: _meetingRoom.description);
    _announcementController = TextEditingController();
    _memoController = TextEditingController();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadAnnouncementAndMemo(),
        _loadAnnouncements(),
        _loadParticipants(),
      ]);
    } catch (e) {
      print('초기 데이터 로드 중 오류: $e');
    }
  }

  Future<bool> _checkUserPermissions() async {
    try {
      final role = await _meetingService.checkUserRole(_meetingRoom.roomId!);
      return role != null; // 참여자라면 true 반환
    } catch (e) {
      print('권한 확인 중 오류: $e');
      return false;
    }
  }

  Future<bool> _checkOwnerPermissions() async {
    try {
      final role = await _meetingService.checkUserRole(_meetingRoom.roomId!);
      return role == 'owner'; // owner인 경우에만 true 반환
    } catch (e) {
      print('방장 권한 확인 중 오류: $e');
      return false;
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        _isLoadingAnnouncements = true;
        _announcementError = null;
      });

      // 권한 체크 추가
      final hasPermission = await _checkUserPermissions();
      if (!hasPermission) {
        throw Exception('공지사항을 볼 수 있는 권한이 없습니다');
      }

      // 단일 공지사항 조회
      final announcement = await _meetingService.getAnnouncement(_meetingRoom.roomId!);
      
      if (mounted) {
        setState(() {
          if (announcement != null && announcement.isNotEmpty) {
            _announcements = [
              MeetingAnnouncement(
                announcementId: null,
                roomId: _meetingRoom.roomId!,
                content: announcement,
                createdBy: '',
                creatorName: null,
                createdAt: DateTime.now(),
              ),
            ];
            _announcementController.text = announcement;
          } else {
            _announcements = [];
            _announcementController.text = '';
          }
          _isLoadingAnnouncements = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _announcementError = e.toString();
          _isLoadingAnnouncements = false;
        });
      }
    }
  }

  Future<void> _loadAnnouncementAndMemo() async {
    try {
      if (_meetingRoom.roomId != null) {
        // 권한 체크 추가
        final hasPermission = await _checkUserPermissions();
        if (!hasPermission) {
          throw Exception('모임방에 참여하지 않은 사용자입니다');
        }

        // 공지사항 로드
        final announcement = await _meetingService.getAnnouncement(_meetingRoom.roomId!);
        if (announcement != null) {
          if (mounted) {
            setState(() {
              _announcementController.text = announcement;
              // 공지사항이 있을 경우 announcements 리스트에도 추가
              _announcements = [
                MeetingAnnouncement(
                  announcementId: null,
                  roomId: _meetingRoom.roomId!,
                  content: announcement,
                  createdBy: '',
                  creatorName: null,
                  createdAt: DateTime.now(),
                ),
              ];
            });
          }
        }

        // 메모 로드
        final memo = await _meetingService.getMemo(_meetingRoom.roomId!);
        if (memo != null && mounted) {
          setState(() {
            _memoController.text = memo;
          });
        }
      }
    } catch (e) {
      print('공지사항/메모 로드 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final participants = await _meetingService.getParticipantsWithUserInfo(_meetingRoom.roomId!);
      if (mounted) {
        setState(() {
          _participants = participants;
        });
      }
    } catch (e) {
      print('참가자 목록 로드 중 오류: $e');
    }
  }

  Future<void> _addAnnouncement(String content) async {
    if (content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공지사항 내용을 입력해주세요.')),
      );
      return;
    }

    try {
      final announcement = await _meetingService.addMeetingAnnouncement(
        _meetingRoom.roomId!,
        content.trim(),
      );

      setState(() {
        _announcements.add(announcement);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공지사항이 등록되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공지사항 등록에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registerToMySchedule() async {
    if (_isRegistering || _isRegistered) return;

    setState(() {
      _isRegistering = true;
      _registrationMessage = '';
    });

    try {
      await _meetingService.addToUserSchedule(_meetingRoom.roomId!);
      
      if (mounted) {
        setState(() {
          _isRegistered = true;
          _isRegistering = false;
          _registrationMessage = '일정이 성공적으로 등록되었습니다.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegistering = false;
          _registrationMessage = '일정 등록에 실패했습니다: ${e.toString()}';
        });
      }
    }
  }

  void _showAddToCalendarDialog() {
    if (_isEditing) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 추가'),
        content: const Text('이 모임을 내 일정에 추가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _registerToMySchedule();
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updateAnnouncement(MeetingAnnouncement announcement) async {
    // 권한 체크 추가
    final hasPermission = await _checkUserPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공지사항을 수정할 권한이 없습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final content = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: announcement.content);
        return AlertDialog(
          title: const Text('공지사항 수정'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '내용',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('수정'),
            ),
          ],
        );
      },
    );

    if (content != null && content.trim().isNotEmpty) {
      try {
        await _meetingService.updateAnnouncement(
          _meetingRoom.roomId!,
          content.trim(),
        );
        
        // 상태 업데이트
        setState(() {
          announcement.content = content.trim();
          _announcementController.text = content.trim();
        });
        
        // 공지사항 목록 새로고침
        await _loadAnnouncements();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공지사항이 수정되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('공지사항 수정에 실패했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAnnouncement(MeetingAnnouncement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지사항 삭제'),
        content: const Text('이 공지사항을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _meetingService.deleteMeetingAnnouncement(announcement.announcementId!);
        await _loadAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공지사항이 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('공지사항 삭제에 실패했습니다: $e')),
          );
        }
      }
    }
  }
  
  // 초대 코드 복사 함수
  void _copyInvitationCode() {
    // TODO: 초대 코드 복사 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대 코드가 복사되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  // 참여자 강퇴 함수
  void _kickParticipant(String name) {
    if (_meetingRoom.createdBy != widget.userId) return;
    
    // TODO: 참여자 강퇴 API 호출
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name님이 강퇴되었습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // 설정 화면 표시
  void _showSettings() async {
    try {
      // 방장 권한 확인
      if (_meetingRoom.createdBy != widget.userId) {
        throw Exception('설정 접근 권한이 없습니다 (방장만 가능)');
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('모임 정보 수정'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isEditing = true;
                    _descriptionController.text = _meetingRoom.description;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('모임 삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 모임 삭제 확인 다이얼로그
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      // 방장 권한 확인
      final isOwner = await _checkOwnerPermissions();
      if (!isOwner) {
        throw Exception('모임방 수정 권한이 없습니다 (방장만 가능)');
      }

      // 1. 모임방 정보 업데이트
      final updatedRoom = _meetingRoom.copyWith(
        description: _descriptionController.text,
        startDate: _selectedDate,
        endDate: _selectedDate,
        timeOfDay: _selectedTime,
      );

      final updated = await _meetingService.updateMeetingRoom(updatedRoom);
      
      // 2. 공지사항 업데이트
      if (_announcementController.text.isNotEmpty) {
        await _meetingService.updateAnnouncement(
          updated.roomId!,
          _announcementController.text.trim(),
        );
        // 공지사항 목록 새로고침
        await _loadAnnouncements();
      }

      // 3. 메모 업데이트
      if (_memoController.text.isNotEmpty) {
        await _meetingService.updateMemo(
          updated.roomId!,
          _memoController.text.trim(),
        );
      }

      // 4. 상태 업데이트
      if (mounted) {
        setState(() {
          _isEditing = false;
          _meetingRoom = updated;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모임 정보가 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('모임 정보 수정에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 방장 여부 확인
    final isCreator = _meetingRoom.createdBy == widget.userId;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildParticipantsDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _meetingRoom.meetingName,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // 참여자 수 표시
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.black, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.participantCount}명',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 방장만 설정/체크 버튼 표시
          if (isCreator) ...[
            _isEditing
                ? IconButton(
                    icon: const Icon(Icons.check, color: Colors.black),
                    onPressed: _saveChanges,
                  )
                : IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: _showSettings,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 소개글 제목
                  const Text(
                    '소개글',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 소개글 내용
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isEditing
                        ? TextField(
                            controller: _descriptionController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '소개글을 입력하세요',
                            ),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            _meetingRoom.description,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 공지사항 제목
                  const Text(
                    '공지사항',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isLoadingAnnouncements)
                    const Center(child: CircularProgressIndicator())
                  else if (_announcementError != null)
                    Center(child: Text(_announcementError!))
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isEditing
                          ? TextField(
                              controller: _announcementController,
                              maxLines: null,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '공지사항을 입력하세요',
                              ),
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            )
                          : _announcements.isEmpty
                              ? const Text(
                                  '등록된 공지사항이 없습니다.',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  _announcements.first.content,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                    ),

                  const SizedBox(height: 24),

                  // 일정 정보 제목
                  const Text(
                    '일정 정보',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: _isEditing ? null : _showAddToCalendarDialog,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _isEditing ? _selectDate : null,
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18, color: Colors.black),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _isEditing ? _selectTime : null,
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18, color: Colors.black),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0062FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_isEditing || _meetingRoom.memo?.isNotEmpty == true)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '메모',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _isEditing
                                        ? TextField(
                                            controller: _memoController,
                                            maxLines: null,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: '메모를 입력하세요',
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            _meetingRoom.memo ?? '',
                                            style: const TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                  ],
                                ),
                              if (_registrationMessage.isNotEmpty && !_isEditing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _registrationMessage,
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 14,
                                      color: _isRegistered ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              if (_isRegistering && !_isEditing)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 참여자 목록 드로워
  Widget _buildParticipantsDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.45,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            alignment: Alignment.centerLeft,
            child: const Text(
              '참여자 목록',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: _participants.isEmpty 
              ? const Center(
                  child: Text(
                    '참여자가 없습니다.',
                    style: TextStyle(color: Colors.black),
                  ),
                )
              : ListView.builder(
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    final participant = _participants[index];
                    String userName = participant['username'] ?? '사용자';
                    final bool isOwner = participant['role'] == 'owner';
                    
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        isOwner ? '(방장) $userName' : userName,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
          ),
          // 초대 코드 복사 버튼은 그대로 유지
          if (_meetingRoom.inviteCode != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _copyInvitationCode,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '초대코드 복사',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _announcementController.dispose();
    _memoController.dispose();
    super.dispose();
  }
} 