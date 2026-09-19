import '../models/goal.dart';

/// 화면은 이 인터페이스만 바라봅니다.
/// 나중에 실제 API가 정해지면 ApiGoalRepository를 만들어 교체하면 됩니다.
abstract class GoalRepository {
  Future<GeneratedGoal> generateGoal(GoalDraft draft);
}

/// 가짜 데이터 버전 (API 연결 전까지 사용)
class MockGoalRepository implements GoalRepository {
  @override
  Future<GeneratedGoal> generateGoal(GoalDraft draft) async {
    await Future.delayed(const Duration(seconds: 2));
    return GeneratedGoal(
      title: draft.desiredChange,
      description: '${draft.period} 동안 "${draft.weakness}"을(를) 바꾸는 연습을 해요.',
    );
  }
}
