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
  final GoalRepository _repo = GoalRepository.configured();
  _Status _status = _Status.loading;
  GeneratedGoal? _goal;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);
    try {
      final goal = await _repo.generateGoal(widget.draft);
      if (mounted) setState(() { _goal = goal; _status = _Status.success; });
    } catch (error) {
      if (mounted) setState(() { _error = error.toString(); _status = _Status.error; });
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
      return Center(child: SizedBox(width: 260, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error ?? '목표를 만들지 못했어요.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        PrimaryButton(label: '다시 시도', onPressed: _load),
      ])));
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
            Text(_goal!.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_goal!.description, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textGrey)),
            const SizedBox(height: 22),
            _GoalStep(step: 'STEP 1', title: _goal!.steps.first.title, description: _goal!.steps.first.description),
            const SizedBox(height: 16),
            _GoalStep(step: 'STEP 2', title: _goal!.steps.length > 1 ? _goal!.steps[1].title : '매일 기록하기', description: _goal!.steps.length > 1 ? _goal!.steps[1].description : '진행 상황을 짧게 기록해요.'),
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
