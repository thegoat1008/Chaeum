import 'package:flutter/material.dart';
import 'login_screen.dart';

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
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: SizedBox(width: 393, height: 852, child: Center(child: ChaeumLogo()))),
      );
}

class ChaeumLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const ChaeumLogo({super.key, this.size = 50, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    if (showTagline) {
      return Image.asset(
        'assets/images/chaeum_logo.png',
        width: size == 50 ? 95 : size * 1.9,
        height: size == 50 ? 68 : size * 1.36,
        fit: BoxFit.contain,
      );
    }
    return Image.asset(
      'assets/images/chaeum_logo_small.png',
      width: size * 1.9,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
