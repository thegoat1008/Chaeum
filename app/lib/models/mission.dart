/// 오늘의 Mission 카드. generate-daily-mission 응답과 1:1로 대응합니다.
class Mission {
  final int dayIndex;
  final String title;
  final String emoji;
  final String objective;

  /// objective 안에서 파란색으로 강조할 어구. 비어 있으면 강조하지 않습니다.
  final String objectiveHighlight;
  final List<String> completionCriteria;
  final List<MissionHint> hints;
  final int durationMinutes;
  final int stage;

  /// Rule Engine이 이 Mission을 왜 이렇게 정했는지. 활동 이력과 재계획 카드에 표시합니다.
  final String decisionReason;
  final String ruleCode;

  const Mission({
    required this.dayIndex,
    required this.title,
    required this.emoji,
    required this.objective,
    required this.objectiveHighlight,
    required this.completionCriteria,
    required this.hints,
    required this.durationMinutes,
    required this.stage,
    required this.decisionReason,
    required this.ruleCode,
  });

  factory Mission.fromJson(Map<String, dynamic> data, Map<String, dynamic>? decision) {
    final dayIndex = data['dayIndex'];
    final duration = data['durationMinutes'];
    final stage = data['stage'];
    return Mission(
      dayIndex: dayIndex is int && dayIndex > 0 ? dayIndex : 1,
      title: data['title']?.toString() ?? '',
      emoji: data['emoji']?.toString() ?? '🐠', // 에셋이 있는 세 종류 중 기본값
      objective: data['objective']?.toString() ?? '',
      objectiveHighlight: data['objectiveHighlight']?.toString() ?? '',
      completionCriteria: (data['completionCriteria'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      hints: (data['hints'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MissionHint.fromJson)
          .where((hint) => hint.title.isNotEmpty)
          .toList(),
      durationMinutes: duration is int ? duration : 10,
      stage: stage is int ? stage : 1,
      decisionReason: decision?['reason']?.toString() ?? '',
      ruleCode: decision?['ruleCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toEvaluationPayload() => {
        'title': title,
        'objective': objective,
        'completionCriteria': completionCriteria,
      };

  Map<String, dynamic> toPreviousMissionPayload() => {
        'title': title,
        'durationMinutes': durationMinutes,
        'stage': stage,
      };
}

class MissionHint {
  final String title;
  final String subtext;

  const MissionHint({required this.title, this.subtext = ''});

  factory MissionHint.fromJson(Map<String, dynamic> json) => MissionHint(
        title: json['title']?.toString() ?? '',
        subtext: json['subtext']?.toString() ?? '',
      );
}

/// evaluate-mission이 돌려준 완료 조건 판정 결과.
class MissionEvaluation {
  final String status; // completed | partial
  final int metCount;
  final int totalCount;
  final List<CriterionResult> criteria;
  final String summary;

  const MissionEvaluation({
    required this.status,
    required this.metCount,
    required this.totalCount,
    required this.criteria,
    required this.summary,
  });

  bool get isComplete => status == 'completed';

  factory MissionEvaluation.fromJson(Map<String, dynamic> data) {
    final criteria = (data['criteria'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CriterionResult.fromJson)
        .toList();
    final metCount = data['metCount'];
    final totalCount = data['totalCount'];
    return MissionEvaluation(
      status: data['status']?.toString() ?? 'partial',
      metCount: metCount is int ? metCount : criteria.where((item) => item.met).length,
      totalCount: totalCount is int ? totalCount : criteria.length,
      criteria: criteria,
      summary: data['summary']?.toString() ?? '',
    );
  }
}

class CriterionResult {
  final String text;
  final bool met;
  final String comment;

  const CriterionResult({required this.text, required this.met, required this.comment});

  factory CriterionResult.fromJson(Map<String, dynamic> json) => CriterionResult(
        text: json['text']?.toString() ?? '',
        met: json['met'] == true,
        comment: json['comment']?.toString() ?? '',
      );
}

/// 난이도 피드백. code는 서버 Rule Engine의 applyDifficulty가 읽는 값입니다.
enum MissionDifficulty {
  hard('hard', '😢', '어려웠어요'),
  normal('normal', '😌', '적당했어요'),
  easy('easy', '😊', '쉬웠어요');

  const MissionDifficulty(this.code, this.emoji, this.label);

  final String code;
  final String emoji;
  final String label;
}

/// 디자인의 이유 칩. "어려웠어요"를 고른 경우에만 노출합니다.
const missionDifficultyReasons = <String>[
  '시간 부족',
  '시작 어려움',
  '할 일 많음',
  '아이디어 부족',
  '집중 어려움',
  '완료 조건 부담',
  '생각 정리 어려움',
  '주변 상황',
  '기타',
];

/// 한 번의 Mission 수행 결과. 다음 Mission 생성 요청에 그대로 실려 갑니다.
class MissionFeedback {
  final String status; // completed | partial | skipped | no_response
  final MissionDifficulty? difficulty;
  final List<String> reasons;

  const MissionFeedback({required this.status, this.difficulty, this.reasons = const []});

  Map<String, dynamic> toJson() => {
        'status': status,
        if (difficulty != null) 'difficulty': difficulty!.code,
        'reason': reasons.isEmpty ? null : reasons.join(', '),
      };
}
