import 'package:flutter/material.dart';

/// Figma의 iPhone 16(393×852) 하단 해저 배경을 그대로 사용합니다.
class AquariumBackground extends StatelessWidget {
  final Widget child;
  const AquariumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFCFDFE),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: AspectRatio(
              aspectRatio: 393 / 412,
              child: Image.asset(
                'assets/images/ocean_background.png',
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
