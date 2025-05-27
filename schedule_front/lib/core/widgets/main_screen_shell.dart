import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/common_widgets/bottom_nav_bar.dart';

class MainScreenShell extends StatefulWidget {
  final Widget child;

  const MainScreenShell({
    super.key,
    required this.child,
  });

  @override
  State<MainScreenShell> createState() => _MainScreenShellState();
}

class _MainScreenShellState extends State<MainScreenShell> {
  int _currentIndex = 0;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/calendar');
        break;
      case 2:
        context.go('/meeting');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: BottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 