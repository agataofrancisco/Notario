import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/auth_service.dart';
import './auth_event.dart';
import './auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final AuthService _authService;
  final SharedPreferences _prefs;

  AuthBloc({
    required ApiService apiService,
    required AuthService authService,
    required SharedPreferences prefs,
  })  : _apiService = apiService,
        _authService = authService,
        _prefs = prefs,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Opcional: verificar se o token ainda é válido ou refrescar dados
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Erro ao verificar autenticação: ${e.toString()}'));
    }
  }

  Future<void> _onGoogleLoginRequested(AuthGoogleLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signInWithGoogle(event.idToken, event.accessToken);
      if (user != null) {
        // Opcional: Aqui você pode chamar o _apiService para enviar o token para o seu backend
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Login com Google falhou. Tente novamente.'));
      }
    } catch (e) {
      emit(AuthError(message: 'Ocorreu um erro durante o login: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      // Limpar SharedPreferences se necessário
      await _prefs.clear();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Erro ao fazer logout: ${e.toString()}'));
    }
  }
}
