import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/planning/presentation/pages/planning_room_screen.dart';
import '../../features/planning/domain/models/planning_room.dart';
import '../../features/meeting/presentation/pages/meeting_room.dart';
import '../../features/schedule/domain/models/schedule.dart';
import '../../features/meeting/domain/models/meeting_room.dart';

class PlanningRoutes {
  static const String room = '/planning/room';
  static const String clubRoom = '/club/room';
  static const String meeting = '/meeting';

  static List<RouteBase> getRoutes() {
    return [
      GoRoute(
        path: room,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          if (args == null) {
            return const SizedBox.shrink();
          }
          return PlanningRoomScreen(
            planningRoom: args['planningRoom'] as PlanningRoom,
            participantCount: args['participantCount'] as int? ?? 6,
            userId: args['userId'] as String?,
          );
        },
      ),
      GoRoute(
        path: clubRoom,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          if (args == null) {
            return const SizedBox.shrink();
          }
          return MeetingRoomPage(
            meetingRoom: args['meetingRoom'] as MeetingRoom,
            participantCount: args['participantCount'] as int? ?? 6,
            userId: args['userId'] as String? ?? 'anonymous',
          );
        },
      ),
    ];
  }

  static String? redirect(BuildContext context, GoRouterState state) {
    if (state.matchedLocation.startsWith('/planning/') || 
        state.matchedLocation.startsWith('/club/')) {
      if (state.extra == null) {
        return '/meeting';
      }
    }
    return null;
  }
} 