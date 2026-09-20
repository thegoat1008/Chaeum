import 'package:flutter/material.dart';

import '../state/session.dart';
import '../theme/app_colors.dart';
import 'splash_screen.dart' show ChaeumLogo;

/// 프로필 탭 = 신뢰·통제 센터 + Agent 활동 이력.
///
/// 기능 정의서의 "사용자가 언제든 목표·기억·알림을 수정·삭제·중지할 수 있게 한다"와
/// "에이전트가 무엇을 왜 했는지 시간순으로 확인한다"를 한 화면에서 처리합니다.
/// (피그마에 이 화면 시안이 없어 기존 디자인 토큰으로 맞춰 구성했습니다.)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 393),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 18, 40, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ChaeumLogo(size: 20, showTagline: false),
              const SizedBox(height: 20),
              Text(
                '${session.userName}님의 목표',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _GoalCard(session: session),
              const SizedBox(height: 30),
              const _Heading('예정된 알림'),
              const SizedBox(height: 12),
              for (final step in session.plan.steps)
                _Row(
                  icon: step.triggerType == 'deadline'
                      ? Icons.event_outlined
                      : Icons.notifications_none,
                  title: step.title,
                  subtitle: step.description,
                ),
              const SizedBox(height: 30),
              const _Heading('통제'),
              const SizedBox(height: 4),
              const Text(
                '일시정지하면 예정된 알림과 미션 생성이 즉시 멈춰요',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: session.paused,
                onChanged: session.setPaused,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: const Text('목표 일시정지', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              const _Heading('Agent 활동 이력'),
              const SizedBox(height: 4),
              const Text(
                '에이전트가 언제 무엇을 왜 했는지 그대로 기록해요',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 12),
              if (session.events.isEmpty)
                const Text(
                  '아직 기록이 없어요.',
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                )
              else
                for (final event in session.events) _TimelineTile(event: event),
              const SizedBox(height: 30),
              const _SafetyNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SessionController session;

  const _GoalCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.plan.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
          ),
          if (session.plan.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              session.plan.description,
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textGrey),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag('DAY ${session.dayIndex}'),
              _Tag('D-${session.remainingDays}'),
              _Tag('${session.plan.durationDays}일 도전'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          // 사용자가 직접 입력한 원문. AI가 바꾸지 않았다는 것을 그대로 보여 줍니다.
          _Field(label: '내가 적은 단점', value: session.draft.weakness),
          const SizedBox(height: 10),
          _Field(label: '원하는 변화', value: session.draft.desiredChange),
          const SizedBox(height: 10),
          _Field(label: '도전 기간', value: session.draft.period),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      );
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x145B6790),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
      );
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500));
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Row({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TimelineTile extends StatelessWidget {
  final AgentEvent event;

  const _TimelineTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final time = '${event.at.hour.toString().padLeft(2, '0')}:'
        '${event.at.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  event.detail,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x145B6790),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          '채움은 정신건강이나 성격을 진단하지 않아요. 진단이 필요하다면 자격을 갖춘 '
          '전문가와 상담해 주세요.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSub),
        ),
      );
}
