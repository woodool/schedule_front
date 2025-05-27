import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/common_pages/home_page.dart';
import 'features/schedule/presentation/pages/add_reminder_page.dart';
import 'features/schedule/presentation/pages/add_schedule_page.dart';
import 'features/schedule/presentation/pages/edit_reminder_page.dart';
import 'features/schedule/presentation/pages/edit_schedule_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/common_pages/calendar_page.dart';
import 'features/common_pages/meeting_page.dart';
import 'features/common_pages/settings_page.dart';
import 'features/common_widgets/bottom_nav_bar.dart';
import 'features/schedule/domain/models/reminder.dart';
import 'features/schedule/domain/models/schedule.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 기본 로케일을 한국어로 설정
  Intl.defaultLocale = 'ko_KR';
  
  if (kIsWeb) {
    await Firebase.initializeApp();
  } else if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAXZ-qsF3YvKm0jsAgnxvrXnEd3J7zwKcs',
        appId: '1:1014225914940:android:9098b4acb80f9b32f78739',
        messagingSenderId: '1014225914940',
        projectId: 'schedule-c3387',
        storageBucket: 'schedule-c3387.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // 앱 시작 시 자동으로 로그아웃
  await FirebaseAuth.instance.signOut();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TimeHomie',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      routerConfig: goRouter,
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 전달받은 초기 인덱스 사용
    _currentIndex = widget.initialIndex;
    _pages = [
    const HomePage(),
    const CalendarPage(),
    const MeetingPage(),
    const SettingsPage(),
  ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: BottomNavBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
