import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'splash_screen.dart' show ChaeumLogo;

/// Figma: iPhone 16 - 4 (홈)
/// D-12는 임시 값입니다. 실제 데이터는 API 연결 후 교체.
class HomeScreen extends StatelessWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChaeumLogo(size: 16),
          const SizedBox(height: 14),
          Text('안녕하세요, $userName님!',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          const Text('오늘도 성장해 볼까요?',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('오늘의 미션 하러가기',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.badge,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('D-12',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Image.asset('assets/images/aquarium.png', width: 260),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('매일 미션을 진행하며 어항을 꾸며보세요!',
                style: TextStyle(fontSize: 9, color: AppColors.textGrey)),
          ),
        ],
      ),
    );
  }
}
