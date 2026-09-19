import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 목표 입력 화면(5~10번) 아래쪽 바다 배경.
/// 해파리·물고기·해초는 Figma에서 PNG로 내보낸 뒤 여기에 추가할 예정.
class AquariumBackground extends StatelessWidget {
  final Widget child;
  const AquariumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: height * 0.55,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.waterTop,
                  AppColors.waterMid,
                  AppColors.waterBlue,
                  AppColors.waterBottom,
                ],
                stops: [0.0, 0.25, 0.65, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
