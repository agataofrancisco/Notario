import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notario/core/domain/entities/app_user.dart';
import 'package:notario/core/services/auth_service.dart';
import 'package:notario/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:notario/features/auth/presentation/bloc/auth_event.dart';
import 'package:notario/features/auth/presentation/bloc/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnauthenticatedFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(auth: _UnauthenticatedFirebaseAuth());

  AppUser? nextUser;

  @override
  Future<AppUser?> signInWithGoogle() async => nextUser;
}

class _CapturingFirebaseAuth implements FirebaseAuth {
  AuthCredential? credential;

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential value) async {
    credential = value;
    return _FakeUserCredential(_FakeFirebaseUser());
  }

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  _FakeUserCredential(this.user);

  @override
  final User user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseUser implements User {
  @override
  String get uid => 'firebase-account-id';

  @override
  String? get email => 'person@example.com';

  @override
  String? get displayName => 'Test Person';

  @override
  String? get photoURL => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleSignIn implements GoogleSignIn {
  _FakeGoogleSignIn(this.account);

  final GoogleSignInAccount account;

  @override
  Future<GoogleSignInAccount?> signIn() async => account;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleAccount implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _FakeGoogleAuthentication();

  @override
  String get id => 'google-account-id';

  @override
  String get email => 'person@example.com';

  @override
  String get displayName => 'Test Person';

  @override
  String? get photoUrl => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleAuthentication implements GoogleSignInAuthentication {
  @override
  String? get idToken => 'google-id-token';

  @override
  String? get accessToken => 'google-access-token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cancelled Google sign-in returns to unauthenticated state', () async {
    final authService = _FakeAuthService();
    final bloc = AuthBloc(
      authService: authService,
      prefs: await SharedPreferences.getInstance(),
    );
    addTearDown(bloc.close);
    final unauthenticated = bloc.stream.firstWhere(
      (state) => state is AuthUnauthenticated,
    );

    bloc.add(const AuthGoogleLoginRequested());

    expect(await unauthenticated, isA<AuthUnauthenticated>());
    expect(bloc.state, isA<AuthUnauthenticated>());
  });

  test('completed Google sign-in exposes the Firebase application user',
      () async {
    final authService = _FakeAuthService()
      ..nextUser =
          const AppUser(uid: 'firebase-user', email: 'test@example.com');
    final bloc = AuthBloc(
      authService: authService,
      prefs: await SharedPreferences.getInstance(),
    );
    addTearDown(bloc.close);
    final authenticated = bloc.stream.firstWhere(
      (state) => state is AuthAuthenticated,
    );

    bloc.add(const AuthGoogleLoginRequested());

    final state = await authenticated as AuthAuthenticated;
    expect(state.user.uid, 'firebase-user');
  });

  test('Google tokens are exchanged for a Firebase Google credential',
      () async {
    final firebase = _CapturingFirebaseAuth();
    final service = AuthService(
      auth: firebase,
      googleSignIn: _FakeGoogleSignIn(_FakeGoogleAccount()),
    );

    final user = await service.signInWithGoogle();

    expect(user?.uid, 'firebase-account-id');
    expect(firebase.credential, isA<OAuthCredential>());
    final credential = firebase.credential! as OAuthCredential;
    expect(credential.providerId, GoogleAuthProvider.PROVIDER_ID);
    expect(credential.idToken, 'google-id-token');
    expect(credential.accessToken, 'google-access-token');
  });
}
