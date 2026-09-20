import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/aquarium_background.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

class GoalConfirmScreen extends StatefulWidget {
  final String userName;
  final GoalDraft draft;
  const GoalConfirmScreen({super.key, required this.userName, required this.draft});

  @override
  State<GoalConfirmScreen> createState() => _GoalConfirmScreenState();
}

enum _Status { loading, success, error }

class _GoalConfirmScreenState extends State<GoalConfirmScreen> {
  final GoalRepository _repo = MockGoalRepository();
  _Status _status = _Status.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);
    try {
      await _repo.generateGoal(widget.draft);
      if (mounted) setState(() => _status = _Status.success);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 393,
          height: 852,
          child: AquariumBackground(child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    if (_status == _Status.loading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          SizedBox(height: 12),
          Text('AI가 맞춤 목표를 생성하고 있어요', style: TextStyle(fontSize: 15, color: AppColors.primary)),
        ]),
      );
    }
    if (_status == _Status.error) {
      return Center(child: SizedBox(width: 200, child: PrimaryButton(label: '다시 시도', onPressed: _load)));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 393),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 98, 40, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.userName}님을 위한 맞춤 목표를 알려드릴게요', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            const Text('미션을 확인한 후, 맞춤 미션이 좋다면\n목표 생성하기 버튼을 눌러주세요', style: TextStyle(fontSize: 18, height: 1.4, color: AppColors.primary)),
            const SizedBox(height: 24),
            const Divider(color: AppColors.border),
            const SizedBox(height: 18),
            const _GoalStep(step: 'STEP 1', title: '제출 일주일 전 시작', description: '마감 일주일 전에 시작하도록 알려드려요'),
            const SizedBox(height: 16),
            const _GoalStep(step: 'STEP 2', title: '매일 오후 6시 알림', description: '매일 오후 6시에 알려드려요'),
            const SizedBox(height: 50),
            PrimaryButton(
              label: '목표 생성하기',
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MainShell(userName: widget.userName)),
                (_) => false,
              ),
            ),
            const SizedBox(height: 12),
            Center(child: TextButton(onPressed: _load, child: const Text('목표 다시 생성하기', style: TextStyle(fontSize: 14, color: AppColors.textGrey)))),
          ]),
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  const _GoalStep({required this.step, required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(step, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(fontSize: 15, color: AppColors.textGrey)),
      ]);
}
