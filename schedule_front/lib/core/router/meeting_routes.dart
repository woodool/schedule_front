import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:schedule/features/meeting/domain/models/meeting_room.dart';
import 'package:schedule/features/meeting/presentation/pages/meeting_room_create_page.dart';
import 'package:schedule/features/meeting/presentation/pages/meeting_room.dart';

class MeetingRoutes {
  static String? redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    
    // /meeting-room을 /meeting/room으로 리다이렉트
    if (location == '/meeting-room') {
      return '/meeting/room';
    }
    
    return null;
  }

  static List<RouteBase> getRoutes() {
    return [
      // 모임 생성 페이지
      GoRoute(
        path: '/create-meeting',
        builder: (context, state) => const MeetingRoomCreatePage(),
      ),
      
      // 모임방 상세 페이지
      GoRoute(
        path: '/meeting/room',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(
                child: Text('잘못된 접근입니다'),
              ),
            );
          }

          final meetingRoom = extra['meetingRoom'] as MeetingRoom?;
          final participantCount = extra['participantCount'] as int?;
          final userId = extra['userId'] as String?;

          if (meetingRoom == null || participantCount == null || userId == null) {
            return const Scaffold(
              body: Center(
                child: Text('필수 정보가 누락되었습니다'),
              ),
            );
          }

          return MeetingRoomPage(
            meetingRoom: meetingRoom,
            participantCount: participantCount,
            userId: userId,
          );
        },
      ),
    ];
  }
} 