import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final instance = GoogleAuthService._();

  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  final GoogleSignIn _signIn = GoogleSignIn.instance;
  bool _initialized = false;

  Stream<GoogleSignInAuthenticationEvent> get events => _signIn.authenticationEvents;

  Future<void> initialize() async {
    if (_initialized) return;
    await _signIn.initialize(
      clientId: _webClientId.isEmpty ? null : _webClientId,
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    _initialized = true;
    final lightweight = _signIn.attemptLightweightAuthentication();
    if (lightweight != null) {
      unawaited(lightweight.then<void>((_) {}));
    }
  }

  bool get supportsDirectAuthentication => _signIn.supportsAuthenticate();

  Future<GoogleSignInAccount> signIn() async {
    await initialize();
    if (!_signIn.supportsAuthenticate()) {
      throw const GoogleAuthException('웹에서는 Google 공식 로그인 버튼을 눌러주세요.');
    }
    return _signIn.authenticate();
  }

  Future<void> signOut() => _signIn.signOut();
}

class GoogleAuthException implements Exception {
  final String message;
  const GoogleAuthException(this.message);
  @override
  String toString() => message;
}
