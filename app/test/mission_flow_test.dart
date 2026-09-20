import 'package:chaeum/models/goal.dart';
import 'package:chaeum/models/mission.dart';
import 'package:chaeum/repositories/mission_repository.dart';
import 'package:chaeum/screens/main_shell.dart';
import 'package:chaeum/state/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _draft = GoalDraft(
  weakness: '과제를 자꾸 미루는 것',
  desiredChange: '마감 이틀 전에 시작하고 싶다',
  period: '1달 동안',
);

final _plan = GoalPlan(
  title: '마감 이틀 전에 과제를 시작하기',
  description: '1달 동안 미루는 습관을 바꾸는 연습을 해요.',
  durationDays: 30,
  steps: GoalStep.defaults,
);

SessionController _session({DateTime? startedOn}) => SessionController(
      userName: '지우',
      draft: _draft,
      plan: _plan,
      repository: MockMissionRepository(),
      startedOn: startedOn,
    );

/// 프레임을 직접 밀어 줍니다.
///
/// pumpAndSettle은 쓰지 않습니다. 로딩 화면의 CircularProgressIndicator가 계속
/// 애니메이션하기 때문에 영원히 settle되지 않습니다.
Future<void> _pump(WidgetTester tester, [Duration step = const Duration(milliseconds: 600)]) async {
  await tester.pump();
  await tester.pump(step);
  await tester.pump();
}

/// Mock Repository의 2초 지연을 넘깁니다.
Future<void> _pumpNetwork(WidgetTester tester) => _pump(tester, const Duration(seconds: 3));

/// 화면 전체가 한 번에 보이도록 세로로 긴 뷰포트를 씁니다.
/// 스크롤해서 버튼을 찾아 누르는 수고를 없애기 위한 테스트 전용 설정입니다.
Future<void> _launch(WidgetTester tester, SessionController session) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: MainShell(session: session)));
  await _pumpNetwork(tester);
}

/// 미션 탭을 열고 오늘의 미션이 그려질 때까지 기다립니다.
Future<void> _openMissionTab(WidgetTester tester) async {
  await tester.tap(find.text('mission'));
  await _pumpNetwork(tester);
}

/// 시작하기 -> 수행 내용 작성 -> 제출까지. 제출 직후(분석 중) 상태로 둡니다.
Future<void> _submitAnswer(WidgetTester tester) async {
  await tester.tap(find.text('시작하기'));
  await _pump(tester);
  // Mock 판정기는 답변 길이로 충족 여부를 흉내 내므로 조건 3개를 모두 채울 만큼 씁니다.
  await tester.enterText(
    find.byType(TextField),
    '아이디어를 세 개 적었어요. 각각 어떤 문제를 해결하는지 한 줄로 설명했고, '
        '그중 가장 해보고 싶은 아이디어 하나를 골랐어요.',
  );
  await _pump(tester);
  await tester.tap(find.text('제출하기'));
  await tester.pump();
}

void main() {
  group('SessionController', () {
    test('도전 시작일로 DAY와 D-day를 계산한다', () {
      final session = _session(startedOn: DateTime.now().subtract(const Duration(days: 17)));
      expect(session.dayIndex, 18);
      expect(session.remainingDays, 12);
      session.dispose();
    });

    test('건너뛰기가 2회 연속되면 다음 미션 시간이 줄어든다', () async {
      final session = _session();
      await session.loadMission();
      expect(session.mission!.durationMinutes, 10);

      await session.skipMission();
      await session.skipMission();

      expect(session.mission!.ruleCode, 'TWO_CONSECUTIVE_MISSES');
      expect(session.mission!.durationMinutes, lessThan(10));
      expect(session.mission!.decisionReason, isNotEmpty);
      session.dispose();
    });

    test('일시정지 중에는 미션을 만들지 않는다', () async {
      final session = _session();
      session.setPaused(true);
      await session.loadMission();
      expect(session.mission, isNull);
      session.dispose();
    });

    test('완료 조건 판정 결과가 피드백 상태로 이어진다', () async {
      final session = _session();
      await session.loadMission();
      await session.submitAnswer('아이디어를 세 개 적었고 각각 한 줄로 설명한 뒤 가장 해보고 싶은 것을 골랐어요.');

      expect(session.stage, MissionStage.feedback);
      expect(session.evaluation!.isComplete, isTrue);

      session.submitFeedback(difficulty: MissionDifficulty.hard, reasons: const ['집중 어려움']);
      expect(session.feedbackHistory.single.status, 'completed');
      expect(session.feedbackHistory.single.difficulty, MissionDifficulty.hard);
      session.dispose();
    });
  });

  group('미션 화면', () {
    testWidgets('미션 탭에서 오늘의 미션과 판단 근거를 보여 준다', (tester) async {
      await _launch(tester, _session());
      await _openMissionTab(tester);

      expect(find.text('DAY 1'), findsOneWidget);
      expect(find.text('프로젝트 브레인스토밍하기'), findsOneWidget);
      expect(find.text('완료 조건'), findsOneWidget);
      expect(find.text('이 미션을 고른 이유'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
    });

    testWidgets('제출하면 AI 분석을 거쳐 난이도 화면으로 넘어간다', (tester) async {
      await _launch(tester, _session());
      await _openMissionTab(tester);
      await _submitAnswer(tester);

      expect(find.text('AI가 완료 조건을 분석하고 있어요'), findsOneWidget);

      await _pumpNetwork(tester);
      expect(find.text('미션 통계'), findsOneWidget);
      expect(find.text('오늘 미션 난이도는 어땠나요?'), findsOneWidget);
      expect(find.textContaining('완료 조건 3/3 충족'), findsOneWidget);
    });

    testWidgets('이유 칩은 "어려웠어요"를 고를 때만 나타난다', (tester) async {
      await _launch(tester, _session());
      await _openMissionTab(tester);
      await _submitAnswer(tester);
      await _pumpNetwork(tester);

      expect(find.text('집중 어려움'), findsNothing);

      await tester.tap(find.text('어려웠어요'));
      await _pump(tester);
      expect(find.text('어려웠다면 이유를 알려주세요'), findsOneWidget);
      expect(find.text('집중 어려움'), findsOneWidget);

      // 어려웠어요가 아니면 이유를 묻지 않고 이미 고른 값도 비웁니다.
      await tester.tap(find.text('적당했어요'));
      await _pump(tester);
      expect(find.text('집중 어려움'), findsNothing);
    });

    testWidgets('완료하기를 누르면 피드백 감사 화면이 나온다', (tester) async {
      final session = _session();
      await _launch(tester, session);
      await _openMissionTab(tester);
      await _submitAnswer(tester);
      await _pumpNetwork(tester);

      await tester.tap(find.text('적당했어요'));
      await _pump(tester);
      await tester.tap(find.text('완료하기'));
      await _pump(tester);

      expect(find.textContaining('더 좋은'), findsOneWidget);
      expect(session.feedbackHistory.single.difficulty, MissionDifficulty.normal);
    });
  });
}
