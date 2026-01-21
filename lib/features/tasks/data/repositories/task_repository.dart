import '../../../tasks/domain/entities/task.dart';
import '../../../../core/database/database_helper.dart';

class TaskRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Criar tarefa
  Future<Task> create(Task task) async {
    final db = await _dbHelper.database;
    await db.insert('tasks', task.toMap());
    return task;
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
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

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
    await db.update(
      'tasks',
      task.toMap(),
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
    return getByDate(userId, DateTime.now());
  }

  // Obter tarefas atrasadas
  Future<List<Task>> getOverdue(String userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

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
    final now = DateTime.now();
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

  // Iniciar tarefa
  Future<void> startTask(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'estado': EstadoTarefa.emExecucao.toJson(),
        'atualizado_em': DateTime.now().toIso8601String(),
        'sync_status': SyncStatus.pending.toJson(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Concluir tarefa
  Future<void> completeTask(String id, int tempoRealMinutos) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'estado': EstadoTarefa.concluida.toJson(),
        'tempo_real_minutos': tempoRealMinutos,
        'concluido_em': DateTime.now().toIso8601String(),
        'atualizado_em': DateTime.now().toIso8601String(),
        'sync_status': SyncStatus.pending.toJson(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Pular tarefa
  Future<void> skipTask(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'estado': EstadoTarefa.pulada.toJson(),
        'atualizado_em': DateTime.now().toIso8601String(),
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
        'atualizado_em': DateTime.now().toIso8601String(),
        'sync_status': SyncStatus.pending.toJson(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
