import 'package:flutter/material.dart';

/// 디자인에 등장하는 바다 생물들.
///
/// Gemini는 미션마다 이모지 하나를 골라 보내는데(`generate-daily-mission`의 emoji),
/// 화면에는 피그마 일러스트를 씁니다. 이모지는 그 일러스트를 찾는 열쇠이자,
/// 아직 에셋이 없을 때의 폴백입니다.
/// 피그마에 실제로 그려져 있는 세 종류입니다. 여기에 없는 생물을 추가하려면
/// 디자인에서 먼저 그려야 하므로, generate-daily-mission 프롬프트도 이 셋으로
/// 제한해 두었습니다.
enum SeaCreature {
  crab('🦀', 'crab'),
  clownfish('🐠', 'clownfish'),
  jellyfish('🪼', 'jellyfish');

  const SeaCreature(this.emoji, this.name);

  final String emoji;
  final String name;

  /// assets/images/ 는 pubspec에 이미 등록돼 있어서 파일만 넣으면 바로 잡힙니다.
  String get asset => 'assets/images/creature_$name.png';

  /// 모르는 이모지는 흰동가리로 보냅니다. 디자인에서 가장 자주 등장합니다.
  static SeaCreature fromEmoji(String emoji) {
    for (final creature in SeaCreature.values) {
      if (creature.emoji == emoji) return creature;
    }
    return SeaCreature.clownfish;
  }
}

/// 바다 생물 일러스트. 에셋이 아직 없으면 같은 크기의 이모지로 대체합니다.
class SeaCreatureIcon extends StatelessWidget {
  final SeaCreature creature;
  final double size;

  const SeaCreatureIcon({super.key, required this.creature, required this.size});

  /// Gemini가 보낸 이모지로 바로 만듭니다.
  SeaCreatureIcon.fromEmoji(String emoji, {super.key, required this.size})
      : creature = SeaCreature.fromEmoji(emoji);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      creature.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, _, _) => SizedBox(
        width: size,
        height: size,
        child: Center(
          // 이모지는 글립 여백 때문에 조금 작게 잡아야 일러스트와 크기가 맞습니다.
          child: Text(creature.emoji, style: TextStyle(fontSize: size * 0.82)),
        ),
      ),
    );
  }
}
