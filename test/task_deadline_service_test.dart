import 'package:flutter_test/flutter_test.dart';
import 'package:notario/core/config/app_timezone.dart';
import 'package:notario/features/tasks/domain/entities/task.dart';
import 'package:notario/features/tasks/domain/services/task_deadline_service.dart';

void main() {
  late DateTime now;
  setUp(() {
    AppTimeZone.initialize();
    now = AppTimeZone.at(DateTime(2026, 11, 17), 10, 0);
  });

  Task task({
    String id = 'task',
    DateTime? deadline,
    int duration = 60,
    Prioridade priority = Prioridade.media,
    EstadoTarefa state = EstadoTarefa.pendente,
    DateTime? start,
    int? actualMinutes,
    String remoteType = 'local',
  }) {
    final starts = start ?? AppTimeZone.at(DateTime(2026, 11, 16), 9, 0);
    return Task(
      id: id,
      userId: 'user',
      titulo: id,
      dataInicio: starts,
      dataFim: starts.add(Duration(minutes: duration)),
      duracaoMinutos: duration,
      prioridade: priority,
      criadoEm: now,
      atualizadoEm: now,
      deadline: deadline,
      estado: state,
      tempoRealMinutos: actualMinutes,
      remoteType: remoteType,
    );
  }

  group('deadline persistence and validation', () {
    test('legacy Firestore map remains valid without deadline', () {
      final legacy = Task.fromJson({
        'id': 'legacy',
        'userId': 'user',
        'titulo': 'Legacy',
        'dataInicio': '2026-11-17T09:00:00.000Z',
        'dataFim': '2026-11-17T10:00:00.000Z',
        'duracaoMinutos': 60,
        'prioridade': 'media',
        'criadoEm': '2026-11-16T10:00:00.000Z',
        'atualizadoEm': '2026-11-16T10:00:00.000Z',
      });

      expect(legacy.deadline, isNull);
    });

    test('deadline round-trips through SQLite map as UTC', () {
      final original =
          task(deadline: AppTimeZone.at(DateTime(2026, 11, 20), 15, 30));
      final restored = Task.fromMap(original.toMap());
      final firestoreRestored = Task.fromJson(original.toJson());

      expect(restored.deadline?.millisecondsSinceEpoch,
          original.deadline?.millisecondsSinceEpoch);
      expect(firestoreRestored.deadline?.millisecondsSinceEpoch,
          original.deadline?.millisecondsSinceEpoch);
      expect(restored.toMap()['deadline'], '2026-11-20T14:30:00.000Z');
    });

    test('deadline clearing is explicit and planned-end boundary is accepted',
        () {
      final original =
          task(deadline: AppTimeZone.at(DateTime(2026, 11, 20), 15, 30));
      expect(original.copyWith(clearDeadline: true).deadline, isNull);
      expect(
        TaskDeadlineService.isValid(
          deadline: DateTime.utc(2026, 11, 17, 11),
          plannedEnd: DateTime.utc(2026, 11, 17, 11),
        ),
        isTrue,
      );
      expect(
        TaskDeadlineService.isValid(
          deadline: DateTime.utc(2026, 11, 17, 10, 59),
          plannedEnd: DateTime.utc(2026, 11, 17, 11),
        ),
        isFalse,
      );
    });
  });

  group('deadline urgency', () {
    test('classifies overdue, today, soon and later from a fixed clock', () {
      expect(
          TaskDeadlineService.contextFor(
                  task(deadline: now.subtract(const Duration(minutes: 1))), now)
              ?.urgency,
          DeadlineUrgency.overdue);
      expect(
          TaskDeadlineService.contextFor(
                  task(deadline: AppTimeZone.at(DateTime(2026, 11, 17), 18, 0)),
                  now)
              ?.urgency,
          DeadlineUrgency.today);
      expect(
          TaskDeadlineService.contextFor(
                  task(deadline: AppTimeZone.at(DateTime(2026, 11, 19), 18, 0)),
                  now)
              ?.urgency,
          DeadlineUrgency.soon);
      expect(
          TaskDeadlineService.contextFor(
                  task(deadline: AppTimeZone.at(DateTime(2026, 11, 25), 18, 0)),
                  now)
              ?.urgency,
          DeadlineUrgency.later);
    });
  });

  group('daily guidance', () {
    test('ranks deadlines then priority and fit, with stable id tie-breaks',
        () {
      final completedToday = task(
        id: 'today',
        start: AppTimeZone.at(DateTime(2026, 11, 17), 8, 0),
        duration: 120,
        state: EstadoTarefa.concluida,
        actualMinutes: 30,
      );
      final sameDeadline = AppTimeZone.at(DateTime(2026, 11, 20), 12, 0);
      final tasks = [
        completedToday,
        task(
            id: 'overdue',
            deadline: now.subtract(const Duration(days: 1)),
            priority: Prioridade.baixa),
        task(
            id: 'later',
            deadline: sameDeadline.add(const Duration(hours: 1)),
            duration: 30),
        task(
            id: 'high-flex',
            deadline: sameDeadline,
            priority: Prioridade.alta,
            duration: 45),
        task(
            id: 'high-a',
            deadline: sameDeadline,
            priority: Prioridade.alta,
            duration: 30),
        task(
            id: 'high-z',
            deadline: sameDeadline,
            priority: Prioridade.alta,
            duration: 30),
        task(
            id: 'medium',
            deadline: sameDeadline,
            priority: Prioridade.media,
            duration: 30),
        task(
            id: 'low',
            deadline: sameDeadline,
            priority: Prioridade.baixa,
            duration: 30),
        task(id: 'too-long', deadline: sameDeadline, duration: 1000),
        task(id: 'no-deadline'),
        task(id: 'done', deadline: sameDeadline, state: EstadoTarefa.concluida),
        task(
            id: 'active',
            deadline: sameDeadline,
            state: EstadoTarefa.emExecucao),
        task(id: 'skipped', deadline: sameDeadline, state: EstadoTarefa.pulada),
        task(
            id: 'cancelled',
            deadline: sameDeadline,
            state: EstadoTarefa.cancelada),
        task(
            id: 'event', deadline: sameDeadline, remoteType: 'google_calendar'),
      ];

      final result =
          const DeadlineGuidanceService().evaluate(now: now, tasks: tasks);

      expect(result.planComplete, isTrue);
      expect(result.freeMinutes, 810);
      expect(result.suggestions.map((item) => item.task.id),
          ['overdue', 'high-flex', 'high-a']);
      expect(result.suggestions, hasLength(3));
      expect(result.suggestions.first.reason, contains('Está atrasada'));
    });

    test('does not suggest work when today still has pending work', () {
      final pendingToday =
          task(start: AppTimeZone.at(DateTime(2026, 11, 17), 16, 0));
      final candidate =
          task(id: 'candidate', deadline: now.add(const Duration(days: 1)));

      final result = const DeadlineGuidanceService()
          .evaluate(now: now, tasks: [pendingToday, candidate]);

      expect(result.planComplete, isFalse);
      expect(result.suggestions, isEmpty);
    });

    test('does not suggest tasks when completed work used all daily capacity',
        () {
      final completedAtCapacity = task(
        id: 'today-full',
        start: AppTimeZone.at(DateTime(2026, 11, 17), 8, 0),
        duration: 840,
        actualMinutes: 840,
        state: EstadoTarefa.concluida,
      );
      final candidate =
          task(id: 'candidate', deadline: now.add(const Duration(days: 1)));

      final result = const DeadlineGuidanceService()
          .evaluate(now: now, tasks: [completedAtCapacity, candidate]);

      expect(result.planComplete, isTrue);
      expect(result.freeMinutes, 0);
      expect(result.suggestions, isEmpty);
    });

    test('does not suggest work without a deadline', () {
      final completedToday = task(
        id: 'today',
        start: AppTimeZone.at(DateTime(2026, 11, 17), 8, 0),
        duration: 120,
        state: EstadoTarefa.concluida,
        actualMinutes: 30,
      );
      final noDeadline = task(id: 'no-deadline');

      final result = const DeadlineGuidanceService()
          .evaluate(now: now, tasks: [completedToday, noDeadline]);

      expect(result.suggestions, isEmpty);
    });
  });
}
