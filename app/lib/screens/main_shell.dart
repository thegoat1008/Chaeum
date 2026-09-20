import 'package:flutter/material.dart';

import '../state/session.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'mission_screen.dart';
import 'profile_screen.dart';

/// 하단 탭 셸. 세 탭이 하나의 [SessionController]를 공유하도록 여기서 스코프를 엽니다.
class MainShell extends StatefulWidget {
  final SessionController session;

  const MainShell({super.key, required this.session});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void dispose() {
    widget.session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: widget.session,
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              HomeScreen(onOpenMission: () => setState(() => _index = 1)),
              const MissionScreen(),
              const ProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 92,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _tab(0, Icons.home_outlined, 'home'),
                _tab(1, Icons.assignment_turned_in_outlined, 'mission'),
                _tab(2, Icons.person_outline, 'profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final color = _index == index ? AppColors.primary : AppColors.textGrey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }
}
