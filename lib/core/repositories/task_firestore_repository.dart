import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/tasks/domain/entities/task.dart';

/// Repositório de tarefas usando Firestore
/// Substitui o antigo TaskRepository que usava SQLite
class TaskFirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Validar se dia comporta tarefa
  /// Retorna informações sobre viabilidade, tempo livre, e sugestões
  Future<Map<String, dynamic>> validateDay({
    required DateTime data,
    required int duracaoMinutos,
    required String prioridade,
    String? userId,
    String? taskIdToExclude,
  }) async {
    try {
      if (userId == null) {
        throw Exception('userId é obrigatório para validação');
      }

      // Constante: minutos úteis por dia (16 horas)
      const minutosUteisDia = 960;

      // 1. Buscar tarefas do dia
      final startOfDay = DateTime(data.year, data.month, data.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('dataInicio',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dataInicio', isLessThan: Timestamp.fromDate(endOfDay))
          .where('estado', whereIn: ['pendente', 'emExecucao']).get();

      final tasks = snapshot.docs
          .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
          .where((task) => task.id != taskIdToExclude)
          .toList();

      // 2. Calcular tempo ocupado
      final tempoOcupado =
          tasks.fold<int>(0, (sum, task) => sum + task.duracaoMinutos);
      final tempoLivre = minutosUteisDia - tempoOcupado;
      final percentual = (tempoOcupado / minutosUteisDia * 100).round();

      // 3. Verificar viabilidade
      if (tempoLivre >= duracaoMinutos) {
        return {
          'viavel': true,
          'tempoLivreMinutos': tempoLivre,
          'tempoOcupadoMinutos': tempoOcupado,
          'percentualOcupado': percentual,
          'mensagem': 'Há ${_formatTempo(tempoLivre)} livres. Pode agendar!',
          'tarefasExistentes': tasks.length,
        };
      }

      // 4. Não cabe - buscar soluções
      final faltam = duracaoMinutos - tempoLivre;
      final prioridadeAtual = _parsePrioridade(prioridade);

      // 4.1. Tarefas de menor prioridade
      final tarefasParaMover = tasks
          .where((t) =>
              _getPrioridadeValue(t.prioridade) <
              _getPrioridadeValue(prioridadeAtual))
          .toList()
        ..sort((a, b) => _getPrioridadeValue(a.prioridade)
            .compareTo(_getPrioridadeValue(b.prioridade)));

      int tempoLiberado = 0;
      List<Map<String, dynamic>> sugestoes = [];
      for (var task in tarefasParaMover) {
        if (tempoLiberado >= faltam) break;
        tempoLiberado += task.duracaoMinutos;
        sugestoes.add({
          'id': task.id,
          'titulo': task.titulo,
          'duracaoMinutos': task.duracaoMinutos,
          'prioridade': task.prioridade.toJson(),
        });
      }

      // 4.2. Dias alternativos
      final diasAlternativos =
          await _buscarDiasAlternativos(userId, data, duracaoMinutos);

      if (sugestoes.isNotEmpty && tempoLiberado >= faltam) {
        return {
          'viavel': false,
          'tempoLivreMinutos': tempoLivre,
          'tempoOcupadoMinutos': tempoOcupado,
          'percentualOcupado': percentual,
          'mensagem':
              'Faltam ${_formatTempo(faltam)}. Sugestão: mover ${sugestoes.length} tarefa(s).',
          'tarefasParaMover': sugestoes,
          'diasAlternativos': diasAlternativos,
        };
      }

      return {
        'viavel': false,
        'tempoLivreMinutos': tempoLivre,
        'tempoOcupadoMinutos': tempoOcupado,
        'percentualOcupado': percentual,
        'mensagem':
            'Não há espaço (faltam ${_formatTempo(faltam)}). Escolha outro dia.',
        'diasAlternativos': diasAlternativos,
      };
    } catch (e) {
      throw Exception('Erro ao validar dia: $e');
    }
  }

  Future<List<DateTime>> _buscarDiasAlternativos(
      String userId, DateTime dataInicial, int duracaoNecessaria) async {
    final dias = <DateTime>[];
    for (int i = 1; i <= 7 && dias.length < 3; i++) {
      final dia = dataInicial.add(Duration(days: i));
      final start = DateTime(dia.year, dia.month, dia.day);
      final end = start.add(const Duration(days: 1));

      final snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('dataInicio',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dataInicio', isLessThan: Timestamp.fromDate(end))
          .where('estado', whereIn: ['pendente', 'emExecucao']).get();

      final ocupado = snapshot.docs.fold<int>(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return sum;
        return sum + ((data['duracaoMinutos'] as num?)?.toInt() ?? 0);
      });

      if (960 - ocupado >= duracaoNecessaria) dias.add(dia);
    }
    return dias;
  }

  Prioridade _parsePrioridade(String p) {
    switch (p.toLowerCase()) {
      case 'alta':
        return Prioridade.alta;
      case 'baixa':
        return Prioridade.baixa;
      default:
        return Prioridade.media;
    }
  }

  int _getPrioridadeValue(Prioridade p) => p == Prioridade.alta
      ? 3
      : p == Prioridade.media
          ? 2
          : 1;

  String _formatTempo(int min) {
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
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
