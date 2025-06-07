import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/schedule/presentation/pages/add_reminder_page.dart';
import '../../features/schedule/presentation/pages/add_schedule_page.dart';
import '../../features/schedule/presentation/pages/edit_reminder_page.dart';
import '../../features/schedule/presentation/pages/edit_schedule_page.dart';
import '../../features/schedule/presentation/pages/schedule_from_image.dart';
import '../../features/schedule/domain/models/reminder.dart';
import '../../features/schedule/domain/models/schedule.dart';
import '../../features/common_pages/home_page.dart';
import '../../features/common_pages/calendar_page.dart';
import '../../features/common_pages/meeting_page.dart';
import '../../features/common_pages/settings_page.dart';
import '../../features/planning/presentation/pages/create_planning_page.dart';
import '../widgets/main_screen_shell.dart';
import 'planning_routes.dart';
import 'meeting_routes.dart';
import '../../features/schedule/presentation/pages/schedule_search_page.dart';
import '../../features/common_pages/profile_page.dart';
import '../../features/common_pages/change_password_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  debugLogDiagnostics: true,  // 라우팅 디버그 로그 활성화
  redirect: (BuildContext context, GoRouterState state) {
    // 현재 인증 상태 확인
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final location = state.matchedLocation;
    
    print('DEBUG: Current auth state - isLoggedIn: $isLoggedIn, location: $location');
    
    // 인증이 필요한 경로 목록
    final protectedRoutes = [
      '/',
      '/calendar',
      '/meeting',
      '/settings',
      '/add-reminder',
      '/add-schedule',
      '/edit-reminder',
      '/edit-schedule',
      '/planning/room',
      '/meeting/room',
    ];
    
    // 인증이 필요하지 않은 경로 목록
    final publicRoutes = ['/login', '/signup'];
    
    // 로그인하지 않은 경우
    if (!isLoggedIn) {
      final isPublicRoute = publicRoutes.contains(location);
      final redirectTo = isPublicRoute ? null : '/login';
      print('DEBUG: Not logged in - isPublicRoute: $isPublicRoute, redirectTo: $redirectTo');
      return redirectTo;
    }
    
    // 로그인한 경우
    if (publicRoutes.contains(location)) {
      print('DEBUG: Logged in, accessing public route - redirecting to /');
      return '/';
    }
    
    // /planning-room을 /planning/room으로 리다이렉트
    if (location == '/planning-room') {
      return '/planning/room';
    }

    // Planning 라우트 리다이렉션 체크
    final planningRedirect = PlanningRoutes.redirect(context, state);
    if (planningRedirect != null) {
      return planningRedirect;
    }
    
    // Meeting 라우트 리다이렉션 체크
    final meetingRedirect = MeetingRoutes.redirect(context, state);
    if (meetingRedirect != null) {
      return meetingRedirect;
    }
    
    print('DEBUG: No redirection needed');
    return null;
  },
  routes: [
    // 인증 관련 라우트
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignupPage(),
    ),
    
    // 메인 ShellRoute (하단 네비게이션 바를 포함하지않는 화면들)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScreenShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
          routes: [
            GoRoute(
              path: 'add-schedule',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final initialDate = state.extra as DateTime?;
                return AddSchedulePage(initialDate: initialDate);
              },
            ),
            GoRoute(
              path: 'add-reminder',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const AddReminderPage(),
            ),
            GoRoute(
              path: 'edit-schedule/:id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final schedule = state.extra as Schedule;
                return EditSchedulePage(schedule: schedule);
              },
            ),
            GoRoute(
              path: 'edit-reminder/:id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final reminder = state.extra as Reminder;
                return EditReminderPage(reminder: reminder);
              },
            ),
            GoRoute(
              path: 'schedule-from-image',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final image = state.extra as File;
                return ScheduleFromImagePage(initialImage: image);
              },
            ),
            GoRoute(
              path: 'schedule/search',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const ScheduleSearchPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarPage(),
          routes: [
            GoRoute(
              path: 'add-schedule',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final initialDate = state.extra as DateTime?;
                return AddSchedulePage(initialDate: initialDate);
              },
            ),
            GoRoute(
              path: 'edit-schedule/:id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final schedule = state.extra as Schedule;
                return EditSchedulePage(schedule: schedule);
              },
            ),
            GoRoute(
              path: 'schedule-from-image',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final image = state.extra as File;
                return ScheduleFromImagePage(initialImage: image);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/meeting',
          builder: (context, state) => const MeetingPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
          routes: [
            GoRoute(
              path: 'profile',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const ProfilePage(),
            ),
            GoRoute(
              path: 'change-password',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const ChangePasswordPage(),
            ),
          ],
        ),
      ],
    ),
    // 일정 잡기 방 관련 라우트
    ...PlanningRoutes.getRoutes(),
    // 일정 잡기 생성 라우트
    GoRoute(
      path: '/create-planning',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreatePlanningPage(),
    ),
    // 모임 관련 라우트
    ...MeetingRoutes.getRoutes(),
  ],
); 