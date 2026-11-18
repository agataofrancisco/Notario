import 'package:flutter_test/flutter_test.dart';
import 'package:notario/core/config/app_timezone.dart';
import 'package:notario/core/services/google_task_time_mapper.dart';
import 'package:notario/core/services/google_calendar_event_timing.dart';

void main() {
  setUp(AppTimeZone.initialize);

  test('Luanda civil day boundaries are stored as UTC instants', () {
    final day = DateTime(2026, 11, 17);
    final start = AppTimeZone.dayStartUtc(day);
    final end = AppTimeZone.dayEndUtc(day);

    expect(start, DateTime.utc(2026, 11, 16, 23));
    expect(end, DateTime.utc(2026, 11, 17, 23));
    expect(end.difference(start), const Duration(days: 1));
  });

  test('a Google Tasks date-only due date gets its Luanda planning time', () {
    final dueDate = DateTime(2026, 11, 17);

    expect(
        AppTimeZone.at(dueDate, 9, 0).toUtc(), DateTime.utc(2026, 11, 17, 8));
  });

  test('a Google Tasks due date maps to Luanda end of day as its deadline', () {
    const due = '2026-11-17T00:00:00.000Z';

    expect(
        GoogleTaskTimeMapper.plannedStart(due), DateTime.utc(2026, 11, 17, 8));
    expect(GoogleTaskTimeMapper.deadline(due),
        DateTime.utc(2026, 11, 17, 22, 59, 59, 999));
  });

  test('invalid Google Tasks due dates are ignored', () {
    expect(GoogleTaskTimeMapper.plannedStart('2026-02-30'), isNull);
    expect(GoogleTaskTimeMapper.deadline(null), isNull);
  });

  test('Google all-day events keep the civil date without consuming 24 hours',
      () {
    final timing = GoogleCalendarEventTiming.fromGoogle(
      timedStart: null,
      timedEnd: null,
      allDayStart: '2026-11-17',
    );

    expect(timing?.startUtc, DateTime.utc(2026, 11, 17, 8));
    expect(timing?.durationMinutes, 30);
  });

  test('timed Google events preserve their exact UTC interval', () {
    final timing = GoogleCalendarEventTiming.fromGoogle(
      timedStart: DateTime.utc(2026, 11, 17, 12),
      timedEnd: DateTime.utc(2026, 11, 17, 13, 15),
      allDayStart: null,
    );

    expect(timing?.startUtc, DateTime.utc(2026, 11, 17, 12));
    expect(timing?.durationMinutes, 75);
  });
}
