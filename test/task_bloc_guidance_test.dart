import 'package:flutter_test/flutter_test.dart';
import 'package:notario/core/config/app_timezone.dart';
import 'package:notario/core/services/notification_service.dart';
import 'package:notario/features/tasks/data/repositories/task_repository.dart';
import 'package:notario/features/tasks/domain/entities/task.dart';
import 'package:notario/features/tasks/presentation/bloc/task_bloc.dart';

class _MemoryTaskRepository extends TaskRepository {
  final List<Task> tasks;

  _MemoryTaskRepository(this.tasks);

  @override
  Future<List<Task>> getByDate(String userId, DateTime date) async => tasks
      .where((task) => AppTimeZone.dayStart(task.dataInicio)
          .isAtSameMomentAs(AppTimeZone.dayStart(date)))
      .toList();

  @override
  Future<List<Task>> getByUserId(String userId) async => tasks;

  @override
  Future<void> completeTask(String id, int actualMinutes) async {
    final index = tasks.indexWhere((task) => task.id == id);
    tasks[index] = tasks[index].copyWith(
      estado: EstadoTarefa.concluida,
      tempoRealMinutos: actualMinutes,
    );
  }
}

Task _task({
  required String id,
  required DateTime start,
  int duration = 60,
  DateTime? deadline,
  EstadoTarefa state = EstadoTarefa.pendente,
}) {
  final now = AppTimeZone.now().toUtc();
  return Task(
    id: id,
    userId: 'user',
    titulo: id,
    dataInicio: start,
    dataFim: start.add(Duration(minutes: duration)),
    duracaoMinutos: duration,
    prioridade: Prioridade.alta,
    criadoEm: now,
    atualizadoEm: now,
    deadline: deadline,
    estado: state,
  );
}

void main() {
  setUp(AppTimeZone.initialize);

  test('completing the planned item refreshes day guidance from local data',
      () async {
    final now = AppTimeZone.now();
    final today = AppTimeZone.dayStart(now);
    final localTasks = <Task>[
      _task(id: 'planned', start: AppTimeZone.at(today, 8, 0), duration: 120),
      _task(
        id: 'candidate',
        start: AppTimeZone.at(today.add(const Duration(days: 1)), 9, 0),
        duration: 30,
        deadline: AppTimeZone.at(today.add(const Duration(days: 1)), 12, 0),
      ),
    ];
    final bloc = TaskBloc(
      repository: _MemoryTaskRepository(localTasks),
      notificationService: NotificationService(),
    );
    addTearDown(bloc.close);

    final firstLoaded = bloc.stream
        .firstWhere((state) => state is TaskDayLoaded)
        .then((state) => state as TaskDayLoaded);
    bloc.add(TaskDayLoadRequested('user', today));
    expect((await firstLoaded).guidance.planComplete, isFalse);

    final operation = bloc.stream.firstWhere(
      (state) => state is TaskOperationSuccess,
    );
    bloc.add(const TaskCompleteRequested('planned', 30));
    await operation;

    final refreshed = bloc.stream
        .firstWhere((state) => state is TaskDayLoaded)
        .then((state) => state as TaskDayLoaded);
    bloc.add(TaskDayLoadRequested('user', today));
    final state = await refreshed;
    expect(state.guidance.planComplete, isTrue);
    expect(state.guidance.freeMinutes, 810);
    expect(state.guidance.suggestions.single.task.id, 'candidate');
  });
}
