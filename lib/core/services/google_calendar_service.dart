import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Serviço para integração com Google Calendar
class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  calendar.CalendarApi? _calendarApi;

  /// Inicializar API do Calendar com autenticação
  Future<void> initialize() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Login com Google cancelado');
    }

    final authentication = await account.authentication;
    final credentials = AccessCredentials(
      AccessToken(
        'Bearer',
        authentication.accessToken!,
        DateTime.now().add(const Duration(hours: 1)),
      ),
      null,
      [
        'https://www.googleapis.com/auth/calendar',
        'https://www.googleapis.com/auth/calendar.events',
      ],
    );

    final client = authenticatedClient(http.Client(), credentials);
    _calendarApi = calendar.CalendarApi(client);
  }

  /// Buscar eventos do dia para validação
  Future<List<calendar.Event>> getEventsForDay(DateTime date) async {
    if (_calendarApi == null) await initialize();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startOfDay.toUtc(),
        timeMax: endOfDay.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      throw Exception('Erro ao buscar eventos: $e');
    }
  }

  /// Calcular minutos ocupados por eventos do Google Calendar
  Future<int> calculateOccupiedMinutes(DateTime date) async {
    final events = await getEventsForDay(date);
    int totalMinutes = 0;

    for (var event in events) {
      if (event.start?.dateTime != null && event.end?.dateTime != null) {
        final start = event.start!.dateTime!;
        final end = event.end!.dateTime!;
        final duration = end.difference(start).inMinutes;
        totalMinutes += duration;
      }
    }

    return totalMinutes;
  }

  /// Criar evento no Google Calendar a partir de uma tarefa
  Future<calendar.Event> createEventFromTask({
    required String title,
    required String? description,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    if (_calendarApi == null) await initialize();

    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final event = calendar.Event()
      ..summary = title
      ..description = description ?? ''
      ..start = calendar.EventDateTime(
        dateTime: startTime.toUtc(),
        timeZone: 'UTC',
      )
      ..end = calendar.EventDateTime(
        dateTime: endTime.toUtc(),
        timeZone: 'UTC',
      )
      ..reminders = (calendar.EventReminders()
        ..useDefault = false
        ..overrides = [
          calendar.EventReminder()
            ..method = 'popup'
            ..minutes = 15,
        ]);

    try {
      return await _calendarApi!.events.insert(event, 'primary');
    } catch (e) {
      throw Exception('Erro ao criar evento: $e');
    }
  }

  /// Atualizar evento existente
  Future<calendar.Event> updateEvent({
    required String eventId,
    required String title,
    required String? description,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    if (_calendarApi == null) await initialize();

    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final event = calendar.Event()
      ..summary = title
      ..description = description ?? ''
      ..start = calendar.EventDateTime(
        dateTime: startTime.toUtc(),
        timeZone: 'UTC',
      )
      ..end = calendar.EventDateTime(
        dateTime: endTime.toUtc(),
        timeZone: 'UTC',
      );

    try {
      return await _calendarApi!.events.update(event, 'primary', eventId);
    } catch (e) {
      throw Exception('Erro ao atualizar evento: $e');
    }
  }

  /// Deletar evento
  Future<void> deleteEvent(String eventId) async {
    if (_calendarApi == null) await initialize();

    try {
      await _calendarApi!.events.delete('primary', eventId);
    } catch (e) {
      throw Exception('Erro ao deletar evento: $e');
    }
  }

  /// Verificar se usuário tem permissão de Calendar
  Future<bool> hasCalendarPermission() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return false;

      final auth = await account.authentication;
      return auth.accessToken != null;
    } catch (e) {
      return false;
    }
  }
}
