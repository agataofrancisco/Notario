import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthBloc({
    required ApiService apiService,
    required SharedPreferences prefs,
  })  : _apiService = apiService,
        _prefs = prefs,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Verificar se existe token salvo
      final token = _prefs.getString(AppConfig.tokenCacheKey);
      final userJson = _prefs.getString(AppConfig.userCacheKey);

      if (token != null && userJson != null) {
        // Tentar obter dados atualizados do servidor
        try {
          final userData = await _apiService.getMe();
          final user = User.fromJson(userData);

          // Atualizar cache
          await _prefs.setString(
            AppConfig.userCacheKey,
            jsonEncode(user.toJson()),
          );

          emit(AuthAuthenticated(user: user, token: token));
        } catch (e) {
          // Se falhar, usar dados do cache
          final user = User.fromJson(jsonDecode(userJson));
          emit(AuthAuthenticated(user: user, token: token));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Autenticação real com Google
      final response = await _apiService.loginWithGoogle(
        idToken: event.idToken,
        accessToken: event.accessToken,
      );

      final user = User.fromJson(response['user']);
      final token = response['jwt_token'];

      // Salvar no cache
      await _prefs.setString(AppConfig.tokenCacheKey, token);
      await _prefs.setString(
        AppConfig.userCacheKey,
        jsonEncode(user.toJson()),
      );

      emit(AuthAuthenticated(user: user, token: token));
    } catch (e) {
      emit(AuthError('Erro ao fazer login: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Limpar cache
      await _prefs.remove(AppConfig.tokenCacheKey);
      await _prefs.remove(AppConfig.userCacheKey);

      // TODO: Limpar base de dados local

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Erro ao fazer logout: ${e.toString()}'));
    }
  }
}
