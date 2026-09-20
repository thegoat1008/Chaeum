import 'package:flutter/material.dart';
import '../widgets/ime_text_field.dart';

import '../models/mission.dart';
import '../state/session.dart';
import '../theme/app_colors.dart';
import '../widgets/aquarium_background.dart';
import '../widgets/loading_view.dart';
import '../widgets/mission_header.dart';
import '../widgets/primary_button.dart';

/// 미션 수행 풀스크린 흐름.
///
/// 작성 -> AI가 완료 조건 분석 -> 난이도·이유 피드백 -> 완료 안내까지를
/// 하나의 라우트에서 단계만 바꿔 가며 보여 줍니다.
class MissionFlowScreen extends StatefulWidget {
  /// 이 화면은 라우트로 푸시되어 [SessionScope] 바깥에 놓이므로 컨트롤러를 직접 받습니다.
  final SessionController session;

  const MissionFlowScreen({super.key, required this.session});

  @override
  State<MissionFlowScreen> createState() => _MissionFlowScreenState();
}

class _MissionFlowScreenState extends State<MissionFlowScreen> {
  final _answerController = TextEditingController();
  MissionDifficulty? _difficulty;
  final Set<String> _reasons = {};

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer(SessionController session) {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;
    session.submitAnswer(answer);
  }

  void _completeFeedback(SessionController session) {
    final difficulty = _difficulty;
    if (difficulty == null) return;
    session.submitFeedback(
      difficulty: difficulty,
      // 이유 칩은 "어려웠어요"를 고른 경우에만 의미가 있습니다.
      reasons: difficulty == MissionDifficulty.hard ? _reasons.toList() : const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final mission = session.mission;
            if (mission == null) {
              return const AquariumLoadingView(message: '미션을 불러오고 있어요');
            }
            return _body(session, mission);
          },
        ),
      ),
    );
  }

  Widget _body(SessionController session, Mission mission) {
    switch (session.stage) {
      case MissionStage.evaluating:
        return const AquariumLoadingView(message: 'AI가 완료 조건을 분석하고 있어요');
      case MissionStage.complete:
        return _CompleteView(userName: session.userName, onDone: () => Navigator.of(context).pop());
      case MissionStage.error:
        return AquariumErrorView(
          message: session.error ?? '문제가 생겼어요.',
          isSafetyBlock: session.errorIsSafetyBlock,
          onRetry: session.errorIsSafetyBlock ? null : session.backToOverview,
        );
      case MissionStage.feedback:
        return _feedbackView(session, mission);
      case MissionStage.loading:
      case MissionStage.overview:
      case MissionStage.writing:
        return _writingView(session, mission);
    }
  }

  Widget _writingView(SessionController session, Mission mission) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 393),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 18, 40, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MissionAppBar(title: '오늘의 미션', onBack: () => Navigator.of(context).pop()),
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
              const SizedBox(height: 30),
              ImeTextField(
                controller: _answerController,
                minLines: 10,
                maxLines: 14,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '완료한 과제 내용을 작성해주세요',
                  hintStyle: const TextStyle(fontSize: 16, color: AppColors.textGrey),
                  contentPadding: const EdgeInsets.all(20),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                label: '제출하기',
                onPressed: _answerController.text.trim().isEmpty
                    ? null
                    : () => _submitAnswer(session),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackView(SessionController session, Mission mission) {
    final evaluation = session.evaluation;
    final showReasons = _difficulty == MissionDifficulty.hard;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 393),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 18, 40, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MissionAppBar(
                title: '미션 통계',
                onBack: () {
                  session.backToOverview();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 30),
              MissionHeader(mission: mission),
              if (evaluation != null) ...[
                _EvaluationSummary(evaluation: evaluation),
                const SizedBox(height: 30),
              ],
              const SectionTitle('오늘 미션 난이도는 어땠나요?'),
              const SizedBox(height: 8),
              const Text(
                '추후 미션 난이도 조정에 반영돼요!',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              const SizedBox(height: 40),
              for (final difficulty in MissionDifficulty.values) ...[
                _DifficultyButton(
                  difficulty: difficulty,
                  selected: _difficulty == difficulty,
                  onTap: () => setState(() {
                    _difficulty = difficulty;
                    if (difficulty != MissionDifficulty.hard) _reasons.clear();
                  }),
                ),
                if (difficulty != MissionDifficulty.values.last) const SizedBox(height: 20),
              ],
              if (showReasons) ...[
                const SizedBox(height: 30),
                const Text(
                  '어려웠다면 이유를 알려주세요',
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final reason in missionDifficultyReasons)
                      _ReasonChip(
                        label: reason,
                        selected: _reasons.contains(reason),
                        onTap: () => setState(() {
                          if (!_reasons.remove(reason)) _reasons.add(reason);
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 30),
              PrimaryButton(
                label: '완료하기',
                onPressed: _difficulty == null ? null : () => _completeFeedback(session),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI가 판정한 완료 조건 결과. 기능 정의서의 "판단 근거" 표시에 해당합니다.
class _EvaluationSummary extends StatelessWidget {
  final MissionEvaluation evaluation;

  const _EvaluationSummary({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x145B6790),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                evaluation.isComplete ? Icons.check_circle : Icons.timelapse,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '완료 조건 ${evaluation.metCount}/${evaluation.totalCount} 충족',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in evaluation.criteria)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.met ? Icons.check : Icons.remove,
                    size: 16,
                    color: item.met ? AppColors.primary : AppColors.textGrey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: item.met ? Colors.black : AppColors.textGrey,
                          ),
                        ),
                        if (item.comment.isNotEmpty)
                          Text(
                            item.comment,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.textGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (evaluation.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              evaluation.summary,
              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSub),
            ),
          ],
        ],
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final MissionDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 51,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Text(difficulty.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              difficulty.label,
              style: TextStyle(fontSize: 16, color: selected ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

/// 복수 선택 가능한 이유 칩.
class _ReasonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

class _CompleteView extends StatelessWidget {
  final String userName;
  final VoidCallback onDone;

  const _CompleteView({required this.userName, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return AquariumBackground(
      child: Center(
        child: SizedBox(
          width: 230,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 40, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                '피드백을 통해 $userName님께 더 좋은\n미션을 제공해 드릴게요',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(label: '홈으로 돌아가기', onPressed: onDone),
            ],
          ),
        ),
      ),
    );
  }
}
