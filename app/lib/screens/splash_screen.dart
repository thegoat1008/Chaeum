import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

/// Figma: iPhone 16 - 1
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: ChaeumLogo(size: 40, showTagline: true)),
    );
  }
}

/// 임시 텍스트 로고. Figma에서 로고 PNG를 받으면 Image.asset으로 교체.
class ChaeumLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  const ChaeumLogo({super.key, required this.size, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('채움',
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                color: AppColors.primary)),
        if (showTagline)
          const Text('나를 채우는 즐거움',
              style: TextStyle(fontSize: 8, color: AppColors.textPrimary)),
      ],
    );
  }
}
