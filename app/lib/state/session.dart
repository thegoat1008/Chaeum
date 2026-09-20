import 'package:flutter/widgets.dart';

import '../models/goal.dart';
import '../models/mission.dart';
import '../repositories/api_client.dart';
import '../repositories/mission_repository.dart';

/// Mission 화면이 지나가는 단계. 디자인의 미션 탭 화면들과 1:1로 대응합니다.
enum MissionStage {
  loading, // 미션 생성 중
  overview, // 오늘의 미션
  writing, // 수행 내용 작성
  evaluating, // AI가 완료 조건을 분석하고 있어요
  feedback, // 미션 통계 (난이도 + 이유)
  complete, // 피드백 감사 화면
  error,
}

/// 에이전트가 무엇을 왜 했는지 남기는 기록. 프로필 탭의 활동 이력에 표시합니다.
class AgentEvent {
  final String type;
  final String title;
  final String detail;
  final DateTime at;

  AgentEvent({required this.type, required this.title, required this.detail, DateTime? at})
      : at = at ?? DateTime.now();
}

/// 목표 위임 -> Mission -> Feedback -> 재계획을 앱에서 이어 주는 상태 보관소.
///
/// 지금은 메모리에만 남습니다. Supabase Auth/DB가 붙으면 [_events], [feedbackHistory],
/// [currentMission]을 저장·복원하는 지점만 바꾸면 됩니다.
class SessionController extends ChangeNotifier {
  SessionController({
    required this.userName,
    required this.draft,
    required this.plan,
    MissionRepository? repository,
    DateTime? startedOn,
  })  : _repository = repository ?? MissionRepository.configured(),
        startedOn = startedOn ?? DateTime.now();

  final String userName;
  final GoalDraft draft;
  final GoalPlan plan;
  final DateTime startedOn;
  final MissionRepository _repository;

  final List<MissionFeedback> feedbackHistory = [];
  final List<AgentEvent> _events = [];

  Mission? _mission;
  Mission? _previousMission;
  MissionEvaluation? _evaluation;
  MissionStage _stage = MissionStage.loading;
  String? _error;
  bool _errorIsSafetyBlock = false;
  bool _paused = false;

  Mission? get mission => _mission;
  MissionEvaluation? get evaluation => _evaluation;
  MissionStage get stage => _stage;
  String? get error => _error;
  bool get errorIsSafetyBlock => _errorIsSafetyBlock;
  bool get paused => _paused;
  List<AgentEvent> get events => List.unmodifiable(_events.reversed);

  /// 도전 시작일로부터 오늘이 며칠째인지. 화면의 "DAY 18".
  int get dayIndex => DateTime.now().difference(_dateOnly(startedOn)).inDays + 1;

  /// 목표 기간까지 남은 일수. 홈 카드의 "D-12".
  int get remainingDays => (plan.durationDays - dayIndex).clamp(0, plan.durationDays);

  /// 오늘 미션을 이미 끝냈는지. 홈 카드 문구가 이 값에 따라 바뀝니다.
  bool get isTodayDone => _stage == MissionStage.complete;

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  void _set(MissionStage stage) {
    _stage = stage;
    notifyListeners();
  }

  void _log(String type, String title, String detail) {
    _events.add(AgentEvent(type: type, title: title, detail: detail));
  }

  /// 첫 진입 시 한 번만 미션을 만듭니다. 이미 있거나 생성 중이면 아무것도 하지 않습니다.
  Future<void> ensureMission() async {
    if (_mission != null || _loading || _stage == MissionStage.error) return;
    await loadMission();
  }

  bool _loading = false;

  Future<void> loadMission() async {
    if (_paused || _loading) return;
    _loading = true;
    _error = null;
    _errorIsSafetyBlock = false;
    _evaluation = null;
    _set(MissionStage.loading);
    try {
      final mission = await _repository.generateDailyMission(
        draft: draft,
        plan: plan,
        dayIndex: dayIndex,
        previousMission: _previousMission,
        recentFeedback: feedbackHistory,
      );
      _mission = mission;
      _log(
        'mission_created',
        'DAY ${mission.dayIndex} · ${mission.title}',
        mission.decisionReason.isEmpty
            ? '${mission.durationMinutes}분짜리 미션을 만들었어요.'
            : mission.decisionReason,
      );
      _set(MissionStage.overview);
    } on ApiException catch (error) {
      _error = error.message;
      _errorIsSafetyBlock = error.isSafetyBlock;
      if (error.isSafetyBlock) _log('safety_paused', '안전 분기', error.message);
      _set(MissionStage.error);
    } catch (error) {
      _error = error.toString();
      _set(MissionStage.error);
    } finally {
      _loading = false;
    }
  }

