import '../../../tasks/domain/entities/task.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/config/app_timezone.dart';
import '../../../progress/data/progress_repository.dart';

class TaskRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Criar tarefa
  Future<Task> create(Task task) async {
    final db = await _dbHelper.database;
    final pending = task.copyWith(
      syncStatus: SyncStatus.pending,
      atualizadoEm: AppTimeZone.now().toUtc(),
    );
    await db.insert('tasks', pending.toMap());
    return pending;
  }

  // Obter tarefa por ID
  Future<Task?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  // Obter todas as tarefas do utilizador
  Future<List<Task>> getByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'data_inicio ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // Obter tarefas de um dia específico
  Future<List<Task>> getByDate(String userId, DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = AppTimeZone.dayStartUtc(date);
    final endOfDay = AppTimeZone.dayEndUtc(date);

    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND data_inicio >= ? AND data_inicio < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'data_inicio ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Reads a planning interval from SQLite. Dashboard calendar indicators must
  /// use this durable local source, never a Firestore query.
  Future<List<Task>> getByRange(
    String userId, {
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND data_inicio >= ? AND data_inicio < ?',
      whereArgs: [
        userId,
        startInclusive.toUtc().toIso8601String(),
        endExclusive.toUtc().toIso8601String(),
      ],
      orderBy: 'data_inicio ASC',
    );
    return maps.map(Task.fromMap).toList();
  }

  // Obter tarefas por estado
  Future<List<Task>> getByEstado(String userId, EstadoTarefa estado) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND estado = ?',
      whereArgs: [userId, estado.toJson()],
      orderBy: 'data_inicio ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // Obter tarefas pendentes de sincronização
  Future<List<Task>> getPendingSync(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: [userId, SyncStatus.pending.toJson()],
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // Atualizar tarefa
  Future<void> update(Task task) async {
    final db = await _dbHelper.database;
    final pending = task.copyWith(
      syncStatus: SyncStatus.pending,
      atualizadoEm: AppTimeZone.now().toUtc(),
    );
    await db.update(
      'tasks',
      pending.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Deletar tarefa
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Marcar como sincronizada
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'sync_status': SyncStatus.synced.toJson(),
        'sincronizado': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Import is idempotent by the Google ID. It intentionally does not mark a
  /// remote record as pending: downloading from Google must work offline later
  /// without echoing the item back as a newly-created event.
  Future<Task> upsertImported(Task task) async {
    final db = await _dbHelper.database;
    final imported = task.copyWith(
      syncStatus: SyncStatus.synced,
      googleCalendarSynced: true,
    );
    final existing = imported.googleEventId == null
        ? <Map<String, Object?>>[]
        : await db.query('tasks',
            where: 'user_id = ? AND google_event_id = ?',
            whereArgs: [imported.userId, imported.googleEventId]);
    if (existing.isEmpty) {
      await db.insert('tasks', imported.toMap());
      return imported;
    } else {
      // Do not overwrite a local completion waiting to be sent to Google.
      final local = Task.fromMap(existing.first);
      if (local.syncStatus != SyncStatus.pending) {
        final saved = imported.copyWith(id: local.id);
        await db.update('tasks', saved.toMap(),
            where: 'id = ?', whereArgs: [local.id]);
        return saved;
      }
      return local;
    }
  }

  Stream<List<Task>> watchUserTasks(String userId) async* {
    yield await getByUserId(userId);
  }

  Stream<List<Task>> watchDayTasks(String userId, DateTime date) async* {
    yield await getByDate(userId, date);
  }

  // Marcar como pendente de sincronização
  Future<void> markAsPending(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'sync_status': SyncStatus.pending.toJson()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Limpar todas as tarefas (útil para logout)
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('tasks');
  }

  // Obter tarefas de hoje
  Future<List<Task>> getToday(String userId) async {
    return getByDate(userId, AppTimeZone.now());
  }

  // Obter tarefas atrasadas
  Future<List<Task>> getOverdue(String userId) async {
    final db = await _dbHelper.database;
    final now = AppTimeZone.now().toUtc();

    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND estado = ? AND data_inicio < ?',
      whereArgs: [
        userId,
        EstadoTarefa.pendente.toJson(),
        now.toIso8601String(),
      ],
      orderBy: 'data_inicio ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // Obter próximas tarefas (próximos 7 dias)
  Future<List<Task>> getUpcoming(String userId, {int days = 7}) async {
    final db = await _dbHelper.database;
    final now = AppTimeZone.now().toUtc();
    final future = now.add(Duration(days: days));

    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND data_inicio >= ? AND data_inicio < ?',
      whereArgs: [
        userId,
        now.toIso8601String(),
        future.toIso8601String(),
      ],
      orderBy: 'data_inicio ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Durable source for reminder recovery after app restart. Completed and
  /// cancelled work must never produce a new notification.
  Future<List<Task>> getFutureActive(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND data_inicio >= ? AND estado IN (?, ?)',
      whereArgs: [
        userId,
        AppTimeZone.now().toUtc().toIso8601String(),
        EstadoTarefa.pendente.toJson(),
        EstadoTarefa.emExecucao.toJson(),
      ],
      orderBy: 'data_inicio ASC',
    );
    return maps.map(Task.fromMap).toList();
  }

  // Iniciar tarefa
  Future<void> startTask(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'estado': EstadoTarefa.emExecucao.toJson(),
        'atualizado_em': AppTimeZone.now().toUtc().toIso8601String(),
        'sync_status': SyncStatus.pending.toJson(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Concluir tarefa
  Future<void> completeTask(String id, int tempoRealMinutos) async {
    final db = await _dbHelper.database;
    final existing = await db.query('tasks',
        columns: ['user_id', 'estado'], where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return;
    final wasCompleted =
        existing.first['estado'] == EstadoTarefa.concluida.toJson();
    final completedAt = AppTimeZone.now().toUtc();
    await db.update(
      'tasks',
      {
        'estado': EstadoTarefa.concluida.toJson(),
        'tempo_real_minutos': tempoRealMinutos,
        'concluido_em': completedAt.toIso8601String(),
        'atualizado_em': completedAt.toIso8601String(),
        'sync_status': SyncStatus.pending.toJson(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (!wasCompleted) {
      await ProgressRepository(databaseHelper: _dbHelper).enqueueCompletion(
        userId: existing.first['user_id']! as String,
        actualMinutes: tempoRealMinutos,
        completedAt: completedAt,
      );
    }
  }

  // Pular tarefa
  Future<void> skipTask(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'estado': EstadoTarefa.pulada.toJson(),
        'atualizado_em': AppTimeZone.now().toUtc().toIso8601String(),
        'sync_status': SyncStatus.pending.toJson(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cancelar tarefa
  Future<void> cancelTask(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'estado': EstadoTarefa.cancelada.toJson(),
        'atualizado_em': AppTimeZone.now().toUtc().toIso8601String(),
        'sync_status': SyncStatus.pending.toJson(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Reagendar tarefa
  Future<void> rescheduleTask(String id, DateTime newStart) async {
    final db = await _dbHelper.database;
    final taskMap = await getById(id);
    if (taskMap != null) {
      final newEnd = newStart.add(Duration(minutes: taskMap.duracaoMinutos));
      await db.update(
        'tasks',
        {
          'data_inicio': newStart.toUtc().toIso8601String(),
          'data_fim': newEnd.toUtc().toIso8601String(),
          'estado': EstadoTarefa.pendente.toJson(), // Volta para pendente
          'atualizado_em': AppTimeZone.now().toUtc().toIso8601String(),
          'sync_status': SyncStatus.pending.toJson(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<Map<String, dynamic>> validateDay({
    required DateTime data,
    required int duracaoMinutos,
    required String prioridade,
    required String userId,
    String? taskIdToExclude,
  }) async {
    const capacity = 960;
    final tasks = (await getByDate(userId, data))
        .where((task) => task.id != taskIdToExclude && !task.isCancelada)
        .toList();
    // A completed task consumes what was actually spent. This returns any
    // unused planned time to the day's capacity.
    final occupied = tasks.fold<int>(0, (sum, task) {
      if (task.isConcluida) {
        return sum + (task.tempoRealMinutos ?? task.duracaoMinutos);
      }
      return sum + task.duracaoMinutos;
    });
    final free = (capacity - occupied).clamp(0, capacity);
    return {
      'viavel': free >= duracaoMinutos,
      'podeReagendar': false,
      'tempoLivreMinutos': free,
      'mensagem': free >= duracaoMinutos
          ? 'Há $free min livres. Pode agendar!'
          : 'Não há tempo livre suficiente.',
    };
  }

  Future<Map<String, dynamic>> executarReagendamento({
    required String userId,
    required List<Map<String, dynamic>> reagendamentoSugerido,
  }) async {
    for (final item in reagendamentoSugerido) {
      final id = item['tarefaId'] as String?;
      final date = DateTime.tryParse(item['dataSugerida'] as String? ?? '');
      if (id != null && date != null) {
        await rescheduleTask(id, date);
      }
    }
    return {
      'sucesso': true,
      'mensagem': 'Reagendamento guardado localmente.',
      'tarefasMovidas': reagendamentoSugerido
    };
  }

  Future<Map<String, dynamic>> getWeeklyStats(
      String userId, DateTime weekStart) async {
    final tasks = <Task>[];
    for (var offset = 0; offset < 7; offset++) {
      tasks.addAll(
          await getByDate(userId, weekStart.add(Duration(days: offset))));
    }
    final completed = tasks.where((t) => t.isConcluida).length;
    return {
      'tarefasDefinidas': tasks.length,
      'tarefasConcluidas': completed,
      'percentualConclusao':
          tasks.isEmpty ? 0 : (completed * 100 / tasks.length).round()
    };
  }
}
