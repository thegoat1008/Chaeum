import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../theme/app_colors.dart';
import '../widgets/aquarium_background.dart';
import '../widgets/primary_button.dart';
import 'goal_confirm_screen.dart';

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

  void _next(TextEditingController controller) {
    if (controller.text.trim().isNotEmpty) setState(() => _step++);
  }

  void _submit() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GoalConfirmScreen(
        userName: widget.userName,
        draft: GoalDraft(
          weakness: _weakness.text.trim(),
          desiredChange: _change.text.trim(),
          period: _period.text.trim(),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: SizedBox(
          width: 393,
          height: 852,
          child: AquariumBackground(
            child: Stack(children: [
              Positioned(
                left: 40,
                top: 98,
                right: 40,
                child: Text(
                  _step == 0 ? '안녕하세요, ${widget.userName}님!' : _step == 1 ? '원하는 변화는 무엇인가요?' : _step == 2 ? '얼마나 진행하고 싶나요?' : '결정 되었다면 하단 버튼을 눌러주세요!',
                  style: TextStyle(fontSize: _step == 0 ? 20 : 18, fontWeight: FontWeight.w500, color: _step == 0 ? Colors.black : AppColors.primary),
                ),
              ),
              if (_step == 0)
                const Positioned(
                  left: 40,
                  top: 127,
                  width: 245,
                  child: Text('지금 당장 바꾸고 싶은 나의 단점은\n무엇인가요?', style: TextStyle(fontSize: 18, height: 1.4, color: AppColors.primary)),
                ),
              if (_step >= 1) Positioned(left: 40, top: 149, width: 313, child: _savedField(_weakness)),
              if (_step >= 2) Positioned(left: 40, top: 222, width: 313, child: _savedField(_change)),
              if (_step >= 3) Positioned(left: 40, top: 295, width: 313, child: _savedField(_period)),
              if (_step == 0)
                Positioned(left: 40, top: 209, width: 313, child: _inputBlock('나의 단점 적기', '자신만의 단점을 작성해주세요', _weakness, TextInputAction.next)),
              if (_step == 1)
                Positioned(left: 40, top: 222, width: 313, child: _inputBlock('원하는 변화', '원하는 변화를 작성해주세요', _change, TextInputAction.next)),
              if (_step == 2)
                Positioned(left: 40, top: 295, width: 313, child: _inputBlock('도전 기간', '도전 기간을 작성해주세요', _period, TextInputAction.done)),
              if (_step == 3)
                Positioned(left: 40, top: 428, width: 313, child: PrimaryButton(label: '목표 생성하기', onPressed: _submit)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _savedField(TextEditingController controller) => Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Text(controller.text, style: const TextStyle(fontSize: 16)),
      );

  Widget _inputBlock(String label, String hint, TextEditingController controller, TextInputAction action) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      SizedBox(
        height: 54,
        child: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: action,
          onSubmitted: (_) => _next(controller),
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 16, color: AppColors.textGrey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ),
    ]);
  }
}
