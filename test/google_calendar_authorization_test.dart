import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notario/core/services/auth_service.dart';
import 'package:notario/core/services/google_calendar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnauthenticatedFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleSignIn implements GoogleSignIn {
  _FakeGoogleSignIn({required this.account, this.granted = true});

  GoogleSignInAccount? account;
  final bool granted;
  int signInCalls = 0;
  int silentSignInCalls = 0;
  int disconnectCalls = 0;
  List<String>? requestedScopes;

  @override
  GoogleSignInAccount? get currentUser => account;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCalls++;
    return account;
  }

  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) async {
    silentSignInCalls++;
    return account;
  }

  @override
  Future<bool> requestScopes(List<String> scopes) async {
    requestedScopes = scopes;
    return granted;
  }

  @override
  Future<GoogleSignInAccount?> disconnect() async {
    disconnectCalls++;
    return account;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleAccount implements GoogleSignInAccount {
  @override
  String get id => 'selected-google-account';

  @override
  String get email => 'person@example.com';

  @override
  String get displayName => 'Test Person';

  @override
  String? get photoUrl => null;

  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disconnected Calendar fails with an actionable typed result', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = GoogleCalendarService(
      authService: AuthService(auth: _UnauthenticatedFirebaseAuth()),
      preferences: preferences,
    );

    await expectLater(
      service.getEventsForRange(
        DateTime.utc(2026, 11, 16, 23),
        DateTime.utc(2026, 11, 17, 23),
      ),
      throwsA(
        isA<GoogleCalendarException>().having(
          (error) => error.failure,
          'failure',
          GoogleCalendarFailure.disconnected,
        ),
      ),
    );
  });

  test('Calendar connects with incremental scopes on the selected account',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final googleSignIn = _FakeGoogleSignIn(account: _FakeGoogleAccount());
    final authService = AuthService(
      auth: _UnauthenticatedFirebaseAuth(),
      googleSignIn: googleSignIn,
    );
    final calendarService = GoogleCalendarService(
      authService: authService,
      preferences: preferences,
    );

    expect(await calendarService.connect(), isTrue);
    expect(googleSignIn.signInCalls, 0);
    expect(googleSignIn.silentSignInCalls, 0);
    expect(googleSignIn.requestedScopes, AuthService.calendarScopes);
    expect(await calendarService.isConnected, isTrue);

    await calendarService.disconnect();
    expect(await calendarService.isConnected, isFalse);
    expect(googleSignIn.disconnectCalls, 1);
  });

  test('declined Calendar scope leaves connection disabled', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final googleSignIn = _FakeGoogleSignIn(
      account: _FakeGoogleAccount(),
      granted: false,
    );
    final calendarService = GoogleCalendarService(
      authService: AuthService(
        auth: _UnauthenticatedFirebaseAuth(),
        googleSignIn: googleSignIn,
      ),
      preferences: preferences,
    );

    await expectLater(
      calendarService.connect(),
      throwsA(isA<GoogleCalendarException>().having(
        (error) => error.failure,
        'failure',
        GoogleCalendarFailure.permissionDenied,
      )),
    );
    expect(await calendarService.isConnected, isFalse);
  });

  test('revoked Google session clears the Calendar connection state', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final googleSignIn = _FakeGoogleSignIn(account: _FakeGoogleAccount());
    final calendarService = GoogleCalendarService(
      authService: AuthService(
        auth: _UnauthenticatedFirebaseAuth(),
        googleSignIn: googleSignIn,
      ),
      preferences: preferences,
    );
    await calendarService.connect();
    googleSignIn.account = null;

    await expectLater(
      calendarService.getEventsForRange(
        DateTime.utc(2026, 11, 16, 23),
        DateTime.utc(2026, 11, 17, 23),
      ),
      throwsA(isA<GoogleCalendarException>().having(
        (error) => error.failure,
        'failure',
        GoogleCalendarFailure.reauthorizationRequired,
      )),
    );
    expect(await calendarService.isConnected, isFalse);
  });
}
