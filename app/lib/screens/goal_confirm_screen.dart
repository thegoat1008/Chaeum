import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/aquarium_background.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

/// Figma: iPhone 16 - 9 (로딩) → 10 (맞춤 목표 확인)
/// 10번 Figma는 문구만 있어서, 목표 표시와 "확인" 버튼은 임시 배치입니다.
class GoalConfirmScreen extends StatefulWidget {
  final String userName;
  final GoalDraft draft;
  const GoalConfirmScreen(
      {super.key, required this.userName, required this.draft});

  @override
  State<GoalConfirmScreen> createState() => _GoalConfirmScreenState();
}

enum _Status { loading, success, error }

class _GoalConfirmScreenState extends State<GoalConfirmScreen> {
  // 실제 API가 정해지면 여기만 교체
  final GoalRepository _repo = MockGoalRepository();
  _Status _status = _Status.loading;
  GeneratedGoal? _goal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);
    try {
      final goal = await _repo.generateGoal(widget.draft);
      if (!mounted) return;
      setState(() {
        _goal = goal;
        _status = _Status.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _Status.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AquariumBackground(
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _Status.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
              SizedBox(height: 12),
              Text('맞춤 목표를 생성하고 있어요',
                  style: TextStyle(fontSize: 10, color: AppColors.textSub)),
            ],
          ),
        );
      case _Status.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('목표를 만들지 못했어요',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: PrimaryButton(label: '다시 시도', onPressed: _load),
              ),
            ],
          ),
        );
      case _Status.success:
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.userName}님을 위한 맞춤 목표를 알려드릴게요',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('미션을 확인한 후, 맞춤 미션이 좋다면\n확인버튼을 눌러주세요',
                  style: TextStyle(fontSize: 11, color: AppColors.textSub)),
              const SizedBox(height: 20),
              Text(_goal!.title,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(_goal!.description,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textGrey)),
              const SizedBox(height: 24),
              PrimaryButton(
                label: '확인',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => MainShell(userName: widget.userName)),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
    }
  }
}
