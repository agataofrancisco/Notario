import '../../features/tasks/domain/entities/task.dart';
import '../../features/tasks/data/repositories/task_repository.dart';

/// Serviço para calcular estatísticas diárias
class StatisticsService {
  final TaskRepository _taskRepository;

  StatisticsService(this._taskRepository);

  /// Calcula estatísticas para um dia específico
  Future<DailyStats> calculateDailyStats(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final tasks = await _taskRepository.getByDate(userId, startOfDay);

    final totalTasks = tasks.length;
    final completedTasks =
        tasks.where((t) => t.estado == EstadoTarefa.concluida).length;
    final cancelledTasks =
        tasks.where((t) => t.estado == EstadoTarefa.cancelada).length;
    final skippedTasks =
        tasks.where((t) => t.estado == EstadoTarefa.pulada).length;
    final pendingTasks =
        tasks.where((t) => t.estado == EstadoTarefa.pendente).length;

    final plannedMinutes =
        tasks.fold<int>(0, (sum, task) => sum + task.duracaoMinutos);
    final actualMinutes = tasks
        .where((t) => t.tempoRealMinutos != null)
        .fold<int>(0, (sum, task) => sum + (task.tempoRealMinutos ?? 0));

    // Calcular pontuação (0-100)
    double score = 0;
    if (totalTasks > 0) {
      final completionRate = completedTasks / totalTasks;
      final efficiencyRate = plannedMinutes > 0
          ? (actualMinutes / plannedMinutes).clamp(0.0, 1.5)
          : 1.0;

      // Pontuação baseada em conclusão (70%) e eficiência (30%)
      score =
          (completionRate * 70) + ((1.0 - (efficiencyRate - 1.0).abs()) * 30);
    }

    return DailyStats(
      date: startOfDay,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      cancelledTasks: cancelledTasks,
      skippedTasks: skippedTasks,
      pendingTasks: pendingTasks,
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes,
      score: score.clamp(0, 100),
    );
  }

  /// Calcula estatísticas para uma semana
  Future<List<DailyStats>> calculateWeeklyStats(
      String userId, DateTime weekStart) async {
    final stats = <DailyStats>[];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dailyStats = await calculateDailyStats(userId, date);
      stats.add(dailyStats);
    }
    return stats;
  }

  /// Calcula estatísticas gerais do usuário
  Future<OverallStats> calculateOverallStats(String userId) async {
    final allTasks = await _taskRepository.getByUserId(userId);

    final totalTasks = allTasks.length;
    final completedTasks =
        allTasks.where((t) => t.estado == EstadoTarefa.concluida).length;
    final totalPlannedMinutes =
        allTasks.fold<int>(0, (sum, task) => sum + task.duracaoMinutos);
    final totalActualMinutes = allTasks
        .where((t) => t.tempoRealMinutos != null)
        .fold<int>(0, (sum, task) => sum + (task.tempoRealMinutos ?? 0));

    // Calcular streak (dias consecutivos com tarefas concluídas)
    int currentStreak = 0;
    int maxStreak = 0;
    DateTime? lastCompletedDate;

    final completedByDate = <DateTime, int>{};
    for (var task
        in allTasks.where((t) => t.estado == EstadoTarefa.concluida)) {
      final date = DateTime(
          task.dataInicio.year, task.dataInicio.month, task.dataInicio.day);
      completedByDate[date] = (completedByDate[date] ?? 0) + 1;
    }

    final sortedDates = completedByDate.keys.toList()..sort();
    for (var date in sortedDates.reversed) {
      if (lastCompletedDate == null) {
        currentStreak = 1;
        lastCompletedDate = date;
      } else {
        final diff = lastCompletedDate.difference(date).inDays;
        if (diff == 1) {
          currentStreak++;
          lastCompletedDate = date;
        } else {
          break;
        }
      }
      if (currentStreak > maxStreak) maxStreak = currentStreak;
    }

    return OverallStats(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      totalPlannedHours: (totalPlannedMinutes / 60).round(),
      totalActualHours: (totalActualMinutes / 60).round(),
      currentStreak: currentStreak,
      maxStreak: maxStreak,
      completionRate: totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0,
    );
  }
}

/// Estatísticas diárias
class DailyStats {
  final DateTime date;
  final int totalTasks;
  final int completedTasks;
  final int cancelledTasks;
  final int skippedTasks;
  final int pendingTasks;
  final int plannedMinutes;
  final int actualMinutes;
  final double score;

  DailyStats({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    required this.cancelledTasks,
    required this.skippedTasks,
    required this.pendingTasks,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.score,
  });

  bool get hasData => totalTasks > 0;
  double get completionRate =>
      totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0;
}

/// Estatísticas gerais
class OverallStats {
  final int totalTasks;
  final int completedTasks;
  final int totalPlannedHours;
  final int totalActualHours;
  final int currentStreak;
  final int maxStreak;
  final double completionRate;

  OverallStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.totalPlannedHours,
    required this.totalActualHours,
    required this.currentStreak,
    required this.maxStreak,
    required this.completionRate,
  });
}
