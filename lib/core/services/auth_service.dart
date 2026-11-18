import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../domain/entities/app_user.dart';

class AuthService {
  static const _identityScopes = <String>['email'];
  static const calendarScopes = <String>[
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/tasks.readonly',
    'https://www.googleapis.com/auth/calendar.events',
    'https://www.googleapis.com/auth/tasks',
  ];
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: _identityScopes,
              serverClientId: AppConfig.googleServerClientId.isEmpty
                  ? null
                  : AppConfig.googleServerClientId,
            );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Reuse the same Google session for incremental Calendar/Tasks scopes.
  GoogleSignIn get googleSignIn => _googleSignIn;

  /// Requests the Calendar/Tasks scopes only after the user chooses Connect.
  /// The active Google account is reused whenever the session is available.
  Future<bool> requestCalendarAccess() async {
    final account = _googleSignIn.currentUser ??
        await _googleSignIn.signInSilently() ??
        await _googleSignIn.signIn();
    if (account == null) return false;
    return _googleSignIn.requestScopes(calendarScopes);
  }

  Future<void> disconnectGoogleAccess() async {
    await _googleSignIn.disconnect();
  }

  /// Short-lived Google ID token used only to authenticate against the
  /// progress backend. It is never persisted in SQLite or sent to Calendar.
  Future<String?> googleIdToken() async {
    final user = _googleSignIn.currentUser;
    if (user == null) return null;
    return (await user.authentication).idToken;
  }

  /// Firebase is the only source of truth for an authenticated app session.
  AppUser? get currentUser => _auth.currentUser == null
      ? null
      : AppUser.fromFirebase(_auth.currentUser!);

  /// Stream de mudanças de autenticação da sessão Firebase.
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map(
          (user) => user == null ? null : AppUser.fromFirebase(user),
        );
  }

  // Login com Email e Senha
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return AppUser.fromFirebase(credential.user!);
  }

  // Registrar com Email e Senha
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Atualizar o nome do usuário
    await userCredential.user?.updateDisplayName(displayName);
    await userCredential.user?.reload();

    return AppUser.fromFirebase(_auth.currentUser!); // Reloaded user
  }

  /// Returns null when the account picker is cancelled.
  Future<AppUser?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Não foi possível obter a credencial de identidade Google.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'O Firebase não devolveu um utilizador autenticado.',
      );
    }
    return AppUser.fromFirebase(user);
  }

  // Reset de senha
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
