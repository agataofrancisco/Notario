import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../domain/entities/app_user.dart';
import '../config/app_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      if (AppConfig.enableGoogleCalendar)
        'https://www.googleapis.com/auth/calendar',
    ],
  );

  // Cache para o usuário Google atual, já que não estamos usando o Firebase para persistência desse estado
  GoogleSignInAccount? _currentGoogleUser;

  // Expor o usuário atual (Unifica Firebase e Google)
  AppUser? get currentUser {
    if (_auth.currentUser != null) {
      return AppUser.fromFirebase(_auth.currentUser!);
    }
    if (_currentGoogleUser != null) {
      return AppUser.fromGoogle(_currentGoogleUser!);
    }
    return null;
  }

  // Stream de mudanças de autenticação
  // Nota: Isso monitora apenas o Firebase Auth. Para Google Sign-In direto,
  // gerenciamos o estado manualmente no Bloc ou via _googleSignIn.onCurrentUserChanged
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user != null) return AppUser.fromFirebase(user);
      if (_currentGoogleUser != null) {
        return AppUser.fromGoogle(_currentGoogleUser!);
      }
      return null;
    });
  }

  // Inicializar listeners (chamado na criação do Service se necessário)
  void init() {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentGoogleUser = account;
    });
    _googleSignIn.signInSilently();
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

  // Login com Google (Modificado para Client ID direto)
  Future<AppUser> signInWithGoogle({String? clientId}) async {
    // Se um clientId for fornecido, recriamos a instância do GoogleSignIn
    if (clientId != null) {
      _googleSignIn = GoogleSignIn(
        clientId: clientId,
        scopes: [
          'email',
          if (AppConfig.enableGoogleCalendar)
            'https://www.googleapis.com/auth/calendar',
        ],
      );
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Login cancelado pelo usuário.');
      }

      _currentGoogleUser = googleUser;
      return AppUser.fromGoogle(googleUser);
    } catch (e) {
      if (kDebugMode) print('Erro no login Google: $e');
      rethrow;
    }
  }

  // Reset de senha
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentGoogleUser = null;
  }
}
