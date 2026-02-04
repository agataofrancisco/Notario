import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/task_firestore_repository.dart';
import '../../features/notes/data/repositories/note_repository.dart';
import 'notion_service.dart';
import 'google_calendar_service.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../../features/notes/domain/entities/note.dart';
import 'package:flutter/foundation.dart';

/// Serviço responsável por sincronizar dados pendentes quando a conexão é restabelecida
class SyncService {
  final TaskFirestoreRepository _taskRepository;
  final NoteRepository _noteRepository;
  final NotionService _notionService;
  final GoogleCalendarService _calendarService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSyncing = false;
  Timer? _syncTimer;

  SyncService({
    required TaskFirestoreRepository taskRepository,
    required NoteRepository noteRepository,
    required NotionService notionService,
    required GoogleCalendarService calendarService,
  })  : _taskRepository = taskRepository,
        _noteRepository = noteRepository,
        _notionService = notionService,
        _calendarService = calendarService;

  /// Inicia a sincronização periódica
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => performSync());
    // Executa uma vez no início
    performSync();
  }

  /// Para a sincronização periódica
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Executa a sincronização de todos os itens pendentes
  Future<void> performSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      if (kDebugMode) print('Starting background sync...');

      await _syncPendingTasks();
      await _syncPendingNotes();

      if (kDebugMode) print('Background sync completed.');
    } catch (e) {
      if (kDebugMode) print('Error during background sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPendingTasks() async {
    try {
      // Buscar tarefas com sincronização pendente no Notion ou Google Calendar
      final snapshot = await _firestore
          .collection('tasks')
          .where(Filter.or(
            Filter('notionSynced', isEqualTo: false),
            Filter('googleCalendarSynced', isEqualTo: false),
          ))
          .get();

      final tasks =
          snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList();

      for (var task in tasks) {
        var updatedTask = task;
        bool changed = false;

        // Sync Notion
        if (!task.notionSynced) {
          if (task.notionPageId == null) {
            final notionId = await _notionService.createTask(task);
            if (notionId != null) {
              updatedTask = updatedTask.copyWith(
                  notionPageId: notionId, notionSynced: true);
              changed = true;
            }
          } else {
            final success = await _notionService.updateTaskStatus(
                task.notionPageId!, task.isConcluida);
            if (success) {
              updatedTask = updatedTask.copyWith(notionSynced: true);
              changed = true;
            }
          }
        }

        // Sync Google Calendar
        if (!task.googleCalendarSynced) {
          if (task.googleEventId == null) {
            final event = await _calendarService.createEventFromTask(
              title: task.titulo,
              description: task.descricao,
              startTime: task.dataInicio,
              durationMinutes: task.duracaoMinutos,
            );
            if (event != null && event.id != null) {
              updatedTask = updatedTask.copyWith(
                  googleEventId: event.id, googleCalendarSynced: true);
              changed = true;
            }
          } else {
            final event = await _calendarService.updateEventFromTask(
              eventId: task.googleEventId!,
              title: task.titulo,
              description: task.descricao,
              startTime: task.dataInicio,
              durationMinutes: task.duracaoMinutos,
            );
            if (event != null) {
              updatedTask = updatedTask.copyWith(googleCalendarSynced: true);
              changed = true;
            }
          }
        }

        if (changed) {
          await _taskRepository.update(updatedTask);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error syncing pending tasks: $e');
    }
  }

  Future<void> _syncPendingNotes() async {
    try {
      final snapshot = await _firestore
          .collection('notes')
          .where('notionSynced', isEqualTo: false)
          .get();

      final notes =
          snapshot.docs.map((doc) => Note.fromJson(doc.data())).toList();

      for (var note in notes) {
        final notionId = await _notionService.createNote(note);
        if (notionId != null) {
          await _noteRepository.update(note.copyWith(notionSynced: true));
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error syncing pending notes: $e');
    }
  }
}
