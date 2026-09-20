import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'splash_screen.dart' show ChaeumLogo;

class HomeScreen extends StatelessWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 393),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 18, 40, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ChaeumLogo(size: 20, showTagline: false),
            const SizedBox(height: 20),
            Text('안녕하세요, $userName님!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            const Text('오늘도 성장해 볼까요?', style: TextStyle(fontSize: 18, color: AppColors.textGrey)),
            const SizedBox(height: 30),
            Container(
              height: 138,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 30, 20, 30),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('오늘의 미션 하러가기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.badge, borderRadius: BorderRadius.circular(5)),
                    child: const Text('D-12', style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ])),
                const Icon(Icons.waving_hand_rounded, size: 58, color: AppColors.primary),
              ]),
            ),
            const SizedBox(height: 70),
            Center(child: Image.asset('assets/images/aquarium.png', width: 257, height: 220, fit: BoxFit.contain)),
            const SizedBox(height: 14),
            const Center(child: Text('매일 미션을 진행하며 어항을 꾸며보세요!', style: TextStyle(fontSize: 12, color: AppColors.textGrey))),
          ]),
        ),
      ),
    );
  }
}
