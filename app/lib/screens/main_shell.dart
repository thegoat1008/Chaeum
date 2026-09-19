import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

/// 하단 탭(home / mission / profile) 틀. Figma: iPhone 16 - 4 + Frame 33
/// mission, profile 화면은 Figma가 오면 채웁니다.
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
      const Center(child: Text('mission (준비 중)')),
      const Center(child: Text('profile (준비 중)')),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _tab(0, Icons.home_outlined, 'home'),
              _tab(1, Icons.assignment_turned_in_outlined, 'mission'),
              _tab(2, Icons.person_outline, 'profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label) {
    final selected = _index == i;
    final color = selected ? AppColors.primary : AppColors.textGrey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
