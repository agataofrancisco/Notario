import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/note_repository.dart';
import '../../../../core/services/notification_service.dart';

// Events
abstract class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object?> get props => [];
}

class NoteLoadRequested extends NoteEvent {
  final String userId;

  const NoteLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class NoteCreateRequested extends NoteEvent {
  final Note note;

  const NoteCreateRequested(this.note);

  @override
  List<Object?> get props => [note];
}

class NoteUpdateRequested extends NoteEvent {
  final Note note;

  const NoteUpdateRequested(this.note);

  @override
  List<Object?> get props => [note];
}

class NoteDeleteRequested extends NoteEvent {
  final String noteId;

  const NoteDeleteRequested(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// States
abstract class NoteState extends Equatable {
  const NoteState();

  @override
  List<Object?> get props => [];
}

class NoteInitial extends NoteState {}

class NoteLoading extends NoteState {}

class NoteLoaded extends NoteState {
  final List<Note> notes;

  const NoteLoaded(this.notes);

  @override
  List<Object?> get props => [notes];
}

class NoteOperationSuccess extends NoteState {
  final String message;

  const NoteOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class NoteError extends NoteState {
  final String message;

  const NoteError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final NoteRepository _repository;
  final NotificationService _notificationService;

  NoteBloc({
    required NoteRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService,
        super(NoteInitial()) {
    on<NoteLoadRequested>(_onLoadRequested);
    on<NoteCreateRequested>(_onCreateRequested);
    on<NoteUpdateRequested>(_onUpdateRequested);
    on<NoteDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    NoteLoadRequested event,
    Emitter<NoteState> emit,
  ) async {
    emit(NoteLoading());
    try {
      await emit.forEach(
        _repository.watchUserNotes(event.userId),
        onData: (notes) => NoteLoaded(notes),
        onError: (error, stackTrace) =>
            NoteError('Erro ao carregar notas: ${error.toString()}'),
      );
    } catch (e) {
      emit(NoteError('Erro ao carregar notas: ${e.toString()}'));
    }
  }

  Future<void> _onCreateRequested(
    NoteCreateRequested event,
    Emitter<NoteState> emit,
  ) async {
    try {
      await _repository.create(event.note);

      // Agendar notificação se houver lembrete
      if (event.note.lembrete != null) {
        await _notificationService.scheduleNoteReminder(
          noteId: event.note.id,
          title: event.note.titulo,
          content: event.note.conteudo,
          reminderTime: event.note.lembrete!,
        );
      }

      emit(const NoteOperationSuccess('Nota criada com sucesso!'));
    } catch (e) {
      emit(NoteError('Erro ao criar nota: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRequested(
    NoteUpdateRequested event,
    Emitter<NoteState> emit,
  ) async {
    try {
      await _repository.update(event.note);

      // Cancelar notificação antiga e criar nova se necessário
      await _notificationService.cancelNotification(event.note.id);
      if (event.note.lembrete != null) {
        await _notificationService.scheduleNoteReminder(
          noteId: event.note.id,
          title: event.note.titulo,
          content: event.note.conteudo,
          reminderTime: event.note.lembrete!,
        );
      }

      emit(const NoteOperationSuccess('Nota atualizada com sucesso!'));
    } catch (e) {
      emit(NoteError('Erro ao atualizar nota: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteRequested(
    NoteDeleteRequested event,
    Emitter<NoteState> emit,
  ) async {
    try {
      await _repository.delete(event.noteId);
      await _notificationService.cancelNotification(event.noteId);
      emit(const NoteOperationSuccess('Nota deletada com sucesso!'));
    } catch (e) {
      emit(NoteError('Erro ao deletar nota: ${e.toString()}'));
    }
  }
}
