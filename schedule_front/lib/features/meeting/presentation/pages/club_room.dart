import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../features/schedule/domain/models/schedule.dart';

class ClubRoom extends StatefulWidget {
  final Schedule schedule;
  final bool isHost;
  
  const ClubRoom({
    Key? key,
    required this.schedule,
    this.isHost = false,
  }) : super(key: key);

  @override
  State<ClubRoom> createState() => _ClubRoomState();
}

class _ClubRoomState extends State<ClubRoom> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // 참여자 목록 (예시)
  final List<Map<String, dynamic>> _participants = [
    {'name': '(방장)나', 'isHost': true},
    {'name': '김김김', 'isHost': false},
    {'name': '남남남', 'isHost': false},
    {'name': '담담담', 'isHost': false},
    {'name': '팜팜팜', 'isHost': false},
    {'name': '맘맘맘', 'isHost': false},
  ];
  
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
    if (!widget.isHost) return;
    
    // TODO: 참여자 강퇴 API 호출
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name님이 강퇴되었습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // 설정 화면 표시
  void _showSettings() {
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
                // TODO: 모임 정보 수정 화면으로 이동
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
  }

  @override
  Widget build(BuildContext context) {
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
          widget.schedule.title,
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
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.black, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${_participants.length}명',
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
          
          // 방장만 설정 버튼 표시
          if (widget.isHost)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: _showSettings,
            ),
        ],
      ),
      body: Column(
        children: [
          // 소개글 표시
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
                    child: Text(
                      widget.schedule.description?.isEmpty ?? true
                        ? '소개글이 없습니다.' 
                        : widget.schedule.description!,
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
                  
                  // 공지사항 내용
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '등록된 공지사항이 없습니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 하단 일정 정보 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 일정 정보 표시
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 날짜 및 시간 표시
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(widget.schedule.startTime),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 시간 표시
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(widget.schedule.startTime),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0062FF),
                            ),
                          ),
                        ],
                      ),
                      
                      // 메모 표시
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.note, size: 18, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            '메모',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(left: 26),
                        child: Text(
                          '준비물: 노트북, 필기구',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: Colors.black,
                          ),
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
    );
  }
  
  // 참여자 목록 드로워
  Widget _buildParticipantsDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.45,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '참여자 목록',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                final isCurrentUserHost = widget.isHost;
                final isParticipantHost = participant['isHost'] as bool;
                
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    participant['name'] as String,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // 방장만 다른 참여자 강퇴 버튼 표시 (본인 제외)
                  trailing: isCurrentUserHost && !isParticipantHost ? 
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _kickParticipant(participant['name'] as String),
                    ) : null,
                );
              },
            ),
          ),
          // 초대 코드 복사 버튼
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _copyInvitationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '초대코드 복사',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 