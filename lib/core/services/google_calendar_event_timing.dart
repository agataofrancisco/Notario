import '../config/app_timezone.dart';
import 'google_calendar_service.dart';

class GoogleCalendarEventTiming {
  static const defaultFocusMinutes = 30;

  final DateTime startUtc;
  final int durationMinutes;

  const GoogleCalendarEventTiming({
    required this.startUtc,
    required this.durationMinutes,
  });

  /// Timed events keep their exact instants. An all-day event has no focus
  /// window, so keep its civil date and assign a short, editable focus slot.
  static GoogleCalendarEventTiming? fromGoogle({
    required DateTime? timedStart,
    required DateTime? timedEnd,
    required Object? allDayStart,
  }) {
    if (timedStart != null) {
      final startUtc = timedStart.toUtc();
      final minutes = timedEnd?.toUtc().difference(startUtc).inMinutes ?? 0;
      return GoogleCalendarEventTiming(
        startUtc: startUtc,
        durationMinutes: minutes > 0 ? minutes : defaultFocusMinutes,
      );
    }

    final civilDate = GoogleCalendarService.parseGoogleDate(allDayStart);
    if (civilDate == null) return null;
    return GoogleCalendarEventTiming(
      startUtc: AppTimeZone.at(civilDate, 9, 0).toUtc(),
      durationMinutes: defaultFocusMinutes,
    );
  }
}
