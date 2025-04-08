import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/schedule/presentation/pages/home_page.dart';
import 'features/schedule/presentation/pages/add_reminder_page.dart';
import 'features/schedule/presentation/pages/add_schedule_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '일정 관리',
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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/add_reminder': (context) => const AddReminderPage(),
        '/add_schedule': (context) => const AddSchedulePage(),
      },
    );
  }
}
