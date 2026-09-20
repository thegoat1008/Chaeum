import '../models/goal.dart';
import 'api_client.dart';

/// 목표 구체화(화면 3) + 계획·권한 승인(화면 4)에 필요한 데이터를 만듭니다.
abstract class GoalRepository {
  Future<GoalPlan> generateGoal(GoalDraft draft);

  /// 빌드 타임에 Supabase 설정이 있으면 실제 Gemini 호출, 없으면 Mock.
  factory GoalRepository.configured() {
    final client = ApiClient.fromEnvironment();
    return client == null ? MockGoalRepository() : GeminiGoalRepository(client);
  }
}

class GeminiGoalRepository implements GoalRepository {
  final ApiClient _api;

  GeminiGoalRepository(this._api);

  @override
  Future<GoalPlan> generateGoal(GoalDraft draft) async {
    final payload = await _api.invoke('generate-mission', draft.toJson());
    final data = payload['data'];
    if (data is! Map<String, dynamic>) throw const ApiException('Gemini 응답 형식이 올바르지 않아요.');
    return GoalPlan.fromJson(data);
  }
}

/// 백엔드 없이 UI와 전체 흐름을 확인하기 위한 구현.
class MockGoalRepository implements GoalRepository {
  @override
  Future<GoalPlan> generateGoal(GoalDraft draft) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return GoalPlan(
      title: draft.desiredChange,
      description: '${draft.period} 동안 "${draft.weakness}"을 바꾸는 연습을 해요.',
      durationDays: _parseDays(draft.period),
      steps: GoalStep.defaults,
    );
  }

  /// "1달 동안", "2주", "30일" 같은 표현에서 일 수를 추정합니다.
  static int _parseDays(String period) {
    final number = int.tryParse(RegExp(r'\d+').firstMatch(period)?.group(0) ?? '') ?? 1;
    if (period.contains('달') || period.contains('개월')) return number * 30;
    if (period.contains('주')) return number * 7;
    if (period.contains('년')) return number * 365;
    if (period.contains('일')) return number;
    return 30;
  }
}
