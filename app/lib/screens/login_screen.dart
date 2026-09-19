import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'name_screen.dart';
import 'splash_screen.dart' show ChaeumLogo;

/// Figma: iPhone 16 - 2
/// 인증 방식은 팀(수아)과 확정 전이라 지금은 화면만 동작합니다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const ChaeumLogo(size: 36, showTagline: true),
                const SizedBox(height: 56),
                const AppTextField(hint: '아이디'),
                const SizedBox(height: 12),
                const AppTextField(hint: '비밀번호', obscureText: true),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('아이디 찾기',
                        style: TextStyle(fontSize: 8, color: AppColors.textGrey)),
                    SizedBox(width: 12),
                    Text('|',
                        style: TextStyle(fontSize: 8, color: AppColors.textGrey)),
                    SizedBox(width: 12),
                    Text('비밀번호 찾기',
                        style: TextStyle(fontSize: 8, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: '로그인하기',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NameScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text('회원가입',
                    style: TextStyle(fontSize: 8, color: AppColors.textGrey)),
                const SizedBox(height: 10),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Text('G',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
