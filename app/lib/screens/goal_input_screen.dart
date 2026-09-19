import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/aquarium_background.dart';
import '../widgets/primary_button.dart';
import 'goal_confirm_screen.dart';

/// Figma: iPhone 16 - 5, 6, 7, 8
/// 한 화면에서 단계(step)만 바뀌며 입력창이 하나씩 늘어납니다.
/// step 0: 단점 / 1: 원하는 변화 / 2: 도전 기간 / 3: 목표 생성하기 버튼
/// (키보드 완료 키로 다음 단계로 넘어가는 방식은 추측입니다. Figma 확인 필요)
class GoalInputScreen extends StatefulWidget {
  final String userName;
  const GoalInputScreen({super.key, required this.userName});

  @override
  State<GoalInputScreen> createState() => _GoalInputScreenState();
}

class _GoalInputScreenState extends State<GoalInputScreen> {
  final _weakness = TextEditingController();
  final _change = TextEditingController();
  final _period = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _weakness.dispose();
    _change.dispose();
    _period.dispose();
    super.dispose();
  }

  void _advance(TextEditingController c) {
    if (c.text.trim().isEmpty) return; // 빈 칸 검증
    setState(() => _step++);
  }

  void _submit() {
    final draft = GoalDraft(
      weakness: _weakness.text.trim(),
      desiredChange: _change.text.trim(),
      period: _period.text.trim(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GoalConfirmScreen(userName: widget.userName, draft: draft),
      ),
    );
  }

  Widget _header() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('안녕하세요, ${widget.userName}님!',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('지금 당장 바꾸고 싶은 나의 단점은\n무엇인가요?',
                style: TextStyle(fontSize: 11, color: AppColors.textSub)),
          ],
        );
      case 1:
        return const Text('원하는 변화는 무엇인가요?',
            style: TextStyle(fontSize: 11, color: AppColors.textSub));
      case 2:
        return const Text('얼마나 진행하고 싶나요?',
            style: TextStyle(fontSize: 11, color: AppColors.textSub));
      default:
        return const Text('결정 되었다면 하단 버튼을 눌러주세요!',
            style: TextStyle(fontSize: 11, color: AppColors.textSub));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이미 입력한 칸은 라벨 없이 위에 쌓이고, 현재 단계 칸에만 라벨이 붙습니다.
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AquariumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 20),
                AppTextField(
                  label: _step == 0 ? '나의 단점 적기' : null,
                  hint: '자신만의 단점을 작성해주세요',
                  controller: _weakness,
                  autofocus: true,
                  readOnly: _step > 0,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _advance(_weakness),
                ),
                if (_step >= 1) ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    label: _step == 1 ? '원하는 변화' : null,
                    hint: '원하는 변화를 작성해주세요',
                    controller: _change,
                    autofocus: _step == 1,
                    readOnly: _step > 1,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _advance(_change),
                  ),
                ],
                if (_step >= 2) ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    label: _step == 2 ? '도전 기간' : null,
                    hint: '도전 기간을 작성해주세요',
                    controller: _period,
                    autofocus: _step == 2,
                    readOnly: _step > 2,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _advance(_period),
                  ),
                ],
                if (_step >= 3) ...[
                  const SizedBox(height: 28),
                  PrimaryButton(label: '목표 생성하기', onPressed: _submit),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
