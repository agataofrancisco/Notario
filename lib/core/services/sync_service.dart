import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../repositories/task_firestore_repository.dart';
import 'google_calendar_service.dart';
import 'notification_service.dart';
import '../config/app_timezone.dart';
import '../config/app_config.dart';
import 'progress_backup_service.dart';

/// Pushes changes only after SQLite committed them; failures remain pending.
class SyncService {
  SyncService(
      {required TaskRepository localRepository,
      required TaskFirestoreRepository firestoreRepository,
      required GoogleCalendarService calendarService,
      required NotificationService notificationService,
      required ProgressBackupService progressBackupService})
      : _local = localRepository,
        _firestore = firestoreRepository,
        _calendar = calendarService,
        _notifications = notificationService,
        _progressBackup = progressBackupService;

  final TaskRepository _local;
  final TaskFirestoreRepository _firestore;
  final GoogleCalendarService _calendar;
  final NotificationService _notifications;
  final ProgressBackupService _progressBackup;
  bool _isSyncing = false;
  Timer? _syncTimer;

  void startPeriodicSync(String userId,
      {Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncUser(userId));
    syncUser(userId);
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncUser(String userId) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      for (var task in await _local.getPendingSync(userId)) {
        var synced = task;
        var firestoreSynced = !AppConfig.enableFirestoreSync;
        var remoteSynced = true;

        // A Firebase billing/configuration error must not prevent Calendar
        // synchronization or compromise the local-first record.
        if (AppConfig.enableFirestoreSync) {
          try {
            await _firestore.create(synced);
            firestoreSynced = true;
          } catch (error) {
            firestoreSynced = false;
            if (kDebugMode) debugPrint('Firestore sync pending: $error');
          }
        }

        try {
          if (synced.remoteType == 'local') {
            final event = synced.googleEventId == null
                ? await _calendar.createEventFromTask(
                    title: synced.titulo,
                    description: synced.descricao,
                    startTime: synced.dataInicio,
                    durationMinutes: synced.duracaoMinutos)
                : await _calendar.updateEventFromTask(
                    eventId: synced.googleEventId!,
                    title: synced.titulo,
                    description: synced.descricao,
                    startTime: synced.dataInicio,
                    durationMinutes: synced.duracaoMinutos);
            if (event?.id != null) {
              synced = synced.copyWith(
                  googleEventId: event!.id, googleCalendarSynced: true);
            }
          } else if (synced.remoteType == 'google_task' &&
              synced.isConcluida &&
              synced.googleEventId != null) {
            await _calendar.completeGoogleTask(synced.googleEventId!);
          }
        } catch (error) {
          remoteSynced = false;
          if (kDebugMode) debugPrint('Google sync pending: $error');
        }

        // Keep the assigned Google event ID even while Firestore is pending,
        // otherwise every retry would create a duplicate Calendar event.
        await _local.update(synced);
        if (firestoreSynced && remoteSynced) {
          await _local.markAsSynced(synced.id);
        }
      }
      await _progressBackup.sync(userId);
    } catch (error) {
      if (kDebugMode) debugPrint('Sync pending: $error');
    } finally {
      _isSyncing = false;
    }
  }

  /// Re-register OS reminders from durable records. This needs no network and
  /// is safe at every app launch because notifications use stable IDs.
  Future<void> restoreLocalNotifications(String userId) async {
    for (final task in await _local.getFutureActive(userId)) {
      await _schedule(task);
    }
  }

  /// Cache an offline planning window after login. Individual-day refreshes
  /// remain available from the dashboard.
  Future<void> refreshGoogleCache(String userId) async {
    final now = AppTimeZone.now();
    try {
      await _importGoogleRange(
        userId,
        AppTimeZone.dayStartUtc(now.subtract(const Duration(days: 30))),
        AppTimeZone.dayEndUtc(now.add(const Duration(days: 365))),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('Google cache refresh skipped: $error');
    }
  }

  /// Imports into the same local entity consumed by focus mode/notifications.
  Future<void> importGoogleDay(String userId, DateTime date) async {
    await _importGoogleRange(
      userId,
      AppTimeZone.dayStartUtc(date),
      AppTimeZone.dayEndUtc(date),
    );
  }

  Future<void> _importGoogleRange(
      String userId, DateTime startInclusive, DateTime endExclusive) async {
    final now = AppTimeZone.now().toUtc();
    final events =
        await _calendar.getEventsForRange(startInclusive, endExclusive);
    for (final event in events) {
      if (event.id == null) continue;
      final start = event.start?.dateTime ??
          GoogleCalendarService.parseGoogleDate(event.start?.date);
      final end = event.end?.dateTime ??
          GoogleCalendarService.parseGoogleDate(event.end?.date);
      if (start == null) continue;
      final minutes = end?.difference(start).inMinutes ?? 30;
      final task = Task(
          id: const Uuid().v4(),
          userId: userId,
          googleEventId: event.id,
          titulo: event.summary ?? 'Evento Google',
          descricao: event.description,
          dataInicio: start.toUtc(),
          dataFim: (end ?? start.add(Duration(minutes: minutes))).toUtc(),
          duracaoMinutos: minutes,
          prioridade: Prioridade.media,
          criadoEm: now,
          atualizadoEm: now,
          remoteType: 'google_calendar',
          googleCalendarSynced: true);
      await _schedule(await _local.upsertImported(task));
    }
    final remoteTasks =
        await _calendar.getTasksForRange(startInclusive, endExclusive);
    for (final remote in remoteTasks) {
      if (remote.id == null) continue;
      final due = DateTime.tryParse(remote.due ?? '')?.toUtc();
      if (due == null) continue;
      final task = Task(
          id: const Uuid().v4(),
          userId: userId,
          googleEventId: remote.id,
          titulo: remote.title ?? 'Tarefa Google',
          descricao: remote.notes,
          dataInicio: due,
          dataFim: due.add(const Duration(minutes: 30)),
          duracaoMinutos: 30,
          prioridade: Prioridade.media,
          criadoEm: now,
          atualizadoEm: now,
          remoteType: 'google_task',
          googleCalendarSynced: true);
      await _schedule(await _local.upsertImported(task));
    }
  }

  Future<void> _schedule(Task task) async {
    // A platform alarm quota or permission failure must never invalidate the
    // SQLite cache. The record remains available and will be retried at boot.
    try {
      await _notifications.scheduleTaskReminder(
          taskId: task.id,
          title: task.titulo,
          startTime: task.dataInicio,
          minutesBefore: task.avisoAntesMinutos);
      await _notifications.scheduleTaskStartNotification(
          taskId: task.id, title: task.titulo, startTime: task.dataInicio);
    } catch (error) {
      if (kDebugMode) debugPrint('Notification scheduling skipped: $error');
    }
  }
}
