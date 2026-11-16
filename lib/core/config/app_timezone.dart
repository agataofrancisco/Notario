import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The product has one civil time zone.  Keep all day boundaries and
/// notification scheduling anchored here instead of inheriting the device.
class AppTimeZone {
  static const id = 'Africa/Luanda';

  static void initialize() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(id));
  }

  static tz.TZDateTime dayStart(DateTime date) =>
      tz.TZDateTime(tz.local, date.year, date.month, date.day);

  static DateTime dayStartUtc(DateTime date) => dayStart(date).toUtc();
  static DateTime dayEndUtc(DateTime date) =>
      dayStart(date).add(const Duration(days: 1)).toUtc();

  static DateTime now() => tz.TZDateTime.now(tz.local);

  static tz.TZDateTime inAppZone(DateTime instant) =>
      tz.TZDateTime.from(instant, tz.local);

  static tz.TZDateTime at(DateTime day, int hour, int minute) =>
      tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
}
