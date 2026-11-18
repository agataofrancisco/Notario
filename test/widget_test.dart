import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notario/app.dart';
import 'package:notario/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnauthenticatedFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Setup mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(NotarioApp(
      prefs: prefs,
      authService: AuthService(auth: _UnauthenticatedFirebaseAuth()),
    ));

    // Verify that the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
