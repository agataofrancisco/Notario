import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../features/tasks/domain/entities/task.dart';

/// Repositório de tarefas usando Firestore
/// Substitui o antigo TaskRepository que usava SQLite
class TaskFirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Referência à coleção de tarefas
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  /// Criar nova tarefa
  Future<void> create(Task task) async {
    await _tasksCollection.doc(task.id).set(task.toJson());
  }

  /// Obter tarefas do utilizador (Stream em tempo real!)
  Stream<List<Task>> watchUserTasks(String userId) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .orderBy('dataInicio')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Obter tarefas de um dia específico (Stream)
  Stream<List<Task>> watchDayTasks(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('dataInicio',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dataInicio', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dataInicio')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Obter tarefas de hoje (Stream)
  Stream<List<Task>> watchTodayTasks(String userId) {
    return watchDayTasks(userId, DateTime.now());
  }

  /// Obter tarefas atrasadas (Stream)
  Stream<List<Task>> watchOverdueTasks(String userId) {
    final now = DateTime.now();

    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('estado', isEqualTo: 'pendente')
        .where('dataInicio', isLessThan: Timestamp.fromDate(now))
        .orderBy('dataInicio')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Obter próximas tarefas (próximos N dias)
  Stream<List<Task>> watchUpcomingTasks(String userId, {int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('dataInicio', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('dataInicio', isLessThan: Timestamp.fromDate(future))
        .orderBy('dataInicio')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Obter tarefas por estado (Stream)
  Stream<List<Task>> watchTasksByEstado(String userId, EstadoTarefa estado) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('estado', isEqualTo: estado.name)
        .orderBy('dataInicio')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Obter tarefa por ID (Future)
  Future<Task?> getById(String taskId) async {
    final doc = await _tasksCollection.doc(taskId).get();
    if (!doc.exists) return null;
    return Task.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Atualizar tarefa
  Future<void> update(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toJson());
  }

  /// Deletar tarefa
  Future<void> delete(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  /// Iniciar tarefa (mudar estado para em_execucao)
  Future<void> startTask(String taskId) async {
    await _tasksCollection.doc(taskId).update({
      'estado': EstadoTarefa.emExecucao.name,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Concluir tarefa
  Future<void> completeTask(String taskId, int tempoRealMinutos) async {
    await _tasksCollection.doc(taskId).update({
      'estado': EstadoTarefa.concluida.name,
      'tempoRealMinutos': tempoRealMinutos,
      'concluidoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Pular tarefa
  Future<void> skipTask(String taskId) async {
    await _tasksCollection.doc(taskId).update({
      'estado': EstadoTarefa.pulada.name,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Cancelar tarefa
  Future<void> cancelTask(String taskId) async {
    await _tasksCollection.doc(taskId).update({
      'estado': EstadoTarefa.cancelada.name,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Validar se dia comporta tarefa (chama Cloud Function)
  Future<Map<String, dynamic>> validateDay({
    required DateTime data,
    required int duracaoMinutos,
    required String prioridade,
  }) async {
    try {
      final callable = _functions.httpsCallable('validateDay');
      final result = await callable.call({
        'data': data.toIso8601String(),
        'duracaoMinutos': duracaoMinutos,
        'prioridade': prioridade,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      // Se Cloud Function não existir ainda, retornar resposta mock
      return {
        'viavel': true,
        'tempoLivreMinutos': 480, // 8h
        'mensagem': 'Validação local (Cloud Function não disponível)',
      };
    }
  }

  /// Limpar todas as tarefas do utilizador (útil para logout)
  Future<void> clearUserTasks(String userId) async {
    final snapshot =
        await _tasksCollection.where('userId', isEqualTo: userId).get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
