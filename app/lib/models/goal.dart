/// 온보딩에서 사용자가 직접 입력한 원문. AI가 이 내용을 추측하거나 바꾸지 않습니다.
class GoalDraft {
  final String weakness;
  final String desiredChange;
  final String period;

  const GoalDraft({required this.weakness, required this.desiredChange, required this.period});

  Map<String, dynamic> toJson() => {
        'weakness': weakness,
        'desiredChange': desiredChange,
        'period': period,
      };
}

/// generate-mission이 돌려준 목표 + 알림 계획. steps는 승인 후 실제로 예약할 Trigger입니다.
class GoalPlan {
  final String title;
  final String description;
  final int durationDays;
  final List<GoalStep> steps;

  const GoalPlan({
    required this.title,
    required this.description,
    required this.durationDays,
    required this.steps,
  });

  factory GoalPlan.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GoalStep.fromJson)
        .where((step) => step.title.isNotEmpty)
        .toList();
    final days = json['durationDays'];
    return GoalPlan(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      durationDays: days is int && days > 0 ? days : 30,
      steps: steps.isEmpty ? GoalStep.defaults : steps,
    );
  }
}

/// 알림 계획 한 줄. triggerType/time/daysBefore는 mission_triggers 예약에 그대로 쓰입니다.
class GoalStep {
  final String title;
  final String description;
  final String triggerType;
  final String time;
  final int daysBefore;

  const GoalStep({
    required this.title,
    required this.description,
    this.triggerType = 'daily',
    this.time = '18:00',
    this.daysBefore = 0,
  });

  factory GoalStep.fromJson(Map<String, dynamic> json) {
    final daysBefore = json['daysBefore'];
    return GoalStep(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      triggerType: json['triggerType']?.toString() ?? 'daily',
      time: json['time']?.toString() ?? '18:00',
      daysBefore: daysBefore is int ? daysBefore : 0,
    );
  }

  /// Gemini가 계획을 비워 보낸 경우에만 쓰이는 최소 안전망.
  static const defaults = [
    GoalStep(
      title: '마감 일주일 전 시작',
      description: '마감 일주일 전에 시작하도록 알려드릴게요',
      triggerType: 'deadline',
      daysBefore: 7,
    ),
    GoalStep(
      title: '매일 오후 6시 알림',
      description: '매일 오후 6시에 알려드릴게요',
      triggerType: 'daily',
      time: '18:00',
    ),
  ];
}
