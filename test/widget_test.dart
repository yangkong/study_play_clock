// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:study_play_clock/main.dart';
import 'package:study_play_clock/providers/time_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => TimeProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the app title is present
    expect(find.text('STUDY PLAY CLOCK'), findsWidgets);
    
    // Verify that the initial time is 00:00:00
    expect(find.text('00:00:00'), findsOneWidget);

    // Verify presence of buttons
    expect(find.text('공부 시작'), findsOneWidget);
  });
}
