import 'package:flutter/material.dart';

import '../state/session.dart';
import '../theme/app_colors.dart';
import '../widgets/sea_creature.dart';
import 'splash_screen.dart' show ChaeumLogo;

/// 홈 / 어항. 현재 목표 진행 상태와 다음 행동을 한눈에 보여 줍니다.
class HomeScreen extends StatelessWidget {
  /// 미션 탭으로 이동. 카드를 누르면 오늘의 미션으로 바로 넘어갑니다.
  final VoidCallback onOpenMission;

  const HomeScreen({super.key, required this.onOpenMission});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 393),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 18, 40, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ChaeumLogo(size: 20, showTagline: false),
              const SizedBox(height: 20),
              Text(
                '안녕하세요, ${session.userName}님!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),
              Text(
                session.paused ? '목표를 잠시 멈춰 뒀어요.' : '오늘도 성장해 볼까요?',
                style: const TextStyle(fontSize: 18, color: AppColors.textGrey),
              ),
              const SizedBox(height: 30),
              _TodayMissionCard(
                title: session.isTodayDone ? '오늘의 미션 완료!' : '오늘의 미션 하러가기',
                remainingDays: session.remainingDays,
                onTap: onOpenMission,
              ),
              const SizedBox(height: 24),
              _GoalSummary(goalTitle: session.plan.title),
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/aquarium.png',
                  width: 257,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  '매일 미션을 진행하며 어항을 꾸며보세요!',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayMissionCard extends StatelessWidget {
  final String title;
  final int remainingDays;
  final VoidCallback onTap;

  const _TodayMissionCard({
    required this.title,
    required this.remainingDays,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 138,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 30, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.badge,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'D-$remainingDays',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SeaCreatureIcon(creature: SeaCreature.jellyfish, size: 58),
          ],
        ),
      ),
    );
  }
}

/// 지금 맡긴 목표가 무엇인지 홈에서 바로 확인합니다.
class _GoalSummary extends StatelessWidget {
  final String goalTitle;

  const _GoalSummary({required this.goalTitle});

  @override
  Widget build(BuildContext context) {
    if (goalTitle.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.flag_outlined, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            goalTitle,
            style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSub),
          ),
        ),
      ],
    );
  }
}
