import 'dart:convert';

import 'package:http/http.dart' as http;

/// Supabase Edge Function 호출 공통 클라이언트.
///
/// URL/키는 빌드 타임에만 주입합니다. 값이 없으면 각 Repository가 Mock 구현으로
/// 떨어지므로, 백엔드 없이도 앱 전체 흐름을 그대로 돌려 볼 수 있습니다.
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=...
class ApiClient {
  final String supabaseUrl;
  final String anonKey;
  final http.Client _client;

  ApiClient({required this.supabaseUrl, required this.anonKey, http.Client? client})
      : _client = client ?? http.Client();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// 빌드 타임 설정이 모두 있을 때만 클라이언트를 만듭니다. 없으면 null.
  static ApiClient? fromEnvironment() {
    if (_url.isEmpty || _anonKey.isEmpty) return null;
    return ApiClient(supabaseUrl: _url, anonKey: _anonKey);
  }

  /// Edge Function을 호출하고 JSON 본문을 돌려줍니다.
  ///
  /// 함수들이 실패를 {"error": "..."} 형태로 통일해 두었으므로, 사용자에게 보여 줄
  /// 문구는 그 값을 우선 사용합니다.
  Future<Map<String, dynamic>> invoke(String function, Map<String, dynamic> body) async {
    final base = supabaseUrl.replaceFirst(RegExp(r'/+$'), '');
    late final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$base/functions/v1/$function'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const ApiException('네트워크 연결을 확인해주세요.');
    }

    Map<String, dynamic>? payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      payload = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload?['error']?.toString();
      throw ApiException(
        message?.isNotEmpty == true ? message! : '요청에 실패했어요. (${response.statusCode})',
        statusCode: response.statusCode,
        // 안전 분기(422)는 재시도가 아니라 안내로 끝나야 하는 응답입니다.
        safety: payload?['safety'] as Map<String, dynamic>?,
      );
    }

    if (payload == null) throw const ApiException('서버 응답 형식이 올바르지 않아요.');
    return payload;
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? safety;

  const ApiException(this.message, {this.statusCode, this.safety});

  /// 안전 분기로 막힌 응답인지. 이 경우 화면은 재시도 버튼 대신 안내를 보여 줍니다.
  bool get isSafetyBlock => statusCode == 422;

  @override
  String toString() => message;
}
