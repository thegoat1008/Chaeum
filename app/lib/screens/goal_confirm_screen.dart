import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../repositories/api_client.dart';
import '../repositories/goal_repository.dart';
import '../state/session.dart';
import '../theme/app_colors.dart';
import '../widgets/aquarium_background.dart';
import '../widgets/loading_view.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

/// 화면 4. 맞춤 목표와 "언제 알려 줄지"를 보여 주고 사용자 승인을 받습니다.
/// 승인 전에는 어떤 알림도 예약되지 않습니다.
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
  GoalPlan? _plan;
  String? _error;
  bool _safetyBlocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = _Status.loading;
      _error = null;
      _safetyBlocked = false;
    });
    try {
      final plan = await _repo.generateGoal(widget.draft);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _status = _Status.success;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _safetyBlocked = error.isSafetyBlock;
        _status = _Status.error;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _status = _Status.error;
      });
    }
  }

  /// 승인. 여기서부터 Agent Loop가 이 목표를 맡습니다.
  void _approve() {
    final plan = _plan;
    if (plan == null) return;
    final session = SessionController(
      userName: widget.userName,
      draft: widget.draft,
      plan: plan,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => MainShell(session: session)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(width: 393, height: 852, child: _body()),
      ),
    );
  }

  Widget _body() {
    switch (_status) {
      case _Status.loading:
        return const AquariumLoadingView(message: '맞춤 목표를 생성하고 있어요');
      case _Status.error:
        return AquariumErrorView(
          message: _error ?? '목표를 만들지 못했어요.',
          isSafetyBlock: _safetyBlocked,
          onRetry: _load,
        );
      case _Status.success:
        return _plan == null ? const SizedBox.shrink() : _planView(_plan!);
    }
  }

  Widget _planView(GoalPlan plan) {
    return AquariumBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 98, 40, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.userName}님을 위한 맞춤 목표를 알려드릴게요',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.4),
            ),
            const SizedBox(height: 6),
            const Text(
              '미션을 확인한 후, 맞춤 미션이 좋다면\n확인버튼을 눌러주세요',
              style: TextStyle(fontSize: 18, height: 1.4, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 22),
            for (var i = 0; i < plan.steps.length; i += 1) ...[
              _PlanStep(step: 'STEP ${i + 1}', item: plan.steps[i]),
              if (i != plan.steps.length - 1) const SizedBox(height: 20),
            ],
            const SizedBox(height: 50),
            PrimaryButton(label: '목표 생성하기', onPressed: _approve),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _load,
                child: const Text(
                  '목표 다시 생성하기',
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  final String step;
  final GoalStep item;

  const _PlanStep({required this.step, required this.item});

  @override
  Widget build(BuildContext context) => Column(
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
          const SizedBox(height: 10),
          Text(item.title, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textGrey),
          ),
        ],
      );
}
