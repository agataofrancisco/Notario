import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';
import '../../../../core/repositories/task_firestore_repository.dart';
import '../../../../core/services/google_calendar_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/notion_service.dart';

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
  final String userId;
  final DateTime data;
  final int duracaoMinutos;
  final String prioridade;
  final String? taskIdToExclude;

  const TaskValidateDayRequested({
    required this.userId,
    required this.data,
    required this.duracaoMinutos,
    required this.prioridade,
    this.taskIdToExclude,
  });

  @override
  List<Object?> get props =>
      [userId, data, duracaoMinutos, prioridade, taskIdToExclude];
}

class TaskExecuteReschedulingRequested extends TaskEvent {
  final String userId;
  final List<Map<String, dynamic>> reagendamentoSugerido;

  const TaskExecuteReschedulingRequested({
    required this.userId,
    required this.reagendamentoSugerido,
  });

  @override
  List<Object?> get props => [userId, reagendamentoSugerido];
}

class TaskWeeklyStatsRequested extends TaskEvent {
  final String userId;
  final DateTime weekStart;

  const TaskWeeklyStatsRequested({
    required this.userId,
    required this.weekStart,
  });

  @override
  List<Object?> get props => [userId, weekStart];
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
  final bool? podeReagendar;
  final int tempoLivreMinutos;
  final String mensagem;
  final List<dynamic>? tarefasParaMover;
  final List<Map<String, dynamic>>? reagendamentoSugerido;
  final List<DateTime>? diasAlternativos;
  final int? tempoLiberado;

  const TaskValidationResult({
    required this.viavel,
    this.podeReagendar,
    required this.tempoLivreMinutos,
    required this.mensagem,
    this.tarefasParaMover,
    this.reagendamentoSugerido,
    this.diasAlternativos,
    this.tempoLiberado,
  });

  @override
  List<Object?> get props => [
        viavel,
        podeReagendar,
        tempoLivreMinutos,
        mensagem,
        tarefasParaMover,
        reagendamentoSugerido,
        diasAlternativos,
        tempoLiberado,
      ];
}

class TaskReschedulingResult extends TaskState {
  final bool sucesso;
  final String mensagem;
  final List<Map<String, dynamic>>? tarefasMovidas;

  const TaskReschedulingResult({
    required this.sucesso,
    required this.mensagem,
    this.tarefasMovidas,
  });

  @override
  List<Object?> get props => [sucesso, mensagem, tarefasMovidas];
}

class TaskWeeklyStatsResult extends TaskState {
  final Map<String, dynamic> stats;

  const TaskWeeklyStatsResult(this.stats);

  @override
  List<Object?> get props => [stats];
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
  final GoogleCalendarService _googleCalendarService;
  final NotificationService _notificationService;
  final NotionService _notionService; // Injected
  final bool _enableGoogleCalendar;

  TaskBloc({
    required TaskFirestoreRepository repository,
    required GoogleCalendarService googleCalendarService,
    required NotificationService notificationService,
    NotionService? notionService,
    bool enableGoogleCalendar = false,
  })  : _repository = repository,
        _googleCalendarService = googleCalendarService,
        _notificationService = notificationService,
        _notionService = notionService ?? NotionService(),
        _enableGoogleCalendar = enableGoogleCalendar,
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
    on<TaskExecuteReschedulingRequested>(_onExecuteReschedulingRequested);
    on<TaskWeeklyStatsRequested>(_onWeeklyStatsRequested);
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
      var taskToSave = event.task;

      // 1) (Opcional) Criar evento no Google Calendar (não bloqueia o salvamento)
      if (_enableGoogleCalendar) {
        try {
          final createdEvent = await _googleCalendarService.createEventFromTask(
            title: taskToSave.titulo,
            description: taskToSave.descricao,
            startTime: taskToSave.dataInicio,
            durationMinutes: taskToSave.duracaoMinutos,
          );
          if (createdEvent != null && createdEvent.id != null) {
            taskToSave = taskToSave.copyWith(
              googleEventId: createdEvent.id,
              sincronizado: true,
            );
          } else {
            // Falha silenciosa - evento não criado no Google Calendar
            taskToSave = taskToSave.copyWith(sincronizado: false);
          }
        } catch (_) {
          taskToSave = taskToSave.copyWith(sincronizado: false);
        }
      }

      // 2) Persistir no Firestore
      await _repository.create(taskToSave);

