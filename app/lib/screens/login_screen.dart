import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/primary_button.dart';
import 'name_screen.dart';
import 'splash_screen.dart' show ChaeumLogo;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  bool _loading = true;
  bool _googleReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeGoogleAuth();
  }

  Future<void> _initializeGoogleAuth() async {
    _authSubscription = GoogleAuthService.instance.events.listen(
      _handleAuthEvent,
      onError: (Object error) {
        if (mounted) setState(() => _error = _friendlyError(error));
      },
    );
    try {
      await GoogleAuthService.instance.initialize();
      if (mounted) setState(() { _loading = false; _googleReady = true; });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = _friendlyError(error); });
    }
  }

  void _handleAuthEvent(GoogleSignInAuthenticationEvent event) {
    if (!mounted || event is! GoogleSignInAuthenticationEventSignIn) return;
    final displayName = event.user.displayName?.trim();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NameScreen(initialName: displayName?.split(' ').first),
    ));
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await GoogleAuthService.instance.signIn();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled) return 'Google 로그인이 취소됐어요.';
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 393,
          height: 852,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(children: [
              const SizedBox(height: 150),
              const ChaeumLogo(),
              const SizedBox(height: 60),
              const AppTextField(hint: '아이디'),
              const SizedBox(height: 12),
              const AppTextField(hint: '비밀번호', obscureText: true),
              const SizedBox(height: 10),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('아이디 찾기', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                SizedBox(width: 18),
                SizedBox(height: 16, child: VerticalDivider(width: 1, thickness: 1, color: AppColors.textGrey)),
                SizedBox(width: 18),
                Text('비밀번호 찾기', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ]),
              const SizedBox(height: 20),
              PrimaryButton(label: '로그인하기', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NameScreen()))),
              const SizedBox(height: 12),
              const Text('회원가입', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 20),
              if (_loading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              else if (_googleReady)
                GoogleAuthButton(onPressed: _signInWithGoogle),
              if (!_loading && !_googleReady && _error == null)
                const Text('Google OAuth 설정이 필요합니다.', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
