import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_timezone.dart';

/// Serviço para integração com Google Calendar
class GoogleCalendarService {
  static const _calendarScopes = <String>[
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/tasks.readonly',
  ];
  static const _writeScopes = <String>[
    'https://www.googleapis.com/auth/calendar.events',
    'https://www.googleapis.com/auth/tasks',
  ];
  static const _requestTimeout = Duration(seconds: 20);

  GoogleCalendarService({required GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn;

  final GoogleSignIn _googleSignIn;

  calendar.CalendarApi? _calendarApi;

  Future<void> _ensureWriteAccess() async {
    final granted = await _googleSignIn.requestScopes(_writeScopes);
    if (!granted) {
      throw Exception(
          'Acesso de escrita ao Google Calendar/Tasks não autorizado');
    }
  }

  /// Generated Google API models have represented all-day `date` as either a
  /// String or DateTime across versions/platforms. Accept both forms.
  static DateTime? parseGoogleDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Inicializar API do Calendar com autenticação
  Future<void> initialize() async {
    final credentials = await _credentialsForCurrentAccount();
    final client = authenticatedClient(http.Client(), credentials);
    _calendarApi = calendar.CalendarApi(client);
  }

  Future<AccessCredentials> _credentialsForCurrentAccount() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Login com Google cancelado');
    }

    // google_sign_in 6.x documents canAccessScopes as Web-only. On Android,
    // the requested scopes are supplied when the shared GoogleSignIn instance
    // performs sign-in (see AuthService).
    if (kIsWeb) {
      final alreadyGranted =
          await _googleSignIn.canAccessScopes(_calendarScopes);
      if (!alreadyGranted) {
        final granted = await _googleSignIn.requestScopes(_calendarScopes);
        if (!granted) {
          throw Exception('Acesso ao Google Calendar não autorizado');
        }
      }
    }

    final authentication = await account.authentication;
    final accessToken = authentication.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Não foi possível obter autorização do Google Calendar');
    }
    return AccessCredentials(
      AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      _calendarScopes,
    );
  }

  /// Buscar eventos do dia para validação
  Future<List<calendar.Event>> getEventsForDay(DateTime date) async {
    return getEventsForRange(
      AppTimeZone.dayStartUtc(date),
      AppTimeZone.dayEndUtc(date),
    );
  }

  /// Queries a single UTC interval whose civil boundaries are derived from
  /// Africa/Luanda. Pagination is mandatory here: a partial first page is not
  /// an offline cache.
  Future<List<calendar.Event>> getEventsForRange(
      DateTime startInclusive, DateTime endExclusive) async {
    if (_calendarApi == null) await initialize();

    try {
      final calendars = await _calendarApi!.calendarList
          .list(showHidden: false, minAccessRole: 'reader')
          .timeout(_requestTimeout);
      final calendarIds = (calendars.items ?? [])
          .where((entry) => entry.id != null && entry.hidden != true)
          .map((entry) => entry.id!)
          .toSet();
      if (calendarIds.isEmpty) calendarIds.add('primary');

      final events = <calendar.Event>[];
      for (final calendarId in calendarIds) {
        try {
          String? pageToken;
          do {
            final result = await _calendarApi!.events
                .list(
                  calendarId,
                  timeMin: startInclusive.toUtc(),
                  timeMax: endExclusive.toUtc(),
                  singleEvents: true,
                  orderBy: 'startTime',
                  showDeleted: false,
                  maxResults: 2500,
                  pageToken: pageToken,
                )
                .timeout(_requestTimeout);
            events.addAll(result.items ?? const []);
            pageToken = result.nextPageToken;
          } while (pageToken != null && pageToken.isNotEmpty);
        } on calendar.DetailedApiRequestError {
          // Um calendário sem permissão não deve impedir os restantes.
        }
      }

      events.sort((a, b) {
        final aStart = a.start?.dateTime ??
            parseGoogleDate(a.start?.date) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bStart = b.start?.dateTime ??
            parseGoogleDate(b.start?.date) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aStart.compareTo(bStart);
      });
      return events;
    } catch (e) {
      throw Exception('Erro ao buscar eventos: $e');
    }
  }

  Future<List<google_tasks.Task>> getTasksForDay(DateTime date) async {
    return getTasksForRange(
      AppTimeZone.dayStartUtc(date),
      AppTimeZone.dayEndUtc(date),
    );
  }

  Future<List<google_tasks.Task>> getTasksForRange(
      DateTime startInclusive, DateTime endExclusive) async {
    if (_calendarApi == null) await initialize();
    final client = authenticatedClient(
      http.Client(),
      await _credentialsForCurrentAccount(),
    );
    try {
      final tasksApi = google_tasks.TasksApi(client);
      final result = <google_tasks.Task>[];
      String? listPageToken;
      do {
        final lists = await tasksApi.tasklists
            .list(maxResults: 100, pageToken: listPageToken)
            .timeout(_requestTimeout);
        for (final list in lists.items ?? const []) {
          final listId = list.id;
          if (listId == null) continue;
          String? taskPageToken;
          do {
            // Fetch the raw due value and filter locally. Google Tasks returns
            // `due` as an RFC3339 string; local filtering avoids losing tasks
            // when the account/calendar timezone differs from the device.
            final tasks = await tasksApi.tasks
                .list(
                  listId,
                  showCompleted: false,
                  showHidden: false,
                  maxResults: 100,
                  pageToken: taskPageToken,
                )
                .timeout(_requestTimeout);
            for (final task in tasks.items ?? const []) {
              final due = DateTime.tryParse(task.due ?? '')?.toUtc();
              if (due != null &&
                  !due.isBefore(startInclusive.toUtc()) &&
                  due.isBefore(endExclusive.toUtc())) {
                result.add(task);
              }
            }
            taskPageToken = tasks.nextPageToken;
          } while (taskPageToken != null && taskPageToken.isNotEmpty);
        }
        listPageToken = lists.nextPageToken;
      } while (listPageToken != null && listPageToken.isNotEmpty);
      return result;
    } finally {
      client.close();
    }
  }

  /// Mark a Google Task as completed. Google Tasks uses a task-list ID in
  /// addition to the task ID, so locate the owning list before updating it.
  Future<void> completeGoogleTask(String taskId) async {
    await _ensureWriteAccess();
    final client = authenticatedClient(
      http.Client(),
      await _credentialsForCurrentAccount(),
    );
    try {
      final tasksApi = google_tasks.TasksApi(client);
      String? listPageToken;
      do {
        final lists = await tasksApi.tasklists
            .list(maxResults: 100, pageToken: listPageToken)
            .timeout(_requestTimeout);
        for (final list in lists.items ?? const []) {
          final listId = list.id;
          if (listId == null) continue;
          try {
            final task = await tasksApi.tasks
                .get(listId, taskId)
                .timeout(_requestTimeout);
            if (task.id != taskId) continue;
            task.status = 'completed';
            task.completed = DateTime.now().toUtc().toIso8601String();
            await tasksApi.tasks
                .update(task, listId, taskId)
                .timeout(_requestTimeout);
            return;
          } on google_tasks.DetailedApiRequestError {
            // The task is not in this list; continue searching.
          }
        }
        listPageToken = lists.nextPageToken;
      } while (listPageToken != null && listPageToken.isNotEmpty);
      throw Exception('Tarefa Google não encontrada');
    } finally {
      client.close();
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
  Future<calendar.Event?> createEventFromTask({
    required String title,
    required String? description,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    try {
      await _ensureWriteAccess();
      if (_calendarApi == null) await initialize();

      final endTime = startTime.add(Duration(minutes: durationMinutes));

      final event = calendar.Event()
        ..summary = title
        ..description = description ?? ''
        ..start = calendar.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: AppTimeZone.id,
        )
        ..end = calendar.EventDateTime(
          dateTime: endTime.toUtc(),
          timeZone: AppTimeZone.id,
        )
        ..reminders = (calendar.EventReminders()
          ..useDefault = false
          ..overrides = [
            calendar.EventReminder()
              ..method = 'popup'
              ..minutes = 15,
          ]);

      final created = await _calendarApi!.events
          .insert(event, 'primary')
          .timeout(_requestTimeout);
      if (created.id == null || created.id!.isEmpty) {
        throw Exception('O Google não devolveu o ID do evento criado');
      }
      return created;
    } on calendar.DetailedApiRequestError catch (e) {
      // Erro específico da API do Google Calendar
      if (kDebugMode) {
        print('Erro da API do Google Calendar: ${e.status} - ${e.message}');
      }
      if (e.status == 403) {
        if (kDebugMode) {
          print(
              'Permissão negada. Verifique as permissões do Google Calendar.');
        }
      } else if (e.status == 409) {
        if (kDebugMode) {
          print('Conflito ao criar evento. O dia pode estar cheio.');
        }
      }
      throw Exception('Google Calendar (${e.status}): ${e.message}');
    } catch (e) {
      // Outros erros (rede, parsing, etc)
      if (kDebugMode) {
        print('Erro inesperado ao criar evento no Google Calendar: $e');
      }
      throw Exception('Falha ao criar evento no Google Calendar: $e');
    }
  }

  /// Atualizar evento existente
  Future<calendar.Event?> updateEvent({
    required String eventId,
    required String title,
    required String? description,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    try {
      await _ensureWriteAccess();
      if (_calendarApi == null) await initialize();

      final endTime = startTime.add(Duration(minutes: durationMinutes));

      final event = calendar.Event()
        ..summary = title
        ..description = description ?? ''
        ..start = calendar.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: AppTimeZone.id,
        )
        ..end = calendar.EventDateTime(
          dateTime: endTime.toUtc(),
          timeZone: AppTimeZone.id,
        );

      return await _calendarApi!.events
          .update(event, 'primary', eventId)
          .timeout(_requestTimeout);
    } on calendar.DetailedApiRequestError catch (e) {
      if (kDebugMode) {
        print(
            'Erro da API do Google Calendar ao atualizar: ${e.status} - ${e.message}');
      }
      throw Exception('Google Calendar (${e.status}): ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Erro inesperado ao atualizar evento no Google Calendar: $e');
      }
      throw Exception('Falha ao atualizar evento no Google Calendar: $e');
    }
  }

  /// Atualizar evento no Google Calendar a partir de uma tarefa
  Future<calendar.Event?> updateEventFromTask({
    required String eventId,
    required String title,
    required String? description,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    return updateEvent(
      eventId: eventId,
      title: title,
      description: description,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );
  }

  /// Deletar evento
  Future<void> deleteEvent(String eventId) async {
    await _ensureWriteAccess();
    if (_calendarApi == null) await initialize();

    try {
      await _calendarApi!.events
          .delete('primary', eventId)
          .timeout(_requestTimeout);
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
