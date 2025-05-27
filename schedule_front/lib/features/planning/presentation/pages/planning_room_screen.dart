import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/planning_room.dart';
import '../../domain/models/planning_final.dart';
import '../controllers/planning_room_controller.dart';
import '../widgets/participants_drawer_widget.dart';
import '../widgets/planning_room_widget.dart';
import '../widgets/planning_voting_widget.dart';
import '../widgets/planning_waiting_widget.dart';
import '../widgets/planning_result_widget.dart';
import 'package:go_router/go_router.dart';

class PlanningRoomScreen extends StatefulWidget {
  final PlanningRoom planningRoom;
  final int participantCount;
  final String? userId;

  const PlanningRoomScreen({
    Key? key,
    required this.planningRoom,
    this.participantCount = 6,
    this.userId,
  }) : super(key: key);

  @override
  State<PlanningRoomScreen> createState() => _PlanningRoomScreenState();
}

class _PlanningRoomScreenState extends State<PlanningRoomScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PlanningRoomController _controller;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 결과 화면 상태 변수
  bool _isRegistering = false;
  bool _isRegistered = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = PlanningRoomController(
      planningRoom: widget.planningRoom,
      userId: widget.userId,
      onLoadingChanged: (loading) {
        if (mounted) {
          setState(() => _isLoading = loading);
        }
      },
      onErrorChanged: (error) {
        if (mounted) {
          setState(() => _errorMessage = error);
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        }
      },
      onDataChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    if (!_controller.isCreator && widget.participantCount > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2인 이상 방에서는 방장만 날짜를 변경할 수 있습니다')),
      );
      return;
    }

    final currentRoom = _controller.updatedRoom ?? widget.planningRoom;
    final DateTime now = DateTime.now();
    final DateTime firstDate = now.isBefore(currentRoom.startDate) 
        ? now 
        : currentRoom.startDate.subtract(const Duration(days: 1));

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: currentRoom.startDate,
        end: currentRoom.endDate,
      ),
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      try {
        setState(() => _isLoading = true);
        if (widget.planningRoom.roomId != null) {
          await _controller.updateRoomDateRange(picked.start, picked.end);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('날짜 범위가 업데이트되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('날짜 범위 업데이트 실패: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _copyInvitationCode() {
    final inviteCode = widget.planningRoom.inviteCode;
    if (inviteCode != null && inviteCode.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초대 코드가 복사되었습니다: $inviteCode'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('초대 코드를 찾을 수 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _startPlanningSchedule() async {
    try {
      await _controller.startVoting();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('투표 시작 실패: $e')),
        );
      }
    }
  }

  Future<void> _submitVotes() async {
    try {
      await _controller.submitVotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('투표 제출 실패: $e')),
        );
      }
    }
  }

  Future<void> _retryVoting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('투표 취소'),
        content: const Text('투표를 취소하시겠습니까?\n다시 투표할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _controller.cancelVote();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('투표 취소 실패: $e')),
          );
        }
      }
    }
  }

  Future<void> _registerToMySchedule() async {
    setState(() {
      _isRegistering = true;
      _message = '';
    });

    try {
      await _controller.registerToMySchedule();
      setState(() {
        _isRegistered = true;
        _message = '일정이 성공적으로 등록되었습니다!';
      });
    } catch (e) {
      setState(() {
        _message = '일정 등록에 실패했습니다: $e';
      });
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }

    switch (_controller.roomState) {
      case RoomState.VOTING:
        return PlanningVotingWidget(
          controller: _controller,
          onSubmitVotes: _submitVotes,
        );
      case RoomState.WAITING:
        return PlanningWaitingWidget(
          controller: _controller,
          onRetryVoting: _retryVoting,
        );
      case RoomState.RESULT:
        if (_controller.finalSchedule != null) {
          return PlanningResultWidget(
            finalSchedule: _controller.finalSchedule!,
            isRegistering: _isRegistering,
            isRegistered: _isRegistered,
            message: _message,
            onRegisterToMySchedule: _registerToMySchedule,
          );
        }
        return const Center(child: Text('최종 일정을 불러올 수 없습니다.'));
      case RoomState.ROOM:
      default:
        return PlanningRoomWidget(
          controller: _controller,
          onSelectDateRange: _selectDateRange,
          onStartPlanningSchedule: _startPlanningSchedule,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/meeting');
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        endDrawer: ParticipantsDrawerWidget(
          participants: _controller.participants,
          inviteCode: widget.planningRoom.inviteCode,
          onCopyInvitationCode: _copyInvitationCode,
          onClose: () => Navigator.pop(context),
        ),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go('/meeting'),
          ),
          title: Text(
            widget.planningRoom.roomName,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (_controller.isCreator && _controller.roomState == RoomState.ROOM)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () {
                  // 수정 화면으로 이동하는 로직
                },
                tooltip: '일정 계획 수정',
              ),
            GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.black, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_controller.participants.length}명',
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
          ],
        ),
        body: _buildBody(),
      ),
    );
  }
} 