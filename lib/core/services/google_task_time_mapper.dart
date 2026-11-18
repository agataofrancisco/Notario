import '../config/app_timezone.dart';

/// Maps Google Tasks' date-only due value onto the app's civil calendar.
/// Google documents that the time component of `due` is ignored, so the task
/// receives a predictable 09:00 planning slot and an end-of-day deadline in
/// Africa/Luanda.
class GoogleTaskTimeMapper {
  const GoogleTaskTimeMapper._();

  static DateTime? plannedStart(String? rawDue) {
    final date = _civilDate(rawDue);
    if (date == null) return null;
    return AppTimeZone.at(date, 9, 0).toUtc();
  }

  static DateTime? deadline(String? rawDue) {
    final date = _civilDate(rawDue);
    if (date == null) return null;
    return AppTimeZone.dayEndUtc(date)
        .subtract(const Duration(milliseconds: 1));
  }

  static DateTime? _civilDate(String? rawDue) {
    if (rawDue == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(rawDue);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }
}
