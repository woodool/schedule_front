import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 참가자 목록 드로어 위젯
/// 일정 계획에 참여하는 사용자 목록을 보여주는 드로어 위젯입니다.
class ParticipantsDrawerWidget extends StatelessWidget {
  final List<dynamic> participants;
  final String? inviteCode;
  final VoidCallback onCopyInvitationCode;
  final VoidCallback onClose;

  const ParticipantsDrawerWidget({
    Key? key,
    required this.participants,
    this.inviteCode,
    required this.onCopyInvitationCode,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 전체 참가자 정보 로깅
    print('👥 참가자 목록 수: ${participants.length}');
    for (var i = 0; i < participants.length; i++) {
      print('👤 참가자 #$i: ${participants[i]}');
    }
    
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
            child: participants.isEmpty 
              ? const Center(
                  child: Text(
                    '참여자가 없습니다.',
                    style: TextStyle(color: Colors.black),
                  ),
                )
              : ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  // 홈페이지에서 사용하는 방식과 정확히 일치시키기
                  // Firebase UID 기반으로 username을 가져오도록 수정
                  String userName = '사용자';
                  
                  // 사용자 정보 디버깅 (전체 정보 확인)
                  print('👤 #$index 참가자 정보: ${participant.toString()}');
                  
                  // username 필드 우선 사용
                  if (participant['username'] != null && participant['username'].toString().isNotEmpty) {
                    userName = participant['username'].toString();
                    print('  ✅ username 필드 사용: $userName');
                  }
                  // name 필드가 있으면 사용
                  else if (participant['name'] != null && participant['name'].toString().isNotEmpty) {
                    userName = participant['name'].toString();
                    print('  ℹ️ name 필드 사용: $userName');
                  }
                  // email이 있으면 @ 앞부분 사용
                  else if (participant['email'] != null && participant['email'].toString().isNotEmpty) {
                    final email = participant['email'].toString();
                    final atIndex = email.indexOf('@');
                    if (atIndex > 0) {
                      userName = email.substring(0, atIndex);
                      print('  ⚠️ email에서 추출: $userName');
                    } else {
                      userName = email;
                      print('  ⚠️ email 전체 사용: $userName');
                    }
                  } else {
                    print('  ❌ 이름 정보 없음: 기본값 "$userName" 사용');
                  }
                  
                  print('  📝 최종 표시 이름: $userName');
                  
                  final bool isCreator = participant['isCreator'] ?? false;
                  
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      isCreator ? '(방장) $userName' : userName,
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
          // 초대 코드 복사 버튼 - UI 개선
          if (inviteCode != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  // 초대코드를 클립보드에 복사
                  Clipboard.setData(ClipboardData(text: inviteCode!));
                  // 콜백 실행
                  onCopyInvitationCode();
                },
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
} 