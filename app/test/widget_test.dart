import 'package:flutter_test/flutter_test.dart';

import 'package:chaeum/main.dart';

void main() {
  testWidgets('스플래시 후 로그인 화면으로 이동', (WidgetTester tester) async {
    await tester.pumpWidget(const ChaeumApp());

    // 스플래시 화면 확인
    expect(find.text('채움'), findsOneWidget);

    // 1.5초 뒤 로그인 화면으로 넘어가는지 확인
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('로그인하기'), findsOneWidget);
  });
}