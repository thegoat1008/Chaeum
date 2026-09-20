import 'package:flutter/material.dart';

import '../models/mission.dart';
import '../theme/app_colors.dart';
import 'sea_creature.dart';

/// "DAY 18 / 프로젝트 브레인스토밍하기 🦀 / 구분선" 블록.
/// 미션 탭·작성·통계 화면이 모두 같은 머리글을 씁니다.
class MissionHeader extends StatelessWidget {
  final Mission mission;

  const MissionHeader({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAY ${mission.dayIndex}',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                mission.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            SeaCreatureIcon.fromEmoji(mission.emoji, size: 38),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// 뒤로가기 + 가운데 제목. 풀스크린으로 열리는 미션 화면들의 상단바입니다.
class MissionAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const MissionAppBar({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: onBack == null
              ? null
              : InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(Icons.chevron_left, size: 30),
                ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 30),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500));
}

/// 완료 조건 목록. 조건 개수를 문구에 그대로 반영합니다.
class CompletionCriteria extends StatelessWidget {
  final List<String> criteria;

  const CompletionCriteria({super.key, required this.criteria});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('완료 조건'),
        const SizedBox(height: 4),
        Text(
          '아래 ${criteria.length}가지를 작성하면 미션이 완료돼요',
          style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        const SizedBox(height: 16),
        for (final item in criteria)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 16, height: 1.4))),
              ],
            ),
          ),
      ],
    );
  }
}

/// 목표 문장. Gemini가 지정한 핵심 어구만 파란색으로 강조합니다.
class MissionObjective extends StatelessWidget {
  final String objective;
  final String highlight;

  const MissionObjective({super.key, required this.objective, required this.highlight});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 16, height: 1.4);
    final start = highlight.isEmpty ? -1 : objective.indexOf(highlight);
    if (start < 0) return Text(objective, style: style);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: objective.substring(0, start)),
          TextSpan(
            text: highlight,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
          TextSpan(text: objective.substring(start + highlight.length)),
        ],
      ),
      style: style,
    );
  }
}
