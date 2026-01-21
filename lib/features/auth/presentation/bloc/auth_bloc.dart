import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/auth_service.dart';
import './auth_event.dart';
import './auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final SharedPreferences _prefs;

  AuthBloc({
    required AuthService authService,
    required SharedPreferences prefs,
  })  : _authService = authService,
        _prefs = prefs,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthEmailLoginRequested>(_onEmailLoginRequested);
    on<AuthEmailRegisterRequested>(_onEmailRegisterRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Erro ao verificar autenticação: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user =
          await _authService.signInWithGoogle(clientId: event.clientId);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError('Erro ao fazer login com Google: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onEmailLoginRequested(
    AuthEmailLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuário não encontrado. Verifique o email.';
          break;
        case 'wrong-password':
          message = 'Senha incorreta. Tente novamente.';
          break;
        case 'invalid-email':
          message = 'Email inválido.';
          break;
        case 'user-disabled':
          message = 'Esta conta foi desativada.';
          break;
        default:
          message = 'Erro ao fazer login: ${e.message}';
      }
      emit(AuthError(message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Erro ao fazer login: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onEmailRegisterRequested(
    AuthEmailRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.registerWithEmail(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Este email já está em uso. Tente fazer login.';
          break;
        case 'invalid-email':
          message = 'Email inválido.';
          break;
        case 'weak-password':
          message = 'Senha muito fraca. Use pelo menos 6 caracteres.';
          break;
        default:
          message = 'Erro ao registrar: ${e.message}';
      }
      emit(AuthError(message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Erro ao registrar: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.resetPassword(event.email);
      emit(AuthPasswordResetSent());
      emit(AuthUnauthenticated());
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuário não encontrado com este email.';
          break;
        case 'invalid-email':
          message = 'Email inválido.';
          break;
        default:
          message = 'Erro ao enviar email: ${e.message}';
      }
      emit(AuthError(message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Erro ao enviar email de reset: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      await _prefs.clear();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Erro ao fazer logout: ${e.toString()}'));
    }
  }
}
