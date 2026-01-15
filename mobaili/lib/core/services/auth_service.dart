import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../../features/auth/domain/entities/user.dart' as domain;

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream de estado de autenticação
  Stream<domain.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToDomain(firebaseUser);
    });
  }

  // Utilizador atual
  domain.User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUserToDomain(firebaseUser);
  }

  // Login com Google
  Future<domain.User> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Login cancelado pelo utilizador');
      }

      // 2. Obter credenciais de autenticação
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Criar credencial Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Login no Firebase
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // 5. Retornar utilizador
      return _mapFirebaseUserToDomain(userCredential.user!);
    } catch (e) {
      throw Exception('Erro ao fazer login com Google: $e');
    }
  }

  // Logout
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Obter token Firebase (para enviar ao backend)
  Future<String?> getIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  // Refresh token
  Future<String?> refreshToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(true); // Force refresh
  }

  // Mapear FirebaseUser para domain User
  domain.User _mapFirebaseUserToDomain(firebase_auth.User firebaseUser) {
    return domain.User(
      id: firebaseUser.uid,
      googleId: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      nome: firebaseUser.displayName ?? 'Utilizador',
      fotoUrl: firebaseUser.photoURL,
      timezone: 'Europe/Lisbon',
      criadoEm: firebaseUser.metadata.creationTime ?? DateTime.now(),
      atualizadoEm: DateTime.now(),
    );
  }
}
