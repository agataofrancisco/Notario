import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_timezone.dart';
import 'auth_service.dart';
import 'google_task_time_mapper.dart';

enum GoogleCalendarFailure {
  disconnected,
  permissionDenied,
  reauthorizationRequired,
  remote
}

class GoogleCalendarException implements Exception {
  final GoogleCalendarFailure failure;
  final String message;

  const GoogleCalendarException(this.failure, this.message);

  @override
  String toString() => message;
}

/// Serviço para integração com Google Calendar
class GoogleCalendarService {
  static const connectionPreferenceKey = 'google_calendar_connected_v1';
  static const _calendarScopes = AuthService.calendarScopes;
  static const _requestTimeout = Duration(seconds: 20);

  GoogleCalendarService({
    required AuthService authService,
    required SharedPreferences preferences,
  })  : _authService = authService,
        _googleSignIn = authService.googleSignIn,
        _preferences = preferences;

  final AuthService _authService;
  final GoogleSignIn _googleSignIn;
  final SharedPreferences _preferences;

  calendar.CalendarApi? _calendarApi;

  GoogleCalendarException _apiException(int? status, Object error) {
    if (status == 401) {
      return const GoogleCalendarException(
        GoogleCalendarFailure.reauthorizationRequired,
        'A autorização Google expirou. Liga o Calendar novamente.',
      );
    }
    if (status == 403) {
      return const GoogleCalendarException(
        GoogleCalendarFailure.permissionDenied,
        'O Google recusou o acesso ao Calendar ou às Tasks. Verifica as permissões.',
      );
    }
    return GoogleCalendarException(
        GoogleCalendarFailure.remote, 'Falha na API Google ($status): $error');
  }

  Future<bool> get isConnected async =>
      _preferences.getBool(connectionPreferenceKey) ?? false;

  Future<bool> connect() async {
    try {
      final granted = await _authService.requestCalendarAccess();
      if (!granted) {
        throw const GoogleCalendarException(
          GoogleCalendarFailure.permissionDenied,
          'Acesso ao Google Calendar não autorizado.',
        );
      }
      await _preferences.setBool(connectionPreferenceKey, true);
      _calendarApi = null;
      return true;
    } on GoogleCalendarException {
      rethrow;
    } catch (error) {
      throw GoogleCalendarException(GoogleCalendarFailure.remote,
          'Não foi possível ligar o Calendar: $error');
    }
  }

  Future<void> disconnect() async {
    await _preferences.setBool(connectionPreferenceKey, false);
    _calendarApi = null;
    try {
      await _authService.disconnectGoogleAccess();
    } catch (error) {
      if (kDebugMode) debugPrint('Calendar disconnected locally: $error');
    }
  }

