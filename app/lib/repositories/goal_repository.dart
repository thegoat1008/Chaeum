import '../models/goal.dart';

abstract class GoalRepository {
  Future<GeneratedGoal> generateGoal(GoalDraft draft);
}

class MockGoalRepository implements GoalRepository {
  @override
  Future<GeneratedGoal> generateGoal(GoalDraft draft) async {
    await Future.delayed(const Duration(seconds: 2));
    return GeneratedGoal(
      title: draft.desiredChange,
      description: '${draft.period} 동안 “${draft.weakness}”을 바꾸는 연습을 해요.',
    );
  }
}
