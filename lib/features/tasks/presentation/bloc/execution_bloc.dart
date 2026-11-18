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

class _PauseForExit extends ExecutionEvent {
  final Completer<void> completer;
  const _PauseForExit(this.completer);
}

class ExecutionResumed extends ExecutionEvent {}

class ExecutionStopped extends ExecutionEvent {}

class ExecutionSkipped extends ExecutionEvent {}

class ExecutionCancelled extends ExecutionEvent {}

class ExecutionRescheduled extends ExecutionEvent {
  final DateTime newDate;
  const ExecutionRescheduled(this.newDate);
  @override
  List<Object?> get props => [newDate];
}

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

class ExecutionFinishing extends ExecutionState {
  const ExecutionFinishing(
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
  int _baseElapsedSeconds = 0;
  DateTime? _runningSinceUtc;
  bool _timeExpiredNotified = false;

  ExecutionBloc({
    required TaskRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService,
        super(const ExecutionInitial()) {
    on<ExecutionStarted>(_onStarted);
    on<ExecutionPaused>(_onPaused);
    on<_PauseForExit>(_onPauseForExit);
    on<ExecutionResumed>(_onResumed);
    on<ExecutionStopped>(_onStopped);
    on<ExecutionSkipped>(_onSkipped);
    on<ExecutionCancelled>(_onCancelled);
    on<ExecutionRescheduled>(_onRescheduled);
    on<ExecutionFinished>(_onFinished);
    on<_ExecutionTicked>(_onTicked);
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    if (state is ExecutionRunning && state.task != null) {
      await _repository.pauseFocusSession(state.task!.id, _currentElapsed());
    }
    await super.close();
  }

  Future<void> _onStarted(
      ExecutionStarted event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();
    _timeExpiredNotified = false;

    // Atualizar estado da tarefa no banco
    try {
      await _repository.startTask(event.task.id);
      _baseElapsedSeconds = await _repository.startFocusSession(event.task.id);
      _runningSinceUtc = DateTime.now().toUtc();
      // Cancelar notificação de início se existir
      await _notificationService.cancelNotification(event.task.id);
    } catch (e) {
      // Log erro?
    }

    emit(ExecutionRunning(
        task: event.task, elapsedSeconds: _baseElapsedSeconds));
    _startTicker();
  }

  Future<void> _onPaused(
      ExecutionPaused event, Emitter<ExecutionState> emit) async {
    if (state is ExecutionRunning) {
      _timer?.cancel();
      final elapsed = _currentElapsed();
      _baseElapsedSeconds = elapsed;
      _runningSinceUtc = null;
      await _repository.pauseFocusSession(state.task!.id, elapsed);
      emit(ExecutionPausedState(task: state.task!, elapsedSeconds: elapsed));
    }
  }

  Future<void> pauseForExit() {
    final completer = Completer<void>();
    add(_PauseForExit(completer));
    return completer.future;
  }

  Future<void> _onPauseForExit(
      _PauseForExit event, Emitter<ExecutionState> emit) async {
    try {
      if (state is ExecutionRunning) {
        _timer?.cancel();
        final elapsed = _currentElapsed();
        _baseElapsedSeconds = elapsed;
        _runningSinceUtc = null;
        await _repository.pauseFocusSession(state.task!.id, elapsed);
        emit(ExecutionPausedState(task: state.task!, elapsedSeconds: elapsed));
      }
    } finally {
      if (!event.completer.isCompleted) event.completer.complete();
    }
  }

  Future<void> _onResumed(
      ExecutionResumed event, Emitter<ExecutionState> emit) async {
    if (state is ExecutionPausedState) {
      _baseElapsedSeconds = await _repository.startFocusSession(state.task!.id);
      _runningSinceUtc = DateTime.now().toUtc();
      emit(ExecutionRunning(
          task: state.task!, elapsedSeconds: _baseElapsedSeconds));
      _startTicker();
    }
  }

  Future<void> _onStopped(
      ExecutionStopped event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();
    final task = state.task;
    if (task != null && state is ExecutionRunning) {
      final elapsed = _currentElapsed();
      await _repository.pauseFocusSession(task.id, elapsed);
    }
    _runningSinceUtc = null;
    emit(const ExecutionInitial());
  }

  void _onSkipped(ExecutionSkipped event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();
    final task = state.task;
    if (task != null) {
      await _repository.clearFocusSession(task.id);
      await _repository.skipTask(task.id);
    }
    emit(const ExecutionInitial());
  }

  void _onRescheduled(
      ExecutionRescheduled event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();
    final task = state.task;
    if (task != null) {
      await _repository.clearFocusSession(task.id);
      await _repository.rescheduleTask(task.id, event.newDate);
    }
    emit(const ExecutionInitial());
  }

  void _onCancelled(
      ExecutionCancelled event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();
    final task = state.task;
    if (task != null) {
      await _repository.clearFocusSession(task.id);
      await _repository.cancelTask(task.id);
    }
    emit(const ExecutionInitial());
  }

  void _onFinished(
      ExecutionFinished event, Emitter<ExecutionState> emit) async {
    _timer?.cancel();

    final task = state.task;
    if (task == null) return;

    final elapsed =
        state is ExecutionRunning ? _currentElapsed() : state.elapsedSeconds;
    final totalMinutes = (elapsed / 60).ceil();

    emit(ExecutionFinishing(
      task: task,
      elapsedSeconds: elapsed,
    ));

    try {
      await _repository.completeTask(task.id, totalMinutes);
      await _repository.clearFocusSession(task.id);
    } catch (e) {
      // Log erro
    }

    emit(ExecutionCompleted(
      task: task,
      elapsedSeconds: elapsed,
      totalTimeSpentMinutes: totalMinutes,
    ));

    // Emitir notificação de sucesso??
  }

  void _onTicked(_ExecutionTicked event, Emitter<ExecutionState> emit) {
    if (state.task == null) return;

    emit(ExecutionRunning(
      task: state.task!,
      elapsedSeconds:
          state is ExecutionRunning ? _currentElapsed() : event.elapsedSeconds,
    ));

    // Verificar se o tempo acabou
    final totalSeconds = (state.task!.duracaoMinutos) * 60;
    if (event.elapsedSeconds >= totalSeconds && !_timeExpiredNotified) {
      _timeExpiredNotified = true;
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
      add(_ExecutionTicked(_currentElapsed()));
    });
  }

  int _currentElapsed() {
    final started = _runningSinceUtc;
    if (started == null) return _baseElapsedSeconds;
    return _baseElapsedSeconds +
        DateTime.now().toUtc().difference(started).inSeconds.clamp(0, 1 << 30);
  }
}