  Future<void> _ensureWriteAccess() async {
    if (!await isConnected) {
      throw const GoogleCalendarException(
        GoogleCalendarFailure.disconnected,
        'Liga o Google Calendar nas definições da agenda para sincronizar.',
      );
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
    if (!await isConnected) {
      throw const GoogleCalendarException(
        GoogleCalendarFailure.disconnected,
        'Google Calendar não está ligado.',
      );
    }
    final account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      await _preferences.setBool(connectionPreferenceKey, false);
      throw const GoogleCalendarException(
        GoogleCalendarFailure.reauthorizationRequired,
        'A sessão Google expirou. Liga o Calendar novamente.',
      );
    }

    // Web needs an explicit scope validity check; mobile keeps the user's
    // granted scopes with the same Google account session.
    if (kIsWeb) {
      final alreadyGranted =
          await _googleSignIn.canAccessScopes(_calendarScopes);
      if (!alreadyGranted) {
        await _preferences.setBool(connectionPreferenceKey, false);
        throw const GoogleCalendarException(
          GoogleCalendarFailure.reauthorizationRequired,
          'A autorização do Google expirou. Liga o Calendar novamente.',
        );
      }
    }

    final authentication = await account.authentication;
    final accessToken = authentication.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      await _preferences.setBool(connectionPreferenceKey, false);
      throw const GoogleCalendarException(
        GoogleCalendarFailure.reauthorizationRequired,
        'Não foi possível obter autorização. Liga o Calendar novamente.',
      );
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
      var readAtLeastOneCalendar = false;
      var inaccessibleCalendar = false;
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
            readAtLeastOneCalendar = true;
            events.addAll(result.items ?? const []);
            pageToken = result.nextPageToken;
          } while (pageToken != null && pageToken.isNotEmpty);
        } on calendar.DetailedApiRequestError catch (error) {
          // A single inaccessible calendar must not hide accessible calendars.
          if (error.status == 401) throw _apiException(error.status, error);
          if (error.status == 403) {
            inaccessibleCalendar = true;
          } else {
            throw _apiException(error.status, error);
          }
        }
      }
      if (!readAtLeastOneCalendar && inaccessibleCalendar) {
        throw const GoogleCalendarException(
          GoogleCalendarFailure.permissionDenied,
          'Não há acesso aos calendários desta conta Google.',
        );
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
    } on GoogleCalendarException {
      rethrow;
    } on calendar.DetailedApiRequestError catch (error) {
      throw _apiException(error.status, error);
    } catch (error) {
      throw GoogleCalendarException(
          GoogleCalendarFailure.remote, 'Erro ao buscar eventos: $error');
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
              final rawDue = task.due ?? '';
              final due = GoogleTaskTimeMapper.plannedStart(rawDue);
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
    } on GoogleCalendarException {
      rethrow;
    } on google_tasks.DetailedApiRequestError catch (error) {
      throw _apiException(error.status, error);
    } catch (error) {
      throw GoogleCalendarException(
          GoogleCalendarFailure.remote, 'Erro ao buscar Tasks: $error');
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
          } on google_tasks.DetailedApiRequestError catch (error) {
            // The task is not in this list; continue searching.
            if (error.status != 404) {
              throw _apiException(error.status, error);
            }
          }
        }
        listPageToken = lists.nextPageToken;
      } while (listPageToken != null && listPageToken.isNotEmpty);
      throw const GoogleCalendarException(
          GoogleCalendarFailure.remote, 'Tarefa Google não encontrada.');
    } on GoogleCalendarException {
      rethrow;
    } on google_tasks.DetailedApiRequestError catch (error) {
      throw _apiException(error.status, error);
    } catch (error) {
      throw GoogleCalendarException(GoogleCalendarFailure.remote,
          'Erro ao concluir tarefa Google: $error');
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
      throw _apiException(e.status, e);
    } catch (e) {
      // Outros erros (rede, parsing, etc)
      if (kDebugMode) {
        print('Erro inesperado ao criar evento no Google Calendar: $e');
      }
      if (e is GoogleCalendarException) rethrow;
      throw GoogleCalendarException(GoogleCalendarFailure.remote,
          'Falha ao criar evento no Google Calendar: $e');
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
      throw _apiException(e.status, e);
    } catch (e) {
      if (kDebugMode) {
        print('Erro inesperado ao atualizar evento no Google Calendar: $e');
      }
      if (e is GoogleCalendarException) rethrow;
      throw GoogleCalendarException(GoogleCalendarFailure.remote,
          'Falha ao atualizar evento no Google Calendar: $e');
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
      if (e is calendar.DetailedApiRequestError) {
        // Deletion is idempotent: a remote event already removed elsewhere is
        // equivalent to a successful retry of the local tombstone.
        if (e.status == 404) return;
        throw _apiException(e.status, e);
      }
      if (e is GoogleCalendarException) rethrow;
      throw GoogleCalendarException(
          GoogleCalendarFailure.remote, 'Erro ao deletar evento: $e');
    }
  }

  /// Verificar se usuário tem permissão de Calendar
  Future<bool> hasCalendarPermission() async {
    try {
      if (!await isConnected) return false;
      final account = _googleSignIn.currentUser;
      if (account == null) return false;

      final auth = await account.authentication;
      return auth.accessToken != null;
    } catch (e) {
      return false;
    }
  }
}
