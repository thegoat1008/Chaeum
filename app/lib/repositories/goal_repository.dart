import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/goal.dart';

abstract class GoalRepository {
  Future<GeneratedGoal> generateGoal(GoalDraft draft);

  factory GoalRepository.configured() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isNotEmpty && anonKey.isNotEmpty) {
      return GeminiGoalRepository(supabaseUrl: url, anonKey: anonKey);
    }
    return MockGoalRepository();
  }
}

class GeminiGoalRepository implements GoalRepository {
  final String supabaseUrl;
  final String anonKey;
  final http.Client _client;

  GeminiGoalRepository({required this.supabaseUrl, required this.anonKey, http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<GeneratedGoal> generateGoal(GoalDraft draft) async {
    final response = await _client.post(
      Uri.parse('${supabaseUrl.replaceFirst(RegExp(r'/+$'), '')}/functions/v1/generate-mission'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
      body: jsonEncode({
        'weakness': draft.weakness,
        'desiredChange': draft.desiredChange,
        'period': draft.period,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GoalGenerationException('맞춤 목표 생성에 실패했어요. (${response.statusCode})');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    if (data == null) throw const GoalGenerationException('Gemini 응답 형식이 올바르지 않아요.');
    final stepsJson = data['steps'] as List<dynamic>? ?? const [];
    final steps = stepsJson.map((item) {
      final step = item as Map<String, dynamic>;
      return GoalStep(title: step['title']?.toString() ?? '', description: step['description']?.toString() ?? '');
    }).where((step) => step.title.isNotEmpty).toList();
    if (steps.length < 2) {
      steps
        ..clear()
        ..addAll(const [
          GoalStep(title: '작게 시작하기', description: '부담 없는 첫 행동 하나를 정해요.'),
          GoalStep(title: '매일 기록하기', description: '완료 여부와 느낀 점을 짧게 남겨요.'),
        ]);
    }
    return GeneratedGoal(
      title: data['title']?.toString() ?? draft.desiredChange,
      description: data['description']?.toString() ?? '',
      steps: steps,
    );
  }
}

class MockGoalRepository implements GoalRepository {
  @override
  Future<GeneratedGoal> generateGoal(GoalDraft draft) async {
    await Future.delayed(const Duration(seconds: 2));
    return GeneratedGoal(
      title: draft.desiredChange,
      description: '${draft.period} 동안 “${draft.weakness}”을 바꾸는 연습을 해요.',
      steps: const [
        GoalStep(title: '작게 시작하기', description: '부담 없는 첫 행동 하나를 정해요.'),
        GoalStep(title: '매일 기록하기', description: '완료 여부와 느낀 점을 짧게 남겨요.'),
      ],
    );
  }
}

class GoalGenerationException implements Exception {
  final String message;
  const GoalGenerationException(this.message);
  @override
  String toString() => message;
}
