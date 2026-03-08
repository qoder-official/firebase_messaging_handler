// This is a basic Flutter widget test for the Firebase Messaging Handler example.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_messaging_handler_example/main.dart';

void main() {
  testWidgets('Firebase Messaging Handler example app loads', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads and shows the Firebase setup screen
    // (since Firebase is not configured in tests)
    expect(find.text('Firebase Setup Required'), findsOneWidget);
  });
}
