class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const String appName = 'NOTÁRIO';
  static const String appVersion = '1.0.0';

  // Tempo de timeout para requisições HTTP (em segundos)
  static const int httpTimeout = 30;

  // Intervalo de sincronização automática (em minutos)
  static const int syncIntervalMinutes = 15;

  // Horário de trabalho (8h-22h)
  static const int workStartHour = 8;
  static const int workEndHour = 22;
  static const int workHoursPerDay = 14;
  static const int workMinutesPerDay = 840;

  // Margem de segurança para agendamento (10%)
  static const double scheduleSafetyMargin = 1.1;

  // Configurações de notificações
  static const int defaultReminderBeforeMinutes = 10;
  static const int defaultReminderAfterMinutes = 5;

  // Configurações de cache
  static const String userCacheKey = 'cached_user';
  static const String tokenCacheKey = 'jwt_token';
  static const String lastSyncKey = 'last_sync_time';

  /// Feature flag: integração com Google Calendar (OAuth) — ativo por padrão
  static const bool enableGoogleCalendar = true;

  /// Firestore is optional. Keep it off until the project has an explicit
  /// billing decision; SQLite, Google and the progress backend keep working.
  static const bool enableFirestoreSync = false;

  static const String progressBackendUrl = String.fromEnvironment(
    'PROGRESS_BACKEND_URL',
    defaultValue: '',
  );

  /// Shared OAuth audience for progress-backend ID tokens. OAuth client IDs
  /// identify an app, but are not secrets and may safely be embedded here.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
