import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/auth_service.dart';
import 'core/services/google_calendar_service.dart';
import 'core/services/notification_service.dart';
import 'core/repositories/task_firestore_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'shared/theme/app_theme.dart';
import 'features/notes/presentation/bloc/note_bloc.dart';
import 'features/notes/data/repositories/note_firestore_repository.dart';

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
        RepositoryProvider<AuthService>(
          create: (context) => AuthService(),
        ),
        RepositoryProvider<GoogleCalendarService>(
          create: (context) => GoogleCalendarService(),
        ),
        RepositoryProvider<NotificationService>(
          create: (context) => NotificationService(),
        ),
        RepositoryProvider<TaskFirestoreRepository>(
          create: (context) => TaskFirestoreRepository(),
        ),
        RepositoryProvider<NoteFirestoreRepository>(
          create: (context) => NoteFirestoreRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authService: context.read<AuthService>(),
              prefs: prefs,
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<TaskBloc>(
            create: (context) => TaskBloc(
              repository: context.read<TaskFirestoreRepository>(),
              googleCalendarService: context.read<GoogleCalendarService>(),
              notificationService: context.read<NotificationService>(),
            ),
          ),
          BlocProvider<NoteBloc>(
            create: (context) => NoteBloc(
              repository: context.read<NoteFirestoreRepository>(),
              notificationService: context.read<NotificationService>(),
            ),
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