  void startWriting() => _set(MissionStage.writing);

  void backToOverview() => _set(MissionStage.overview);

  /// 수행 내용을 제출하고 완료 조건을 AI가 판정합니다. 디자인의 분석 로딩 화면 구간.
  Future<void> submitAnswer(String answer) async {
    final mission = _mission;
    if (mission == null) return;
    _error = null;
    _errorIsSafetyBlock = false;
    _set(MissionStage.evaluating);
    try {
      final evaluation = await _repository.evaluateAnswer(mission: mission, answer: answer);
      _evaluation = evaluation;
      _log(
        'mission_evaluated',
        '완료 조건 ${evaluation.metCount}/${evaluation.totalCount} 충족',
        evaluation.summary,
      );
      _set(MissionStage.feedback);
    } on ApiException catch (error) {
      _error = error.message;
      _errorIsSafetyBlock = error.isSafetyBlock;
      if (error.isSafetyBlock) _log('safety_paused', '안전 분기', error.message);
      _set(MissionStage.error);
    } catch (error) {
      _error = error.toString();
      _set(MissionStage.error);
    }
  }

  /// 난이도와 이유를 기록합니다. 다음 Mission 생성 요청에 그대로 실려 갑니다.
  void submitFeedback({required MissionDifficulty difficulty, required List<String> reasons}) {
    final status = _evaluation?.status ?? 'partial';
    feedbackHistory.add(
      MissionFeedback(status: status, difficulty: difficulty, reasons: reasons),
    );
    _log(
      'feedback_recorded',
      '난이도 ${difficulty.label}',
      reasons.isEmpty ? '결과: $status' : '결과: $status · 이유: ${reasons.join(', ')}',
    );
    _set(MissionStage.complete);
  }

  /// 미션 건너뛰기. Rule Engine이 다음 미션에서 분량을 줄이는 근거가 됩니다.
  Future<void> skipMission() async {
    feedbackHistory.add(const MissionFeedback(status: 'skipped'));
    _log('feedback_recorded', '미션 건너뛰기', '건너뛰기가 2회 연속되면 다음 미션 시간을 줄입니다.');
    _rollOver();
    await loadMission();
  }

  Future<void> regenerateMission() async {
    _log('mission_regenerated', '미션 다시 생성', '같은 단계에서 다른 행동을 제안합니다.');
    _rollOver();
    await loadMission();
  }

  /// 현재 미션을 "직전 미션"으로 밀어 둡니다. Rule Engine이 시간·단계를 이어받고,
  /// Gemini는 같은 행동을 반복하지 않는 근거로 씁니다.
  void _rollOver() {
    if (_mission != null) _previousMission = _mission;
    _mission = null;
  }

  /// 통제 센터의 일시정지. 켜져 있는 동안 미션 생성과 알림을 멈춥니다.
  void setPaused(bool value) {
    if (_paused == value) return;
    _paused = value;
    _log(
      value ? 'goal_paused' : 'goal_resumed',
      value ? '목표 일시정지' : '목표 재개',
      value ? '예정된 알림과 미션 생성을 멈췄어요.' : '다시 미션을 만들어 드릴게요.',
    );
    notifyListeners();
  }

  /// 다음 날 미션으로 넘어갑니다(완료 화면에서 돌아올 때).
  Future<void> startNextMission() async {
    _rollOver();
    await loadMission();
  }
}

/// 위젯 트리 어디서든 [SessionController]를 꺼내 쓰기 위한 스코프.
class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({super.key, required SessionController controller, required super.child})
      : super(notifier: controller);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope?.notifier != null, 'SessionScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }
}
