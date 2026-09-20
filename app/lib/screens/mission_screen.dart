import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/aquarium_background.dart';
import '../widgets/primary_button.dart';

enum MissionStage { overview, writing, feedback, complete }

class MissionScreen extends StatefulWidget {
  final String userName;
  const MissionScreen({super.key, required this.userName});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  final _answerController = TextEditingController();
  MissionStage _stage = MissionStage.overview;
  String? _difficulty;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == MissionStage.complete) return _completeView();
    return Center(
      child: SizedBox(
        width: 393,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 18, 40, 34),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader(_stage == MissionStage.feedback ? '미션 통계' : '오늘의 미션'),
            const SizedBox(height: 30),
            const Text('DAY 18', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 2),
            const Row(children: [
              Expanded(child: Text('프로젝트 브레인스토밍하기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500))),
              Text('🦀', style: TextStyle(fontSize: 34)),
            ]),
            const SizedBox(height: 18),
            const Divider(color: AppColors.border),
            const SizedBox(height: 20),
            if (_stage == MissionStage.overview) _overview(),
            if (_stage == MissionStage.writing) _writing(),
            if (_stage == MissionStage.feedback) _feedback(),
          ]),
        ),
      ),
    );
  }

  Widget _pageHeader(String title) => Row(children: [
        const Icon(Icons.chevron_left, size: 30),
        const Spacer(),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        const Spacer(),
        const SizedBox(width: 30),
      ]);

  Widget _overview() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('목표'),
        const SizedBox(height: 10),
        const Text.rich(
          TextSpan(children: [
            TextSpan(text: '프로젝트의 방향을 정하기 위해 '),
            TextSpan(text: '떠오르는 아이디어', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
            TextSpan(text: '를 자유롭게 정리해보세요'),
          ]),
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 34),
        _conditions(),
        const SizedBox(height: 34),
        const _SectionTitle('Hint!'),
        const SizedBox(height: 4),
        const Text('미션이 어렵다면 이 글을 확인해주세요', style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
        const SizedBox(height: 12),
        const _HintStep('STEP 1', '떠오르는 아이디어를 자유롭게 적어보세요', '→ 완벽한 아이디어가 아니어도 괜찮아요'),
        const _HintStep('STEP 2', '각 아이디어가 어떤 문제를 해결하는지\n한 줄로 적어보세요', null),
        const _HintStep('STEP 3', '가장 관심이 가는 아이디어 하나를 골라보세요', null),
        const SizedBox(height: 20),
        PrimaryButton(label: '시작하기', onPressed: () => setState(() => _stage = MissionStage.writing)),
        const SizedBox(height: 10),
        const Center(child: Text('미션 건너뛰기   |   미션 다시 생성하기', style: TextStyle(fontSize: 13, color: AppColors.textGrey))),
      ]);

  Widget _writing() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _conditions(),
        const SizedBox(height: 30),
        TextField(
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
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 30),
        PrimaryButton(
          label: '제출하기',
          onPressed: _answerController.text.trim().isEmpty ? null : () => setState(() => _stage = MissionStage.feedback),
        ),
      ]);

  Widget _feedback() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('오늘 미션 난이도는 어땠나요?'),
        const SizedBox(height: 8),
        const Text('추후 미션 난이도 조정에 반영돼요!', style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
        const SizedBox(height: 40),
        _difficultyButton('😢', '어려웠어요'),
        const SizedBox(height: 20),
        _difficultyButton('😌', '적당했어요'),
        const SizedBox(height: 20),
        _difficultyButton('😊', '쉬웠어요'),
        const SizedBox(height: 30),
        PrimaryButton(
          label: '완료하기',
          onPressed: _difficulty == null ? null : () => setState(() => _stage = MissionStage.complete),
        ),
      ]);

  Widget _difficultyButton(String emoji, String label) {
    final selected = _difficulty == label;
    return InkWell(
      onTap: () => setState(() => _difficulty = label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 51,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 16, color: selected ? Colors.white : Colors.black)),
        ]),
      ),
    );
  }

  Widget _completeView() => Center(
        child: SizedBox(
          width: 393,
          height: 852,
          child: AquariumBackground(
            child: Center(
              child: SizedBox(
                width: 220,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline, size: 40, color: AppColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    '피드백을 통해 ${widget.userName}님께 더 좋은 미션을 제공해드릴게요',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  TextButton(onPressed: () => setState(() => _stage = MissionStage.overview), child: const Text('미션으로 돌아가기')),
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _conditions() => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionTitle('완료 조건'),
        SizedBox(height: 4),
        Text('아래 3가지를 작성하면 미션이 완료돼요', style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
        SizedBox(height: 16),
        _Bullet('프로젝트 아이디어 3개 이상 적기'),
        _Bullet('각 아이디어에 대해 한 줄 설명 작성하기'),
        _Bullet('가장 해보고 싶은 아이디어 1개 선택하기'),
      ]);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500));
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('•  ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4))),
        ]),
      );
}

class _HintStep extends StatelessWidget {
  final String step;
  final String text;
  final String? subtext;
  const _HintStep(this.step, this.text, this.subtext);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
          if (subtext != null) Text(subtext!, style: const TextStyle(fontSize: 15, color: AppColors.textGrey)),
        ]),
      );
}
