import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/auth_service.dart';
import 'core/services/google_calendar_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/statistics_service.dart';
import 'core/services/weekly_notification_service.dart';
import 'core/repositories/task_firestore_repository.dart';

import 'core/config/app_config.dart';
import 'core/services/sync_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/dashboard/presentation/bloc/stats_bloc.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/data/repositories/task_repository.dart';
import 'shared/theme/app_theme.dart';
import 'features/notes/presentation/bloc/note_bloc.dart';
import 'features/notes/data/repositories/note_repository.dart';
import 'features/notes/presentation/screens/note_list_screen.dart';
import 'features/tasks/presentation/screens/task_list_screen.dart';
import 'features/tasks/presentation/screens/execution_screen.dart';

class NotarioApp extends StatelessWidget {
  final SharedPreferences prefs;

  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  const NotarioApp({
    super.key,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    // Registrar callback para navegação via notificação (payload)
    // Mantemos simples: usa rotas nomeadas, sem router adicional.
    final notificationService = NotificationService();
    notificationService.setOnPayloadTap((payload) async {
      final nav = _navigatorKey.currentState;
      if (nav == null) return;

      if (payload.startsWith('task:')) {
        nav.push(MaterialPageRoute(builder: (_) => const TaskListScreen()));
        return;
      }
      if (payload.startsWith('note:')) {
        nav.push(MaterialPageRoute(builder: (_) => const NoteListScreen()));
        return;
      }
      if (payload.startsWith('execution:')) {
        final taskId = payload.substring('execution:'.length);
        final repo = getItMaybeRead<TaskFirestoreRepository>(nav.context);
        if (repo == null) {
          nav.pushNamed('/tasks');
          return;
        }
        final task = await repo.getById(taskId);
        if (task == null) {
          nav.pushNamed('/tasks');
          return;
        }
        nav.push(
          MaterialPageRoute(builder: (_) => ExecutionScreen(task: task)),
        );
        return;
      }
    });

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
        RepositoryProvider<WeeklyNotificationService>(
          create: (context) => WeeklyNotificationService(),
        ),
        RepositoryProvider<TaskFirestoreRepository>(
          create: (context) => TaskFirestoreRepository(),
        ),
        RepositoryProvider<TaskRepository>(
          create: (context) => TaskRepository(),
        ),
        RepositoryProvider<NoteRepository>(
          create: (context) => NoteRepository(),
        ),
        RepositoryProvider<StatisticsService>(
          create: (context) =>
              StatisticsService(context.read<TaskRepository>()),
        ),
        RepositoryProvider<SyncService>(
          create: (context) => SyncService(
            taskRepository: context.read<TaskFirestoreRepository>(),
            calendarService: context.read<GoogleCalendarService>(),
          ),
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
              enableGoogleCalendar: AppConfig.enableGoogleCalendar,
            ),
          ),
          BlocProvider<StatsBloc>(
            create: (context) => StatsBloc(
              statisticsService: context.read<StatisticsService>(),
            ),
          ),
          BlocProvider<NoteBloc>(
            create: (context) => NoteBloc(
              repository: context.read<NoteRepository>(),
              notificationService: context.read<NotificationService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'NOTÁRIO',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
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
                // Inicializar notificações semanais quando usuário estiver autenticado
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final weeklyService =
                      context.read<WeeklyNotificationService>();
                  await weeklyService.initialize(state.user.uid);
                  await weeklyService
                      .checkAndSendMissedNotifications(state.user.uid);

                  if (!context.mounted) return;
                  context.read<SyncService>().startPeriodicSync();
                });

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

T? getItMaybeRead<T>(BuildContext context) {
  try {
    return RepositoryProvider.of<T>(context);
  } catch (_) {
    return null;
  }
}
