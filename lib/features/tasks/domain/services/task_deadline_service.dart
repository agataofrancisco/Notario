import '../../../../core/config/app_timezone.dart';
import '../../../../core/config/app_config.dart';
import '../entities/task.dart';

enum DeadlineUrgency { none, overdue, today, soon, later }

class DeadlineContext {
  final DeadlineUrgency urgency;
  final String label;
  final DateTime deadline;

  const DeadlineContext(this.urgency, this.label, this.deadline);
}

/// Small, deterministic deadline rules. [now] is passed in so boundaries are
/// stable in tests and the app never needs a paid recommendation service.
class TaskDeadlineService {
  static const nearTermHorizon = Duration(days: 3);

  static bool isValid(
          {required DateTime? deadline, required DateTime plannedEnd}) =>
      deadline == null || !deadline.isBefore(plannedEnd);

  static DeadlineContext? contextFor(Task task, DateTime now) {
    final deadline = task.deadline;
    if (deadline == null) return null;
    final nowUtc = now.toUtc();
    final deadlineUtc = deadline.toUtc();
    final nowLocal = AppTimeZone.inAppZone(nowUtc);
    final deadlineLocal = AppTimeZone.inAppZone(deadlineUtc);
    final sameDay = nowLocal.year == deadlineLocal.year &&
        nowLocal.month == deadlineLocal.month &&
        nowLocal.day == deadlineLocal.day;

    if (deadlineUtc.isBefore(nowUtc)) {
      return DeadlineContext(
          DeadlineUrgency.overdue, 'Prazo ultrapassado', deadlineUtc);
    }
    if (sameDay) {
      return DeadlineContext(
          DeadlineUrgency.today,
          'Prazo hoje, às ${_time(deadlineLocal.hour, deadlineLocal.minute)}',
          deadlineUtc);
    }
    if (!deadlineUtc.isAfter(nowUtc.add(nearTermHorizon))) {
      final todayStart = AppTimeZone.dayStart(nowLocal);
      final deadlineDay = AppTimeZone.dayStart(deadlineLocal);
      final daysUntil = deadlineDay.difference(todayStart).inDays;
      final label =
          daysUntil == 1 ? 'Prazo amanhã' : 'Prazo em $daysUntil dias';
      return DeadlineContext(DeadlineUrgency.soon, label, deadlineUtc);
    }
    return DeadlineContext(
        DeadlineUrgency.later,
        'Prazo ${deadlineLocal.day.toString().padLeft(2, '0')}/${deadlineLocal.month.toString().padLeft(2, '0')}/${deadlineLocal.year}',
        deadlineUtc);
  }

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class DeadlineSuggestion {
  final Task task;
  final String reason;

  const DeadlineSuggestion({required this.task, required this.reason});
}

class DailyGuidance {
  final bool planComplete;
  final int freeMinutes;
  final List<DeadlineSuggestion> suggestions;

  const DailyGuidance({
    required this.planComplete,
    required this.freeMinutes,
    required this.suggestions,
  });
}

class DeadlineGuidanceService {
  const DeadlineGuidanceService();

  DailyGuidance evaluate({
    required DateTime now,
    required List<Task> tasks,
  }) {
    final today = AppTimeZone.inAppZone(now);
    final todayTasks = tasks.where((task) {
      final start = AppTimeZone.inAppZone(task.dataInicio);
      return start.year == today.year &&
          start.month == today.month &&
          start.day == today.day &&
          !task.isCancelada &&
          !task.isPulada;
    }).toList();

    final planComplete = todayTasks.isNotEmpty &&
        todayTasks.every(
          (task) => task.isConcluida,
        );
    const dailyCapacityMinutes = AppConfig.workMinutesPerDay;
    final occupiedMinutes = todayTasks.fold<int>(0, (sum, task) {
      if (task.isConcluida) {
        return sum + (task.tempoRealMinutos ?? task.duracaoMinutos);
      }
      return sum + task.duracaoMinutos;
    });
    final freeMinutes = (dailyCapacityMinutes - occupiedMinutes)
        .clamp(0, dailyCapacityMinutes)
        .toInt();

    if (!planComplete || freeMinutes == 0) {
      return DailyGuidance(
          planComplete: planComplete,
          freeMinutes: freeMinutes,
          suggestions: const []);
    }

    final eligible = tasks.where((task) {
      return task.isPendente &&
          task.remoteType != 'google_calendar' &&
          task.deadline != null &&
          task.duracaoMinutos > 0 &&
          task.duracaoMinutos <= freeMinutes;
    }).toList();

    eligible.sort((a, b) {
      final aDeadline = a.deadline!.toUtc();
      final bDeadline = b.deadline!.toUtc();
      final aOverdue = aDeadline.isBefore(now.toUtc());
      final bOverdue = bDeadline.isBefore(now.toUtc());
      if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
      final deadlineOrder = aDeadline.compareTo(bDeadline);
      if (deadlineOrder != 0) return deadlineOrder;
      final priorityOrder =
          _priorityRank(b.prioridade).compareTo(_priorityRank(a.prioridade));
      if (priorityOrder != 0) return priorityOrder;
      final slackOrder = (freeMinutes - a.duracaoMinutos)
          .compareTo(freeMinutes - b.duracaoMinutos);
      if (slackOrder != 0) return slackOrder;
      final plannedOrder = a.dataInicio.compareTo(b.dataInicio);
      return plannedOrder != 0 ? plannedOrder : a.id.compareTo(b.id);
    });

    return DailyGuidance(
      planComplete: true,
      freeMinutes: freeMinutes,
      suggestions: eligible.take(3).map((task) {
        final context = TaskDeadlineService.contextFor(task, now)!;
        final priority = task.prioridade.displayName.toLowerCase();
        final reason = context.urgency == DeadlineUrgency.overdue
            ? 'Está atrasada, tem prioridade $priority e cabe nos $freeMinutes min livres.'
            : '${context.label}, prioridade $priority e cabe nos $freeMinutes min livres.';
        return DeadlineSuggestion(task: task, reason: reason);
      }).toList(growable: false),
    );
  }

  int _priorityRank(Prioridade priority) => switch (priority) {
        Prioridade.alta => 3,
        Prioridade.media => 2,
        Prioridade.baixa => 1,
      };
}
