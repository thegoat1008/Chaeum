import 'package:flutter/material.dart';

/// 색상 모음. 지금 값은 스크린샷으로 눈대중한 값이라
/// Figma Inspect 패널의 정확한 HEX로 여기만 고치면 앱 전체가 바뀝니다.
class AppColors {
  static const background = Color(0xFFFAFBFF);
  static const primary = Color(0xFF5E6A94); // 버튼, 로고, 선택된 탭
  static const textPrimary = Color(0xFF1A1A1A);
  static const textHint = Color(0xFFB0B4C0);
  static const textSub = Color(0xFF4C7BD9); // 파란 안내 문구
  static const textGrey = Color(0xFF8A8FA0);
  static const border = Color(0xFFC9CCD6);
  static const badge = Color(0xFF5E6A94);

  // 어항 배경 그라데이션 (위 -> 아래)
  static const waterTop = Color(0x00FFFFFF);
  static const waterMid = Color(0xFFCFF3FF);
  static const waterBlue = Color(0xFF4DA8FF);
  static const waterBottom = Color(0xFF8C8CFF);
}
