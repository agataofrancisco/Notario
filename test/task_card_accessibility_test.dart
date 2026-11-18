import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notario/core/config/app_timezone.dart';
import 'package:notario/core/services/notification_service.dart';
import 'package:notario/features/tasks/data/repositories/task_repository.dart';
import 'package:notario/features/tasks/domain/entities/task.dart';
import 'package:notario/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:notario/features/tasks/presentation/screens/task_form_screen.dart';
import 'package:notario/features/tasks/presentation/widgets/task_list_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notario/features/dashboard/presentation/widgets/empty_state.dart';

void main() {
  setUp(AppTimeZone.initialize);

  testWidgets('deadline and offline sync state are readable on a compact card',
      (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final now = AppTimeZone.now();
    final task = Task(
      id: 'task-1',
      userId: 'user-1',
      titulo: 'Rever contrato',
      dataInicio: now.add(const Duration(minutes: 90)),
      dataFim: now.add(const Duration(minutes: 120)),
      duracaoMinutos: 30,
      prioridade: Prioridade.alta,
      criadoEm: now.toUtc(),
      atualizadoEm: now.toUtc(),
      deadline: now.add(const Duration(minutes: 60)),
      syncStatus: SyncStatus.pending,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TaskListItem(task: task)),
    ));

    expect(
        find.text(
            'Prazo hoje, às ${_time(now.add(const Duration(minutes: 60)))}'),
        findsOneWidget);
    expect(find.text('Sincronização pendente'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Prazo: Prazo hoje')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
          RegExp('Alteração guardada no dispositivo; sincronização pendente')),
      findsOneWidget,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty agenda state stays scrollable in a short viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(height: 99, child: EmptyState()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma tarefa para hoje!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'task form rejects an invalid deadline and clears it on compact UI',
      (tester) async {
    await initializeDateFormatting('pt_PT', null);
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final start = AppTimeZone.at(DateTime(2026, 11, 18), 9, 0);
    final task = Task(
      id: 'task-with-deadline',
      userId: 'user-1',
      titulo: 'Rever contrato',
      dataInicio: start,
      dataFim: start.add(const Duration(minutes: 60)),
      duracaoMinutos: 60,
      prioridade: Prioridade.alta,
      criadoEm: start.toUtc(),
      atualizadoEm: start.toUtc(),
      deadline: AppTimeZone.at(DateTime(2026, 11, 18), 9, 30),
    );
    final bloc = TaskBloc(
      repository: TaskRepository(),
      notificationService: NotificationService(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(home: TaskFormScreen(task: task)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('18/11/2026 às 09:30'), findsOneWidget);
    await tester.ensureVisible(find.text('Salvar Alterações'));
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pumpAndSettle();
    expect(
      find.text('O prazo tem de ser igual ou posterior ao fim planeado.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byTooltip('Limpar prazo'));
    await tester.tap(find.byTooltip('Limpar prazo'));
    await tester.pumpAndSettle();

    expect(find.text('Definir prazo'), findsOneWidget);
    expect(find.byTooltip('Limpar prazo'), findsNothing);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar Alterações'));
    await tester.pumpAndSettle();
    expect(
        tester.getRect(find.text('Salvar Alterações')).bottom, lessThan(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('new task form lets the user set a valid deadline',
      (tester) async {
    await initializeDateFormatting('pt_PT', null);
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = TaskBloc(
      repository: TaskRepository(),
      notificationService: NotificationService(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: const MaterialApp(home: TaskFormScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Definir prazo'));
    await tester.tap(find.text('Definir prazo'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.ensureVisible(find.text('OK'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.ensureVisible(find.text('OK'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Limpar prazo'), findsOneWidget);
    expect(find.text('Definir prazo'), findsNothing);
    expect(
      find.text('O prazo tem de ser igual ou posterior ao fim planeado.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
