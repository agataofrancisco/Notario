import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notario/core/config/app_timezone.dart';
import 'package:notario/core/services/auth_service.dart';
import 'package:notario/core/services/google_calendar_service.dart';
import 'package:notario/core/services/notification_service.dart';
import 'package:notario/core/services/statistics_service.dart';
import 'package:notario/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:notario/features/auth/presentation/bloc/auth_event.dart';
import 'package:notario/features/auth/presentation/bloc/auth_state.dart';
import 'package:notario/features/dashboard/presentation/bloc/stats_bloc.dart';
import 'package:notario/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:notario/features/tasks/data/repositories/task_repository.dart';
import 'package:notario/features/tasks/domain/entities/task.dart';
import 'package:notario/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInUser implements User {
  @override
  String get uid => 'user-1';

  @override
  String? get email => 'user@example.com';

  @override
  String? get displayName => 'Test User';

  @override
  String? get photoURL => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SignedInFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => _SignedInUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AgendaRepository extends TaskRepository {
  final List<Task> tasks;
  bool failLoading = false;

  _AgendaRepository(this.tasks);

  @override
  Future<List<Task>> getByDate(String userId, DateTime date) async {
    if (failLoading) throw Exception('offline');
    return tasks
        .where((task) => AppTimeZone.dayStart(task.dataInicio)
            .isAtSameMomentAs(AppTimeZone.dayStart(date)))
        .toList();
  }

  @override
  Future<List<Task>> getByUserId(String userId) async => tasks;
}

void main() {
  setUp(() async {
    AppTimeZone.initialize();
    await initializeDateFormatting('pt_PT', null);
  });

  testWidgets(
      'guidance actions require confirmation and dismiss without changing tasks',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final now = AppTimeZone.now();
    final today = AppTimeZone.dayStart(now);
    final planned = Task(
      id: 'planned',
      userId: 'user-1',
      titulo: 'Plano concluído',
      dataInicio: AppTimeZone.at(today, 8, 0),
      dataFim: AppTimeZone.at(today, 9, 0),
      duracaoMinutos: 60,
      prioridade: Prioridade.media,
      criadoEm: now.toUtc(),
      atualizadoEm: now.toUtc(),
      estado: EstadoTarefa.concluida,
      tempoRealMinutos: 45,
    );
    final suggestion = Task(
      id: 'suggestion',
      userId: 'user-1',
      titulo: 'Preparar relatório',
      dataInicio: AppTimeZone.at(today.add(const Duration(days: 1)), 9, 0),
      dataFim: AppTimeZone.at(today.add(const Duration(days: 1)), 9, 30),
      duracaoMinutos: 30,
      prioridade: Prioridade.alta,
      criadoEm: now.toUtc(),
      atualizadoEm: now.toUtc(),
      deadline: AppTimeZone.at(today.add(const Duration(days: 1)), 12, 0),
    );
    final repository = _AgendaRepository([planned, suggestion]);
    final authBloc = AuthBloc(
      authService: AuthService(auth: _SignedInFirebaseAuth()),
      prefs: preferences,
    );
    final authenticated = authBloc.stream.firstWhere(
      (state) => state is AuthAuthenticated,
    );
    authBloc.add(AuthCheckRequested());
    await authenticated;
    addTearDown(authBloc.close);

    final taskBloc = TaskBloc(
      repository: repository,
      notificationService: NotificationService(),
    );
    addTearDown(taskBloc.close);
    final statsBloc = StatsBloc(
      statisticsService: StatisticsService(repository),
    );
    addTearDown(statsBloc.close);
    final calendarService = GoogleCalendarService(
      authService: AuthService(auth: _SignedInFirebaseAuth()),
      preferences: preferences,
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: taskBloc),
          BlocProvider.value(value: statsBloc),
          RepositoryProvider.value(value: calendarService),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    expect(find.text('Google Calendar desligado'), findsOneWidget);
    expect(find.text('Ligar'), findsOneWidget);
    expect(find.text('Nenhuma tarefa para hoje!'), findsNothing);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar esta tarefa?'), findsOneWidget);
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(suggestion.estado, EstadoTarefa.pendente);

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();
    expect(find.text('Reagendar tarefa?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(suggestion.estado, EstadoTarefa.pendente);

    await tester.tap(find.text('Dispensar'));
    await tester.pumpAndSettle();
    expect(find.text('Preparar relatório'), findsNothing);
    expect(suggestion.estado, EstadoTarefa.pendente);
    expect(suggestion.dataInicio,
        AppTimeZone.at(today.add(const Duration(days: 1)), 9, 0));
    expect(tester.takeException(), isNull);

    repository.tasks.remove(suggestion);
    final emptyAgenda =
        taskBloc.stream.firstWhere((state) => state is TaskDayLoaded);
    taskBloc.add(TaskDayLoadRequested('user-1', today));
    await emptyAgenda;
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Não há tarefas com prazo que caibam no tempo livre de hoje.'),
        findsOneWidget);

    repository.failLoading = true;
    final failedAgenda =
        taskBloc.stream.firstWhere((state) => state is TaskError);
    taskBloc.add(TaskDayLoadRequested('user-1', today));
    await failedAgenda;
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar o dia'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
