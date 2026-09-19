/// 사용자가 직접 입력한 목표 (서버로 보낼 값). API 명세 확정 전 임시 모델.
class GoalDraft {
  final String weakness; // 나의 단점
  final String desiredChange; // 원하는 변화
  final String period; // 도전 기간

  const GoalDraft({
    required this.weakness,
    required this.desiredChange,
    required this.period,
  });
}

/// 에이전트가 만들어 준 맞춤 목표 (서버에서 받을 값). 임시 모델.
class GeneratedGoal {
  final String title;
  final String description;

  const GeneratedGoal({required this.title, required this.description});
}
