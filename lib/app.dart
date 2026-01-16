import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart'; // Importa o AuthService
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'shared/theme/app_theme.dart';

class NotarioApp extends StatelessWidget {
  final SharedPreferences prefs;

  const NotarioApp({
    super.key,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Prover AuthService e ApiService para toda a aplicação
        RepositoryProvider<AuthService>(
          create: (context) => AuthService(),
        ),
        RepositoryProvider<ApiService>(
          create: (context) => ApiService(prefs),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              apiService: context.read<ApiService>(),
              authService: context.read<AuthService>(), // Injete o AuthService
              prefs: prefs,
            )..add(AuthCheckRequested()),
          ),
        ],
        child: MaterialApp(
          title: 'NOTÁRIO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading || state is AuthInitial) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is AuthAuthenticated) {
                return const DashboardScreen();
              }

              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
