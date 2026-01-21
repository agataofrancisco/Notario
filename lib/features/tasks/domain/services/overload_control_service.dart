import '../../domain/entities/task.dart';

class OverloadControlService {
  /// Verifica se é possível adicionar uma nova tarefa ao dia
  /// Retorna null se for possível, ou a próxima data disponível data se não for
  static DateTime? checkAvailability(
    List<Task> existingTasks,
    DateTime proposedStart,
    int durationMinutes,
  ) {
    if (existingTasks.isEmpty) return null;

    final proposedEnd = proposedStart.add(Duration(minutes: durationMinutes));

    // Ordenar tarefas por data de início
    final tasks = List<Task>.from(existingTasks)
      ..sort((a, b) => a.dataInicio.compareTo(b.dataInicio));

    // 1. Verificar conflito direto
    for (var task in tasks) {
      if (_hasOverlap(
          proposedStart, proposedEnd, task.dataInicio, task.dataFim)) {
        return _findNextSlot(tasks, durationMinutes);
      }
    }

    // 2. Verificar carga total do dia (limite de 12h de trabalho produtivo, por exemplo)
    int totalMinutes = tasks.fold(0, (sum, t) => sum + t.duracaoMinutos);
    if (totalMinutes + durationMinutes > 12 * 60) {
      // Dia cheio, sugere amanhã
      return DateTime(
          proposedStart.year, proposedStart.month, proposedStart.day + 1, 9, 0);
    }

    return null; // Disponível
  }

  static bool _hasOverlap(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  static DateTime _findNextSlot(List<Task> tasks, int durationMinutes) {
    // Começa a procurar a partir do fim da última tarefa ou agora
    DateTime candidateStart = DateTime.now();
    if (tasks.isNotEmpty) {
      // Tenta encaixar nos buracos
      for (int i = 0; i < tasks.length - 1; i++) {
        final currentEnd = tasks[i].dataFim;
        final nextStart = tasks[i + 1].dataInicio;

        if (nextStart.difference(currentEnd).inMinutes >= durationMinutes) {
          // Encontrou um buraco!
          return currentEnd
              .add(const Duration(minutes: 5)); // +5 min de intervalo
        }
      }

      // Se não, sugere após a última tarefa
      candidateStart = tasks.last.dataFim.add(const Duration(minutes: 15));
    }

    // Não permitir agendamento muito tarde (ex: após 22h)
    if (candidateStart.hour >= 22) {
      return DateTime(candidateStart.year, candidateStart.month,
          candidateStart.day + 1, 9, 0);
    }

    return candidateStart;
  }
}
