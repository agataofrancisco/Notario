import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/entities/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _googleScopes = <String>[
    'email',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/tasks.readonly',
  ];
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _googleScopes);

  /// Reuse the same Google session for incremental Calendar/Tasks scopes.
  GoogleSignIn get googleSignIn => _googleSignIn;

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
