// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:treasure_ar_app/main.dart';

void main() {
  testWidgets('App starts and shows home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TreasureARApp());

    // Verify that the home page is displayed.
    expect(find.text('AR宝探し'), findsOneWidget);
    expect(find.text('ゲームを始める'), findsOneWidget);
    expect(find.text('使い方'), findsOneWidget);
  });
}
