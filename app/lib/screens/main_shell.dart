import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'mission_screen.dart';

class MainShell extends StatefulWidget {
  final String userName;
  const MainShell({super.key, required this.userName});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(userName: widget.userName),
      MissionScreen(userName: widget.userName),
      const Center(child: Text('프로필 화면 준비 중')),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: Container(
        height: 92,
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: Row(children: [
            _tab(0, Icons.home_outlined, 'home'),
            _tab(1, Icons.assignment_turned_in_outlined, 'mission'),
            _tab(2, Icons.person_outline, 'profile'),
          ]),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final color = _index == index ? AppColors.primary : AppColors.textGrey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 15, color: color)),
        ]),
      ),
    );
  }
}
