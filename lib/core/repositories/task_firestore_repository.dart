import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/tasks/domain/entities/task.dart';

/// Repositório de tarefas usando Firestore
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

  /// Obter tarefas num intervalo de datas (Stream)
  /// Útil para o mini-calendário (ex: 7 dias) sem precisar abrir 7 streams.
  Stream<List<Task>> watchRangeTasks({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final start = DateTime(
      startInclusive.year,
      startInclusive.month,
      startInclusive.day,
    );
    final end = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );

    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('dataInicio', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dataInicio', isLessThan: Timestamp.fromDate(end))
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
    final now = DateTime.now();
    await _tasksCollection.doc(taskId).update({
      'estado': EstadoTarefa.concluida.name,
      'tempoRealMinutos': tempoRealMinutos,
      'concluidoEm': Timestamp.fromDate(now),
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

  /// Reagendar tarefa
  Future<void> rescheduleTask(String taskId, DateTime newStart) async {
    final task = await getById(taskId);
    if (task == null) return;

    final newEnd = newStart.add(Duration(minutes: task.duracaoMinutos));

    await _tasksCollection.doc(taskId).update({
      'dataInicio': Timestamp.fromDate(newStart),
      'dataFim': Timestamp.fromDate(newEnd),
      'estado': EstadoTarefa.pendente.name,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Validar se dia comporta tarefa com sistema inteligente de reagendamento
  /// Retorna informações sobre viabilidade, tempo livre, e sugestões de reagendamento
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
          tasks.fold<int>(0, (total, task) => total + task.duracaoMinutos);
      final tempoLivre = minutosUteisDia - tempoOcupado;
      final percentual = (tempoOcupado / minutosUteisDia * 100).round();

      // 3. Verificar viabilidade direta
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

      // 4. Não cabe - implementar sistema inteligente de reagendamento
      final faltam = duracaoMinutos - tempoLivre;
      final prioridadeAtual = _parsePrioridade(prioridade);
      final prioridadeAtualValue = _getPrioridadeValue(prioridadeAtual);

      // 4.1. Identificar tarefas de menor prioridade que podem ser movidas
      final tarefasNegociaveis = tasks
          .where((t) =>
              t.isNegotiable &&
              _getPrioridadeValue(t.prioridade) < prioridadeAtualValue)
          .toList()
        ..sort((a, b) {
          // Ordenar por prioridade (menor primeiro) e depois por duração (maior primeiro)
          final prioComp = _getPrioridadeValue(a.prioridade)
              .compareTo(_getPrioridadeValue(b.prioridade));
          if (prioComp != 0) return prioComp;
          return b.duracaoMinutos.compareTo(a.duracaoMinutos);
        });

      // 4.2. Calcular reagendamento inteligente
      final reagendamento = await _calcularReagendamentoInteligente(
        userId: userId,
        tarefasNegociaveis: tarefasNegociaveis,
        tempoNecessario: faltam,
        dataOriginal: data,
      );

      // 4.3. Buscar dias alternativos
      final diasAlternativos =
          await _buscarDiasAlternativos(userId, data, duracaoMinutos);

      if (reagendamento['viavel'] == true) {
        return {
          'viavel': false, // Não cabe diretamente
          'podeReagendar': true,
          'tempoLivreMinutos': tempoLivre,
          'tempoOcupadoMinutos': tempoOcupado,
          'percentualOcupado': percentual,
          'mensagem': reagendamento['mensagem'],
          'tarefasParaMover': reagendamento['tarefasParaMover'],
          'reagendamentoSugerido': reagendamento['reagendamentoSugerido'],
          'diasAlternativos':
              diasAlternativos.map((d) => d.toIso8601String()).toList(),
          'tempoLiberado': reagendamento['tempoLiberado'],
        };
      }

      // 4.4. Não há tarefas de menor prioridade suficientes
      return {
        'viavel': false,
        'podeReagendar': false,
        'tempoLivreMinutos': tempoLivre,
        'tempoOcupadoMinutos': tempoOcupado,
        'percentualOcupado': percentual,
        'mensagem': tarefasNegociaveis.isEmpty
            ? 'Dia lotado. Todas as tarefas têm prioridade igual ou superior.'
            : 'Não há espaço suficiente mesmo movendo tarefas de menor prioridade.',
        'diasAlternativos':
            diasAlternativos.map((d) => d.toIso8601String()).toList(),
        'tarefasNegociaveis': tarefasNegociaveis.length,
      };
    } catch (e) {
      throw Exception('Erro ao validar dia: $e');
    }
  }

  /// Calcular reagendamento inteligente de tarefas
  Future<Map<String, dynamic>> _calcularReagendamentoInteligente({
    required String userId,
    required List<Task> tarefasNegociaveis,
    required int tempoNecessario,
    required DateTime dataOriginal,
  }) async {
    if (tarefasNegociaveis.isEmpty) {
      return {'viavel': false, 'mensagem': 'Nenhuma tarefa pode ser movida.'};
    }

    List<Map<String, dynamic>> tarefasParaMover = [];
    List<Map<String, dynamic>> reagendamentoSugerido = [];
    int tempoLiberado = 0;

    // Tentar encontrar combinação ótima de tarefas para mover
    for (var tarefa in tarefasNegociaveis) {
      if (tempoLiberado >= tempoNecessario) break;

      // Buscar melhor dia para esta tarefa
      final melhorDia = await _encontrarMelhorDiaParaTarefa(
        userId: userId,
        tarefa: tarefa,
        dataOriginal: dataOriginal,
      );

      if (melhorDia != null) {
        tarefasParaMover.add({
          'id': tarefa.id,
          'titulo': tarefa.titulo,
          'duracaoMinutos': tarefa.duracaoMinutos,
          'prioridade': tarefa.prioridade.toJson(),
          'dataAtual': tarefa.dataInicio.toIso8601String(),
        });

        reagendamentoSugerido.add({
          'tarefaId': tarefa.id,
          'titulo': tarefa.titulo,
          'dataAtual': tarefa.dataInicio.toIso8601String(),
          'dataSugerida': melhorDia.toIso8601String(),
          'motivacao': 'Liberar espaço para tarefa de maior prioridade',
        });

        tempoLiberado += tarefa.duracaoMinutos;
      }
    }

    if (tempoLiberado >= tempoNecessario) {
      return {
        'viavel': true,
        'mensagem':
            'Pode agendar movendo ${tarefasParaMover.length} tarefa(s) de menor prioridade.',
        'tarefasParaMover': tarefasParaMover,
        'reagendamentoSugerido': reagendamentoSugerido,
        'tempoLiberado': tempoLiberado,
      };
    }

    return {
      'viavel': false,
      'mensagem':
          'Mesmo movendo tarefas de menor prioridade, não há espaço suficiente.',
      'tarefasParaMover': tarefasParaMover,
      'tempoLiberado': tempoLiberado,
    };
  }

  /// Encontrar o melhor dia para reagendar uma tarefa
  Future<DateTime?> _encontrarMelhorDiaParaTarefa({
    required String userId,
    required Task tarefa,
    required DateTime dataOriginal,
  }) async {
    // Procurar nos próximos 14 dias (excluindo o dia original)
    for (int i = 1; i <= 14; i++) {
      final candidato = dataOriginal.add(Duration(days: i));

      // Pular fins de semana se a tarefa original era em dia útil
      if (_isDiaUtil(dataOriginal) && !_isDiaUtil(candidato)) continue;

      final validacao = await validateDay(
        data: candidato,
        duracaoMinutos: tarefa.duracaoMinutos,
        prioridade: tarefa.prioridade.toJson(),
        userId: userId,
      );

      if (validacao['viavel'] == true) {
        return candidato;
      }
    }

    return null;
  }

  /// Verificar se é dia útil (segunda a sexta)
  bool _isDiaUtil(DateTime data) {
    return data.weekday >= 1 && data.weekday <= 5;
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

      final ocupado = snapshot.docs.fold<int>(0, (total, doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return total;
        return total + ((data['duracaoMinutos'] as num?)?.toInt() ?? 0);
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

  /// Executar reagendamento automático de tarefas
  Future<Map<String, dynamic>> executarReagendamento({
    required String userId,
    required List<Map<String, dynamic>> reagendamentoSugerido,
  }) async {
    try {
      final batch = _firestore.batch();
      final tarefasMovidas = <Map<String, dynamic>>[];

      for (var sugestao in reagendamentoSugerido) {
        final tarefaId = sugestao['tarefaId'] as String;
        final dataSugerida = DateTime.parse(sugestao['dataSugerida'] as String);

        // Buscar tarefa atual
        final tarefaDoc = await _tasksCollection.doc(tarefaId).get();
        if (!tarefaDoc.exists) continue;

        final tarefa = Task.fromJson(tarefaDoc.data() as Map<String, dynamic>);

        // Calcular nova data/hora mantendo o mesmo horário
        final novaDataInicio = DateTime(
          dataSugerida.year,
          dataSugerida.month,
          dataSugerida.day,
          tarefa.dataInicio.hour,
          tarefa.dataInicio.minute,
        );

        final novaDataFim = novaDataInicio.add(
          Duration(minutes: tarefa.duracaoMinutos),
        );

        // Atualizar no batch
        batch.update(_tasksCollection.doc(tarefaId), {
          'dataInicio': Timestamp.fromDate(novaDataInicio),
          'dataFim': Timestamp.fromDate(novaDataFim),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });

        tarefasMovidas.add({
          'id': tarefaId,
          'titulo': tarefa.titulo,
          'dataAnterior': tarefa.dataInicio.toIso8601String(),
          'dataNova': novaDataInicio.toIso8601String(),
        });
      }

      // Executar todas as atualizações
      await batch.commit();

      return {
        'sucesso': true,
        'tarefasMovidas': tarefasMovidas,
        'mensagem':
            'Reagendamento executado com sucesso! ${tarefasMovidas.length} tarefa(s) movida(s).',
      };
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro ao executar reagendamento: $e',
      };
    }
  }

  /// Obter estatísticas semanais para notificações
  Future<Map<String, dynamic>> getWeeklyStats(
      String userId, DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));

      final snapshot = await _tasksCollection
          .where('userId', isEqualTo: userId)
          .where('dataInicio',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('dataInicio', isLessThan: Timestamp.fromDate(weekEnd))
          .get();

      final tasks = snapshot.docs
          .map((doc) => Task.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      final tarefasDefinidas = tasks.length;
      final tarefasConcluidas = tasks.where((t) => t.isConcluida).length;
      final tarefasPendentes = tasks.where((t) => t.isPendente).length;
      final tarefasPuladas = tasks.where((t) => t.isPulada).length;

      final percentualConclusao = tarefasDefinidas > 0
          ? (tarefasConcluidas / tarefasDefinidas * 100).round()
          : 0;

      // Tempo total planejado vs realizado
      final tempoPlaneado =
          tasks.fold<int>(0, (total, t) => total + t.duracaoMinutos);
      final tempoRealizado = tasks
          .where((t) => t.isConcluida && t.tempoRealMinutos != null)
          .fold<int>(0, (total, t) => total + (t.tempoRealMinutos ?? 0));

      return {
        'semanaInicio': weekStart.toIso8601String(),
        'semanaFim': weekEnd.toIso8601String(),
        'tarefasDefinidas': tarefasDefinidas,
        'tarefasConcluidas': tarefasConcluidas,
        'tarefasPendentes': tarefasPendentes,
        'tarefasPuladas': tarefasPuladas,
        'percentualConclusao': percentualConclusao,
        'tempoPlaneadoMinutos': tempoPlaneado,
        'tempoRealizadoMinutos': tempoRealizado,
        'eficienciaTempo': tempoPlaneado > 0
            ? (tempoRealizado / tempoPlaneado * 100).round()
            : 0,
      };
    } catch (e) {
      throw Exception('Erro ao obter estatísticas semanais: $e');
    }
  }
}
