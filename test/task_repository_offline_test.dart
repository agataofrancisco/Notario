import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notario/core/config/app_timezone.dart';
import 'package:notario/core/database/database_helper.dart';
import 'package:notario/core/repositories/task_firestore_repository.dart';
import 'package:notario/core/services/auth_service.dart';
import 'package:notario/core/services/google_calendar_service.dart';
import 'package:notario/core/services/notification_service.dart';
import 'package:notario/core/services/progress_backup_service.dart';
import 'package:notario/core/services/sync_service.dart';
import 'package:notario/features/progress/data/progress_repository.dart';
import 'package:notario/features/tasks/data/repositories/task_repository.dart';
import 'package:notario/features/tasks/domain/entities/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/calendar/v3.dart' as calendar_api;

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCalendarService extends GoogleCalendarService {
  _FakeCalendarService(
      {required super.authService, required super.preferences});

  bool connected = true;
  Object? deleteError;
  Object? createError;
  Object? updateError;
  final deletedEventIds = <String>[];
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Future<void> deleteEvent(String eventId) async {
    final error = deleteError;
    if (error != null) throw error;
    deletedEventIds.add(eventId);
  }

  @override
  Future<calendar_api.Event?> createEventFromTask({
    required String title,
    required String? description,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    createCalls++;
    final error = createError;
    if (error != null) throw error;
    return calendar_api.Event()..id = 'created-google-event';
  }

  @override
  Future<calendar_api.Event?> updateEventFromTask({
    required String eventId,
    required String title,
    required String? description,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    updateCalls++;
    final error = updateError;
    if (error != null) throw error;
    return calendar_api.Event()..id = eventId;
  }
}

void main() {
  late Database database;
  late DatabaseHelper databaseHelper;
  late TaskRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppTimeZone.initialize();
  });

  setUp(() async {
    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE tasks (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              google_event_id TEXT,
              titulo TEXT NOT NULL,
              descricao TEXT,
              data_inicio TEXT NOT NULL,
              data_fim TEXT NOT NULL,
              duracao_minutos INTEGER NOT NULL,
              prioridade TEXT NOT NULL,
              aviso_antes_minutos INTEGER DEFAULT 10,
              aviso_depois_minutos INTEGER DEFAULT 5,
              estado TEXT DEFAULT 'pendente',
              tempo_real_minutos INTEGER,
              is_negotiable INTEGER DEFAULT 1,
              safety_margin_minutes INTEGER DEFAULT 0,
              sincronizado INTEGER DEFAULT 0,
              versao INTEGER DEFAULT 1,
              criado_em TEXT NOT NULL,
              atualizado_em TEXT NOT NULL,
              concluido_em TEXT,
              deadline TEXT,
              sync_status TEXT DEFAULT 'synced',
              remote_type TEXT DEFAULT 'local'
            )
          ''');
          await db.execute('''
            CREATE UNIQUE INDEX idx_tasks_remote_event
            ON tasks(user_id, remote_type, google_event_id)
          ''');
          await db.execute('''
            CREATE TABLE focus_sessions (
              task_id TEXT PRIMARY KEY,
              elapsed_seconds INTEGER NOT NULL DEFAULT 0,
              running_since_utc TEXT,
              updated_at_utc TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE progress_events (
              operation_id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              completed_at TEXT NOT NULL,
              actual_minutes INTEGER NOT NULL,
              kind TEXT NOT NULL DEFAULT 'completed',
              sync_status TEXT NOT NULL DEFAULT 'pending',
              attempts INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE sync_queue (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              entidade_tipo TEXT NOT NULL,
              entidade_id TEXT NOT NULL,
              operacao TEXT NOT NULL,
              payload TEXT NOT NULL,
              processado INTEGER DEFAULT 0,
              tentativas INTEGER DEFAULT 0,
              erro TEXT,
              criado_em TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    databaseHelper = DatabaseHelper.forTesting(database);
    repository = TaskRepository(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  Task makeTask({
    required String id,
    String? googleId,
    String remoteType = 'local',
    EstadoTarefa status = EstadoTarefa.pendente,
    int duration = 60,
    int? actualMinutes,
    DateTime? start,
  }) {
    final now = AppTimeZone.now().toUtc();
    final starts = start ?? AppTimeZone.at(DateTime(2026, 11, 17), 9, 0);
    return Task(
      id: id,
      userId: 'user-1',
      googleEventId: googleId,
      titulo: id,
      dataInicio: starts,
      dataFim: starts.add(Duration(minutes: duration)),
      duracaoMinutos: duration,
      prioridade: Prioridade.media,
      criadoEm: now,
      atualizadoEm: now,
      estado: status,
      tempoRealMinutos: actualMinutes,
      remoteType: remoteType,
    );
  }

  test('imported Google rows are upserted once by source ID', () async {
    final event = makeTask(
      id: 'generated-1',
      googleId: 'google-event-1',
      remoteType: 'google_calendar',
    );

    final first = await repository.upsertImported(event);
    final refreshed = await repository.upsertImported(
      event.copyWith(id: 'generated-2', titulo: 'Updated title'),
    );
    final rows = await database.query('tasks');

    expect(rows, hasLength(1));
    expect(refreshed.id, first.id);
    expect(refreshed.titulo, 'Updated title');
    expect(refreshed.syncStatus, SyncStatus.synced);
  });

  test('new work is committed to SQLite as pending before any sync attempt',
      () async {
    final task = makeTask(id: 'offline-create');

    final saved = await repository.create(task);
    final cached = await repository.getById(task.id);

    expect(saved.syncStatus, SyncStatus.pending);
    expect(cached?.titulo, task.titulo);
    expect(cached?.syncStatus, SyncStatus.pending);
  });

  test('deleting a locally-created Google event queues an offline tombstone',
      () async {
    await repository.create(makeTask(
      id: 'local-with-event',
      googleId: 'google-event-id',
    ));

    await repository.delete('local-with-event');

    expect(await repository.getById('local-with-event'), isNull);
    final queued = await database.query('sync_queue');
    expect(queued, hasLength(1));
    expect(queued.single['processado'], 0);
    expect(jsonDecode(queued.single['payload']! as String),
        {'googleEventId': 'google-event-id'});
  });

  test('deleting an imported Google event never queues remote deletion',
      () async {
    await repository.create(makeTask(
      id: 'imported-event',
      googleId: 'google-event-id',
      remoteType: 'google_calendar',
    ));

    await repository.delete('imported-event');

    expect(await database.query('sync_queue'), isEmpty);
  });

  test('queued Google deletion is retried and cleared after success', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final auth = AuthService(auth: _FakeFirebaseAuth());
    final calendar = _FakeCalendarService(
      authService: auth,
      preferences: preferences,
    );
    final sync = SyncService(
      localRepository: repository,
      firestoreRepository:
          TaskFirestoreRepository(firestore: _FakeFirebaseFirestore()),
      calendarService: calendar,
      notificationService: NotificationService(),
      progressBackupService: ProgressBackupService(
        repository: ProgressRepository(databaseHelper: databaseHelper),
        authService: auth,
      ),
    );
    await repository.create(makeTask(
      id: 'pending-delete',
      googleId: 'google-event-retry',
    ));
    await repository.delete('pending-delete');

    await sync.syncUser('user-1');

    expect(calendar.deletedEventIds, ['google-event-retry']);
    expect(await repository.getPendingCalendarDeletes('user-1'), isEmpty);
    final queued = await database.query('sync_queue');
    expect(queued.single['processado'], 1);
  });

  test('failed Google deletion stays queued with retry attention', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final auth = AuthService(auth: _FakeFirebaseAuth());
    final calendar = _FakeCalendarService(
      authService: auth,
      preferences: preferences,
    )..deleteError =
        const GoogleCalendarException(GoogleCalendarFailure.remote, 'offline');
    final sync = SyncService(
      localRepository: repository,
      firestoreRepository:
          TaskFirestoreRepository(firestore: _FakeFirebaseFirestore()),
      calendarService: calendar,
      notificationService: NotificationService(),
      progressBackupService: ProgressBackupService(
        repository: ProgressRepository(databaseHelper: databaseHelper),
        authService: auth,
      ),
    );
    await repository.create(makeTask(
      id: 'failed-delete',
      googleId: 'google-event-fail',
    ));
    await repository.delete('failed-delete');

    await sync.syncUser('user-1');

    final pending = await repository.getPendingCalendarDeletes('user-1');
    expect(pending, hasLength(1));
    final queued = await database.query('sync_queue');
    expect(queued.single['tentativas'], 1);
    expect(queued.single['erro'], contains('offline'));
    expect(calendar.deletedEventIds, isEmpty);
  });

  test('failed Calendar create keeps the task local and pending', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final auth = AuthService(auth: _FakeFirebaseAuth());
    final calendar = _FakeCalendarService(
      authService: auth,
      preferences: preferences,
    )..createError = const GoogleCalendarException(
        GoogleCalendarFailure.remote, 'create failed');
    final sync = SyncService(
      localRepository: repository,
      firestoreRepository:
          TaskFirestoreRepository(firestore: _FakeFirebaseFirestore()),
      calendarService: calendar,
      notificationService: NotificationService(),
      progressBackupService: ProgressBackupService(
        repository: ProgressRepository(databaseHelper: databaseHelper),
        authService: auth,
      ),
    );
    await repository.create(makeTask(id: 'failed-create'));

    await sync.syncUser('user-1');

    final saved = await repository.getById('failed-create');
    expect(calendar.createCalls, 1);
    expect(saved, isNotNull);
    expect(saved?.syncStatus, SyncStatus.pending);
    expect(saved?.googleEventId, isNull);
  });

  test('failed Calendar update preserves its event ID and pending state',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final auth = AuthService(auth: _FakeFirebaseAuth());
    final calendar = _FakeCalendarService(
      authService: auth,
      preferences: preferences,
    )..updateError = const GoogleCalendarException(
        GoogleCalendarFailure.remote, 'update failed');
    final sync = SyncService(
      localRepository: repository,
      firestoreRepository:
          TaskFirestoreRepository(firestore: _FakeFirebaseFirestore()),
      calendarService: calendar,
      notificationService: NotificationService(),
      progressBackupService: ProgressBackupService(
        repository: ProgressRepository(databaseHelper: databaseHelper),
        authService: auth,
      ),
    );
    await repository.create(makeTask(
      id: 'failed-update',
      googleId: 'existing-google-event',
    ));

    await sync.syncUser('user-1');

    final saved = await repository.getById('failed-update');
    expect(calendar.updateCalls, 1);
    expect(saved, isNotNull);
    expect(saved?.syncStatus, SyncStatus.pending);
    expect(saved?.googleEventId, 'existing-google-event');
  });

  test('focus elapsed time survives pause and resume from SQLite', () async {
    await repository.create(makeTask(id: 'focus'));

    expect(await repository.startFocusSession('focus'), 0);
    await repository.pauseFocusSession('focus', 125);
    expect(await repository.startFocusSession('focus'), 125);
  });

  test('completion stores actual time and returns unused capacity', () async {
    final start = AppTimeZone.at(DateTime(2026, 11, 17), 9, 0);
    await repository.create(makeTask(
      id: 'completed',
      status: EstadoTarefa.concluida,
      duration: 120,
      actualMinutes: 30,
      start: start,
    ));
    await repository.create(makeTask(
      id: 'pending',
      duration: 60,
      start: start.add(const Duration(hours: 2)),
    ));

    final capacity = await repository.validateDay(
      data: start,
      duracaoMinutos: 700,
      prioridade: Prioridade.media.name,
      userId: 'user-1',
    );

    expect(capacity['tempoLivreMinutos'], 750);
    expect(capacity['viavel'], true);

    await repository.completeTask('pending', 25);
    final completed = await repository.getById('pending');
    expect(completed?.estado, EstadoTarefa.concluida);
    expect(completed?.tempoRealMinutos, 25);
    expect(await database.query('progress_events'), hasLength(1));
  });
}