      // 2.5) Sincronizar com Notion (não bloqueia)
      try {
        await _notionService.createTask(taskToSave);
      } catch (_) {
        // Falha silenciosa - não impede criação da tarefa
      }

      // 3) Lembrete local
      await _notificationService.scheduleTaskReminder(
        taskId: taskToSave.id,
        title: taskToSave.titulo,
        startTime: taskToSave.dataInicio,
        minutesBefore: taskToSave.avisoAntesMinutos,
      );
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
      var taskToSave = event.task;

      // 1) (Opcional) Atualizar / criar evento no Google Calendar (não bloqueia o salvamento)
      if (_enableGoogleCalendar) {
        try {
          if (taskToSave.googleEventId != null &&
              taskToSave.googleEventId!.isNotEmpty) {
            final updatedEvent = await _googleCalendarService.updateEvent(
              eventId: taskToSave.googleEventId!,
              title: taskToSave.titulo,
              description: taskToSave.descricao,
              startTime: taskToSave.dataInicio,
              durationMinutes: taskToSave.duracaoMinutos,
            );
            if (updatedEvent != null) {
              taskToSave = taskToSave.copyWith(sincronizado: true);
            } else {
              taskToSave = taskToSave.copyWith(sincronizado: false);
            }
          } else {
            final createdEvent =
                await _googleCalendarService.createEventFromTask(
              title: taskToSave.titulo,
              description: taskToSave.descricao,
              startTime: taskToSave.dataInicio,
              durationMinutes: taskToSave.duracaoMinutos,
            );
            if (createdEvent != null && createdEvent.id != null) {
              taskToSave = taskToSave.copyWith(
                googleEventId: createdEvent.id,
                sincronizado: true,
              );
            } else {
              taskToSave = taskToSave.copyWith(sincronizado: false);
            }
          }
        } catch (_) {
          taskToSave = taskToSave.copyWith(sincronizado: false);
        }
      }

      // 2) Persistir no Firestore
      await _repository.update(taskToSave);

      // 3) Atualizar lembrete local
      await _notificationService.cancelNotification(taskToSave.id);
      await _notificationService.scheduleTaskReminder(
        taskId: taskToSave.id,
        title: taskToSave.titulo,
        startTime: taskToSave.dataInicio,
        minutesBefore: taskToSave.avisoAntesMinutos,
      );
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
      // Buscar tarefa para tentar remover eventId e cancelar lembrete
      final task = await _repository.getById(event.taskId);
      if (_enableGoogleCalendar &&
          task?.googleEventId != null &&
          task!.googleEventId!.isNotEmpty) {
        try {
          await _googleCalendarService.deleteEvent(task.googleEventId!);
        } catch (_) {
          // Não bloquear delete local
        }
      }

      await _notificationService.cancelNotification(event.taskId);
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
        userId: event.userId,
        taskIdToExclude: event.taskIdToExclude,
      );

      emit(TaskValidationResult(
        viavel: result['viavel'] as bool,
        podeReagendar: result['podeReagendar'] as bool?,
        tempoLivreMinutos: result['tempoLivreMinutos'] as int,
        mensagem: result['mensagem'] as String,
        tarefasParaMover: result['tarefasParaMover'] as List<dynamic>?,
        reagendamentoSugerido:
            (result['reagendamentoSugerido'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>(),
        diasAlternativos: (result['diasAlternativos'] as List<dynamic>?)
            ?.map((e) => DateTime.parse(e as String))
            .toList(),
        tempoLiberado: result['tempoLiberado'] as int?,
      ));
    } catch (e) {
      emit(TaskError('Erro ao validar dia: ${e.toString()}'));
    }
  }

  Future<void> _onExecuteReschedulingRequested(
    TaskExecuteReschedulingRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final result = await _repository.executarReagendamento(
        userId: event.userId,
        reagendamentoSugerido: event.reagendamentoSugerido,
      );

      emit(TaskReschedulingResult(
        sucesso: result['sucesso'] as bool,
        mensagem: result['mensagem'] as String,
        tarefasMovidas: (result['tarefasMovidas'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>(),
      ));
    } catch (e) {
      emit(TaskError('Erro ao executar reagendamento: ${e.toString()}'));
    }
  }

  Future<void> _onWeeklyStatsRequested(
    TaskWeeklyStatsRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final stats =
          await _repository.getWeeklyStats(event.userId, event.weekStart);
      emit(TaskWeeklyStatsResult(stats));
    } catch (e) {
      emit(TaskError('Erro ao obter estatísticas semanais: ${e.toString()}'));
    }
  }
}
