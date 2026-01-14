class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  // Configurações de notificações
  static const int avisoAntesPadraoMinutos = 15;
  static const int avisoDepoisPadraoMinutos = 5;

  // Configurações de tempo
  static const int horaInicioDia = 8; // 8h
  static const int horaFimDia = 22; // 22h
  static const int duracaoMaximaTarefaMinutos = 480; // 8h

  // Configurações de sincronização
  static const int intervaloSincronizacaoSegundos = 300; // 5 minutos
  static const int maxTentativasSincronizacao = 3;
}
