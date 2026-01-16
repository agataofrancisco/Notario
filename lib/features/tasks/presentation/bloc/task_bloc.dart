import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';
import '../../../../core/repositories/task_firestore_repository.dart';

// Events
abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TaskLoadRequested extends TaskEvent {
  final String userId;

  const TaskLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class TaskDayLoadRequested extends TaskEvent {
  final String userId;
  final DateTime date;

  const TaskDayLoadRequested(this.userId, this.date);

  @override
  List<Object?> get props => [userId, date];
}

class TaskCreateRequested extends TaskEvent {
  final Task task;

  const TaskCreateRequested(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskUpdateRequested extends TaskEvent {
  final Task task;

  const TaskUpdateRequested(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskDeleteRequested extends TaskEvent {
  final String taskId;

  const TaskDeleteRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TaskStartRequested extends TaskEvent {
  final String taskId;

  const TaskStartRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TaskCompleteRequested extends TaskEvent {
  final String taskId;
  final int tempoRealMinutos;

  const TaskCompleteRequested(this.taskId, this.tempoRealMinutos);

  @override
  List<Object?> get props => [taskId, tempoRealMinutos];
}

class TaskSkipRequested extends TaskEvent {
  final String taskId;

  const TaskSkipRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TaskValidateDayRequested extends TaskEvent {
  final DateTime data;
  final int duracaoMinutos;
  final String prioridade;

  const TaskValidateDayRequested({
    required this.data,
    required this.duracaoMinutos,
    required this.prioridade,
  });

  @override
  List<Object?> get props => [data, duracaoMinutos, prioridade];
}

// States
abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;

  const TaskLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskDayLoaded extends TaskState {
  final List<Task> tasks;
  final DateTime date;

  const TaskDayLoaded(this.tasks, this.date);

  @override
  List<Object?> get props => [tasks, date];
}

class TaskOperationSuccess extends TaskState {
  final String message;

  const TaskOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskValidationResult extends TaskState {
  final bool viavel;
  final int tempoLivreMinutos;
  final String mensagem;
  final List<dynamic>? tarefasParaMover;
  final List<DateTime>? diasAlternativos;

  const TaskValidationResult({
    required this.viavel,
    required this.tempoLivreMinutos,
    required this.mensagem,
    this.tarefasParaMover,
    this.diasAlternativos,
  });

  @override
  List<Object?> get props => [
        viavel,
        tempoLivreMinutos,
        mensagem,
        tarefasParaMover,
        diasAlternativos,
      ];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskFirestoreRepository _repository;

  TaskBloc({required TaskFirestoreRepository repository})
      : _repository = repository,
        super(TaskInitial()) {
    on<TaskLoadRequested>(_onLoadRequested);
    on<TaskDayLoadRequested>(_onDayLoadRequested);
    on<TaskCreateRequested>(_onCreateRequested);
    on<TaskUpdateRequested>(_onUpdateRequested);
    on<TaskDeleteRequested>(_onDeleteRequested);
    on<TaskStartRequested>(_onStartRequested);
    on<TaskCompleteRequested>(_onCompleteRequested);
    on<TaskSkipRequested>(_onSkipRequested);
    on<TaskValidateDayRequested>(_onValidateDayRequested);
  }

  Future<void> _onLoadRequested(
    TaskLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      // Usar stream para atualizações em tempo real
      await emit.forEach(
        _repository.watchUserTasks(event.userId),
        onData: (tasks) => TaskLoaded(tasks),
        onError: (error, stackTrace) => TaskError(error.toString()),
      );
    } catch (e) {
      emit(TaskError('Erro ao carregar tarefas: ${e.toString()}'));
    }
  }

  Future<void> _onDayLoadRequested(
    TaskDayLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await emit.forEach(
        _repository.watchDayTasks(event.userId, event.date),
        onData: (tasks) => TaskDayLoaded(tasks, event.date),
        onError: (error, stackTrace) => TaskError(error.toString()),
      );
    } catch (e) {
      emit(TaskError('Erro ao carregar tarefas do dia: ${e.toString()}'));
    }
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.create(event.task);
      emit(const TaskOperationSuccess('Tarefa criada com sucesso!'));
    } catch (e) {
      emit(TaskError('Erro ao criar tarefa: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRequested(
    TaskUpdateRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.update(event.task);
      emit(const TaskOperationSuccess('Tarefa atualizada com sucesso!'));
    } catch (e) {
      emit(TaskError('Erro ao atualizar tarefa: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteRequested(
    TaskDeleteRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.delete(event.taskId);
      emit(const TaskOperationSuccess('Tarefa eliminada com sucesso!'));
    } catch (e) {
      emit(TaskError('Erro ao eliminar tarefa: ${e.toString()}'));
    }
  }

  Future<void> _onStartRequested(
    TaskStartRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.startTask(event.taskId);
      emit(const TaskOperationSuccess('Tarefa iniciada!'));
    } catch (e) {
      emit(TaskError('Erro ao iniciar tarefa: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteRequested(
    TaskCompleteRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.completeTask(event.taskId, event.tempoRealMinutos);
      emit(const TaskOperationSuccess('Tarefa concluída!'));
    } catch (e) {
      emit(TaskError('Erro ao concluir tarefa: ${e.toString()}'));
    }
  }

  Future<void> _onSkipRequested(
    TaskSkipRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.skipTask(event.taskId);
      emit(const TaskOperationSuccess('Tarefa pulada'));
    } catch (e) {
      emit(TaskError('Erro ao pular tarefa: ${e.toString()}'));
    }
  }

  Future<void> _onValidateDayRequested(
    TaskValidateDayRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final result = await _repository.validateDay(
        data: event.data,
        duracaoMinutos: event.duracaoMinutos,
        prioridade: event.prioridade,
      );

      emit(TaskValidationResult(
        viavel: result['viavel'] as bool,
        tempoLivreMinutos: result['tempoLivreMinutos'] as int,
        mensagem: result['mensagem'] as String,
        tarefasParaMover: result['tarefasParaMover'] as List<dynamic>?,
        diasAlternativos: (result['diasAlternativos'] as List<dynamic>?)
            ?.map((e) => DateTime.parse(e as String))
            .toList(),
      ));
    } catch (e) {
      emit(TaskError('Erro ao validar dia: ${e.toString()}'));
    }
  }
}
