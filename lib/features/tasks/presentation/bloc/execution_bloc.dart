import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../../../core/services/notification_service.dart';

// Events
abstract class ExecutionEvent extends Equatable {
  const ExecutionEvent();

  @override
  List<Object?> get props => [];
}

class ExecutionStarted extends ExecutionEvent {
  final Task task;

  const ExecutionStarted(this.task);

  @override
  List<Object?> get props => [task];
}

class ExecutionPaused extends ExecutionEvent {}

class ExecutionResumed extends ExecutionEvent {}

class ExecutionStopped extends ExecutionEvent {}

class ExecutionSkipped extends ExecutionEvent {}

class ExecutionCancelled extends ExecutionEvent {}

class ExecutionFinished extends ExecutionEvent {}

class _ExecutionTicked extends ExecutionEvent {
  final int elapsedSeconds;

  const _ExecutionTicked(this.elapsedSeconds);

  @override
  List<Object?> get props => [elapsedSeconds];
}

// States
abstract class ExecutionState extends Equatable {
  final Task? task;
  final int elapsedSeconds;

  const ExecutionState({this.task, this.elapsedSeconds = 0});

  @override
  List<Object?> get props => [task, elapsedSeconds];

  int get durationMinutes => task?.duracaoMinutos ?? 0;
  int get remainingSeconds {
    if (task == null) return 0;
    final totalSeconds = (task!.duracaoMinutos) * 60;
    return totalSeconds - elapsedSeconds;
  }
}

class ExecutionInitial extends ExecutionState {
  const ExecutionInitial();
}

class ExecutionRunning extends ExecutionState {
  const ExecutionRunning(
      {required Task super.task, required super.elapsedSeconds});
}

class ExecutionPausedState extends ExecutionState {
  const ExecutionPausedState(
      {required Task super.task, required super.elapsedSeconds});
}

class ExecutionCompleted extends ExecutionState {
  final int totalTimeSpentMinutes;

  const ExecutionCompleted({
    required Task super.task,
    required super.elapsedSeconds,
    required this.totalTimeSpentMinutes,
  });

  @override
  List<Object?> get props => [task, elapsedSeconds, totalTimeSpentMinutes];
}

// BLoC
class ExecutionBloc extends Bloc<ExecutionEvent, ExecutionState> {
  final TaskRepository _repository;
  final NotificationService _notificationService;

  Timer? _timer;

  ExecutionBloc({
    required TaskRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService,
        super(const ExecutionInitial()) {
    on<ExecutionStarted>(_onStarted);
    on<ExecutionPaused>(_onPaused);
    on<ExecutionResumed>(_onResumed);
    on<ExecutionStopped>(_onStopped);
    on<ExecutionSkipped>(_onSkipped);
    on<ExecutionCancelled>(_onCancelled);
    on<ExecutionFinished>(_onFinished);
    on<_ExecutionTicked>(_onTicked);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _onStarted(ExecutionStarted event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();

    // Atualizar estado da tarefa no banco
    try {
      await _repository.startTask(event.task.id);
      // Cancelar notificação de início se existir
      await _notificationService.cancelNotification(event.task.id);
    } catch (e) {
      // Log erro?
    }

    emit(ExecutionRunning(task: event.task, elapsedSeconds: 0));
    _startTicker();
  }

  void _onPaused(ExecutionPaused event, Emitter<ExecutionState> emit) {
    if (state is ExecutionRunning) {
      _timer?.cancel();
      emit(ExecutionPausedState(
          task: state.task!, elapsedSeconds: state.elapsedSeconds));
    }
  }

  void _onResumed(ExecutionResumed event, Emitter<ExecutionState> emit) {
    if (state is ExecutionPausedState) {
      emit(ExecutionRunning(
          task: state.task!, elapsedSeconds: state.elapsedSeconds));
      _startTicker();
    }
  }

  void _onStopped(ExecutionStopped event, Emitter<ExecutionState> emit) {
    _timer?.cancel();
    emit(const ExecutionInitial());
  }

  void _onSkipped(ExecutionSkipped event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();
    final task = state.task;
    if (task != null) {
      await _repository.skipTask(task.id);
    }
    emit(const ExecutionInitial());
  }

  void _onCancelled(
      ExecutionCancelled event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();
    final task = state.task;
    if (task != null) {
      await _repository.cancelTask(task.id);
    }
    emit(const ExecutionInitial());
  }

  void _onFinished(
      ExecutionFinished event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();

    final task = state.task;
    if (task == null) return;

    final totalMinutes = (state.elapsedSeconds / 60).ceil();

    try {
      await _repository.completeTask(task.id, totalMinutes);
    } catch (e) {
      // Log erro
    }

    emit(ExecutionCompleted(
      task: task,
      elapsedSeconds: state.elapsedSeconds,
      totalTimeSpentMinutes: totalMinutes,
    ));

    // Emitir notificação de sucesso??
  }

  void _onTicked(_ExecutionTicked event, Emitter<ExecutionState> emit) {
    if (state.task == null) return;

    emit(ExecutionRunning(
      task: state.task!,
      elapsedSeconds: event.elapsedSeconds,
    ));

    // Verificar se o tempo acabou
    final totalSeconds = (state.task!.duracaoMinutos) * 60;
    if (event.elapsedSeconds == totalSeconds) {
      _notificationService.showImmediateNotification(
        title: "Tempo Esgotado! ⏰",
        body:
            "O tempo para '${state.task!.titulo}' acabou. Deseja concluir ou continuar?",
        payload: "execution:${state.task!.id}",
      );
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(_ExecutionTicked(state.elapsedSeconds + 1));
    });
  }
}
