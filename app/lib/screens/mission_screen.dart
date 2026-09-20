import 'package:flutter/material.dart';

import '../models/mission.dart';
import '../state/session.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_view.dart';
import '../widgets/mission_header.dart';
import '../widgets/primary_button.dart';
import 'mission_flow_screen.dart';
import 'splash_screen.dart' show ChaeumLogo;

/// 미션 탭. 오늘의 미션 개요를 보여 주고, 시작하면 풀스크린 수행 흐름으로 넘깁니다.
class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  @override
  void initState() {
    super.initState();
    // 탭이 처음 만들어질 때 오늘의 미션을 준비합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SessionScope.of(context).ensureMission();
    });
  }

  Future<void> _start() async {
    final session = SessionScope.of(context);
    session.startWriting();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MissionFlowScreen(session: session)),
    );
    // 흐름을 끝내고 돌아오면 다음 미션을 준비합니다.
    if (!mounted) return;
    if (session.stage == MissionStage.complete) await session.startNextMission();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final mission = session.mission;

    if (session.paused) {
      return const _CenteredNotice(
        icon: Icons.pause_circle_outline,
        message: '목표를 일시정지했어요.\n프로필 탭에서 다시 시작할 수 있어요.',
      );
    }
    if (session.stage == MissionStage.error) {
      return AquariumErrorView(
        message: session.error ?? '미션을 만들지 못했어요.',
        isSafetyBlock: session.errorIsSafetyBlock,
        onRetry: session.loadMission,
      );
    }
    if (mission == null) {
      return const AquariumLoadingView(message: '오늘의 미션을 만들고 있어요');
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 393),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 18, 40, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ChaeumLogo(size: 20, showTagline: false),
              const SizedBox(height: 30),
              MissionHeader(mission: mission),
              const SectionTitle('목표'),
              const SizedBox(height: 10),
              MissionObjective(
                objective: mission.objective,
                highlight: mission.objectiveHighlight,
              ),
              const SizedBox(height: 34),
              CompletionCriteria(criteria: mission.completionCriteria),
              if (mission.hints.isNotEmpty) ...[
                const SizedBox(height: 34),
                const SectionTitle('Hint!'),
                const SizedBox(height: 4),
                const Text(
                  '미션이 어렵다면 이 글을 확인해주세요',
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < mission.hints.length; i += 1)
                  _HintStep(step: 'STEP ${i + 1}', hint: mission.hints[i]),
              ],
              const SizedBox(height: 20),
              PrimaryButton(label: '시작하기', onPressed: _start),
              const SizedBox(height: 10),
              _FooterActions(
                onSkip: session.skipMission,
                onRegenerate: session.regenerateMission,
              ),
              if (mission.decisionReason.isNotEmpty) ...[
                const SizedBox(height: 20),
                _DecisionNote(reason: mission.decisionReason),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HintStep extends StatelessWidget {
  final String step;
  final MissionHint hint;

  const _HintStep({required this.step, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(hint.title, style: const TextStyle(fontSize: 16, height: 1.4)),
          if (hint.subtext.isNotEmpty)
            Text(
              '→ ${hint.subtext}',
              style: const TextStyle(fontSize: 15, color: AppColors.textGrey),
            ),
        ],
      ),
    );
  }
}

/// "미션 건너뛰기 | 미션 다시 생성하기". 둘 다 Rule Engine에 근거를 남깁니다.
class _FooterActions extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onRegenerate;

  const _FooterActions({required this.onSkip, required this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, color: AppColors.textGrey);
    // 좁은 화면에서도 한 줄을 유지해야 해서 넘칠 때만 줄여 그립니다.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(onTap: onSkip, child: const Text('미션 건너뛰기', style: style)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('|', style: style),
            ),
            InkWell(onTap: onRegenerate, child: const Text('미션 다시 생성하기', style: style)),
          ],
        ),
      ),
    );
  }
}

/// 기능 정의서의 "판단 근거". 왜 오늘 이 미션인지 사용자에게 그대로 보여 줍니다.
class _DecisionNote extends StatelessWidget {
  final String reason;

  const _DecisionNote({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x145B6790),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이 미션을 고른 이유',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(reason, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSub)),
        ],
      ),
    );
  }
}

class _CenteredNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const _CenteredNotice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textGrey),
            ),
          ],
        ),
      );
}
