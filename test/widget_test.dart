import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notario/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Setup mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(NotarioApp(prefs: prefs));

    // Verify that the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
