import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'aquarium_background.dart';
import 'primary_button.dart';

/// 해저 배경 위에 스피너와 안내 문구만 놓는 전체 화면 로딩.
/// "맞춤 목표를 생성하고 있어요", "AI가 완료 조건을 분석하고 있어요"가 같은 모양입니다.
class AquariumLoadingView extends StatelessWidget {
  final String message;

  const AquariumLoadingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AquariumBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 실패 안내. 안전 분기로 막힌 경우에는 재시도 버튼을 숨깁니다.
class AquariumErrorView extends StatelessWidget {
  final String message;
  final bool isSafetyBlock;
  final VoidCallback? onRetry;

  const AquariumErrorView({
    super.key,
    required this.message,
    this.isSafetyBlock = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AquariumBackground(
      child: Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSafetyBlock ? Icons.favorite_outline : Icons.error_outline,
                size: 36,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (!isSafetyBlock && onRetry != null) ...[
                const SizedBox(height: 24),
                PrimaryButton(label: '다시 시도', onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
