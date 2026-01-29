import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akshaya_hub/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen has welcome text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));

    // Verify that our welcome text is displayed
    expect(find.text('Welcome to Akshaya Hub'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
