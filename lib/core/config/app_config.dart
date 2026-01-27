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

  /// Feature flag: integração com Google Calendar (OAuth) — mantém false por padrão
  /// Ativar com: `--dart-define=ENABLE_GOOGLE_CALENDAR=true`
  static const bool enableGoogleCalendar = bool.fromEnvironment(
    'ENABLE_GOOGLE_CALENDAR',
    defaultValue: false,
  );

  // --- Integração Notion ---
  static const String notionApiUrl = 'https://api.notion.com/v1';
  static const String notionApiVersion = '2022-06-28';

  // Token fornecido pelo usuário
  static const String notionApiToken =
      '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';

  // Database ID fornecido pelo usuário
  static const String notionTaskDatabaseId = '2f5d1889d1788087bd7bf3c712533a40';
  static const String notionNoteDatabaseId = '2f5d1889d1788087bd7bf3c712533a40';
}
