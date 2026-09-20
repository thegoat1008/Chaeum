import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const ChaeumApp());

class ChaeumApp extends StatelessWidget {
  const ChaeumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '채움',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
