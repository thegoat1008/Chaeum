import '../models/goal.dart';
import '../models/mission.dart';
import 'api_client.dart';

/// Agent Loop의 앱 쪽 입구입니다.
///
/// - [generateDailyMission] : 상태 확인 -> Rule Engine 판단 -> Mission 생성
/// - [evaluateAnswer]       : 사용자가 쓴 수행 내용으로 완료 조건 판정
abstract class MissionRepository {
  Future<Mission> generateDailyMission({
    required GoalDraft draft,
    required GoalPlan plan,
    required int dayIndex,
    Mission? previousMission,
    List<MissionFeedback> recentFeedback,
  });

  Future<MissionEvaluation> evaluateAnswer({required Mission mission, required String answer});

  factory MissionRepository.configured() {
    final client = ApiClient.fromEnvironment();
    return client == null ? MockMissionRepository() : GeminiMissionRepository(client);
  }
}

class GeminiMissionRepository implements MissionRepository {
  final ApiClient _api;

  GeminiMissionRepository(this._api);

  @override
  Future<Mission> generateDailyMission({
    required GoalDraft draft,
    required GoalPlan plan,
    required int dayIndex,
    Mission? previousMission,
    List<MissionFeedback> recentFeedback = const [],
  }) async {
    final payload = await _api.invoke('generate-daily-mission', {
      'goal': {
        'title': plan.title,
        'weakness': draft.weakness,
        'desiredChange': draft.desiredChange,
      },
      'dayIndex': dayIndex,
      'previousMission': previousMission?.toPreviousMissionPayload(),
      'recentFeedback': recentFeedback.map((item) => item.toJson()).toList(),
    });
    final data = payload['data'];
    if (data is! Map<String, dynamic>) throw const ApiException('Gemini 응답 형식이 올바르지 않아요.');
    return Mission.fromJson(data, payload['decision'] as Map<String, dynamic>?);
  }

  @override
  Future<MissionEvaluation> evaluateAnswer({required Mission mission, required String answer}) async {
    final payload = await _api.invoke('evaluate-mission', {
      'mission': mission.toEvaluationPayload(),
      'answer': answer,
    });
    final data = payload['data'];
    if (data is! Map<String, dynamic>) throw const ApiException('Gemini 응답 형식이 올바르지 않아요.');
    return MissionEvaluation.fromJson(data);
  }
}

/// 백엔드 없이 미션 흐름 전체를 확인하기 위한 구현.
/// Rule Engine과 같은 규칙(건너뛰기 2회 -> 축소, 완료 2회 -> 다음 단계)을 흉내 냅니다.
class MockMissionRepository implements MissionRepository {
  @override
  Future<Mission> generateDailyMission({
    required GoalDraft draft,
    required GoalPlan plan,
    required int dayIndex,
    Mission? previousMission,
    List<MissionFeedback> recentFeedback = const [],
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    var minutes = previousMission?.durationMinutes ?? 10;
    var stage = previousMission?.stage ?? 1;
    var ruleCode = 'INSUFFICIENT_PATTERN';
    var reason = '전략을 바꿀 만큼 같은 결과가 반복되지 않아 현재 단계를 유지합니다.';

    final missed = _trailing(recentFeedback, const {'skipped', 'no_response'});
    final completed = _trailing(recentFeedback, const {'completed'});
    if (missed >= 2) {
      final next = (minutes - 2).clamp(2, 5);
      ruleCode = 'TWO_CONSECUTIVE_MISSES';
      reason = '최근 건너뛰기·무응답이 $missed회 연속 확인되어 Mission 시간을 $minutes분에서 $next분으로 줄입니다.';
      minutes = next;
    } else if (completed >= 2) {
      ruleCode = 'TWO_CONSECUTIVE_COMPLETIONS';
      reason = '동일 단계 Mission을 $completed회 연속 완료하여 다음 단계로 이동합니다.';
      stage += 1;
      minutes = minutes.clamp(5, 10);
    } else {
      minutes = minutes.clamp(5, 10);
    }

    const objective = '프로젝트의 방향을 정하기 위해 떠오르는 아이디어를 자유롭게 정리해보세요';
    return Mission(
      dayIndex: dayIndex,
      title: '프로젝트 브레인스토밍하기',
      emoji: '🦀',
      objective: objective,
      objectiveHighlight: '떠오르는 아이디어',
      completionCriteria: const [
        '프로젝트 아이디어 3개 이상 적기',
        '각 아이디어에 대해 한 줄 설명 작성하기',
        '가장 해보고 싶은 아이디어 1개 선택하기',
      ],
      hints: const [
        MissionHint(title: '떠오르는 아이디어를 자유롭게 적어보세요', subtext: '완벽한 아이디어가 아니어도 괜찮아요'),
        MissionHint(title: '각 아이디어가 어떤 문제를 해결하는지\n한 줄로 적어보세요'),
        MissionHint(title: '가장 관심이 가는 아이디어 하나를 골라보세요'),
      ],
      durationMinutes: minutes,
      stage: stage,
      decisionReason: reason,
      ruleCode: ruleCode,
    );
  }

  @override
  Future<MissionEvaluation> evaluateAnswer({required Mission mission, required String answer}) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // 실제 판정은 Gemini가 합니다. Mock은 글자 수로 대충 나눠 화면만 확인합니다.
    final generous = answer.trim().length >= 40;
    final criteria = [
      for (var i = 0; i < mission.completionCriteria.length; i += 1)
        CriterionResult(
          text: mission.completionCriteria[i],
          met: generous || i == 0,
          comment: generous || i == 0
              ? '작성한 내용에서 이 조건을 확인했어요.'
              : '이 조건에 해당하는 내용을 조금만 더 적어주세요.',
        ),
    ];
    final metCount = criteria.where((item) => item.met).length;
    return MissionEvaluation(
      status: metCount == criteria.length ? 'completed' : 'partial',
      metCount: metCount,
      totalCount: criteria.length,
      criteria: criteria,
      summary: metCount == criteria.length
          ? '오늘 미션을 모두 채우셨어요. 내일은 한 단계 더 나아가 볼게요.'
          : '시작한 것만으로 충분해요. 남은 조건은 내일 미션에서 이어가 볼게요.',
    );
  }

  static int _trailing(List<MissionFeedback> feedback, Set<String> statuses) {
    var count = 0;
    for (var i = feedback.length - 1; i >= 0; i -= 1) {
      if (!statuses.contains(feedback[i].status)) break;
      count += 1;
    }
    return count;
  }
}
