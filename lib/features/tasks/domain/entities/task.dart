enum Prioridade {
  baixa,
  media,
  alta;

  String get displayName {
    switch (this) {
      case Prioridade.baixa:
        return 'Baixa';
      case Prioridade.media:
        return 'Média';
      case Prioridade.alta:
        return 'Alta';
    }
  }

  String toJson() => name;

  static Prioridade fromJson(String value) {
    return Prioridade.values.firstWhere((e) => e.name == value);
  }
}

enum EstadoTarefa {
  pendente,
  emExecucao,
  concluida,
  pulada,
  cancelada;

  String get displayName {
    switch (this) {
      case EstadoTarefa.pendente:
        return 'Pendente';
      case EstadoTarefa.emExecucao:
        return 'Em Execução';
      case EstadoTarefa.concluida:
        return 'Concluída';
      case EstadoTarefa.pulada:
        return 'Pulada';
      case EstadoTarefa.cancelada:
        return 'Cancelada';
    }
  }

  String toJson() => name;

  static EstadoTarefa fromJson(String value) {
    return EstadoTarefa.values.firstWhere((e) => e.name == value,
        orElse: () => EstadoTarefa.pendente);
  }
}

enum SyncStatus {
  synced,
  pending,
  syncing,
  conflict;

  String toJson() => name;

  static SyncStatus fromJson(String value) {
    return SyncStatus.values.firstWhere((e) => e.name == value);
  }
}

class Task {
  final String id;
  final String userId;
  final String? googleEventId;
  final String titulo;
  final String? descricao;
  final DateTime dataInicio;
  final DateTime dataFim;
  final int duracaoMinutos;
  final Prioridade prioridade;
  final int avisoAntesMinutos;
  final int avisoDepoisMinutos;
  final EstadoTarefa estado;
  final int? tempoRealMinutos;
  final bool isNegotiable;
  final int safetyMarginMinutes;
  final bool sincronizado; // Mantido para retrocompatibilidade
  final int versao;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final DateTime? concluidoEm;
  final SyncStatus syncStatus;
  final bool googleCalendarSynced;

  Task({
    required this.id,
    required this.userId,
    this.googleEventId,
    required this.titulo,
    this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.duracaoMinutos,
    required this.prioridade,
    this.avisoAntesMinutos = 10,
    this.avisoDepoisMinutos = 5,
    this.estado = EstadoTarefa.pendente,
    this.tempoRealMinutos,
    this.isNegotiable = true,
    this.safetyMarginMinutes = 0,
    this.sincronizado = false,
    this.versao = 1,
    required this.criadoEm,
    required this.atualizadoEm,
    this.concluidoEm,
    this.syncStatus = SyncStatus.synced,
    this.googleCalendarSynced = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

    return Task(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'] ?? '',
      googleEventId: json['googleEventId'] ?? json['google_event_id'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'],
      dataInicio: parseDateTime(json['dataInicio'] ?? json['data_inicio']),
      dataFim: parseDateTime(json['dataFim'] ?? json['data_fim']),
      duracaoMinutos: json['duracaoMinutos'] ?? json['duracao_minutos'] ?? 0,
      prioridade: Prioridade.fromJson(json['prioridade'] ?? 'media'),
      avisoAntesMinutos:
          json['avisoAntesMinutos'] ?? json['aviso_antes_minutos'] ?? 10,
      avisoDepoisMinutos:
          json['avisoDepoisMinutos'] ?? json['aviso_depois_minutos'] ?? 5,
      estado: EstadoTarefa.fromJson(json['estado'] ?? 'pendente'),
      tempoRealMinutos: json['tempoRealMinutos'] ?? json['tempo_real_minutos'],
      isNegotiable: json['isNegotiable'] ?? json['is_negotiable'] ?? true,
      safetyMarginMinutes:
          json['safetyMarginMinutes'] ?? json['safety_margin_minutes'] ?? 0,
      sincronizado: json['sincronizado'] ?? false,
      versao: json['versao'] ?? 1,
      criadoEm: parseDateTime(json['criadoEm'] ?? json['criado_em']),
      atualizadoEm:
          parseDateTime(json['atualizadoEm'] ?? json['atualizado_em']),
      concluidoEm: json['concluidoEm'] != null || json['concluido_em'] != null
          ? parseDateTime(json['concluidoEm'] ?? json['concluido_em'])
          : null,
      syncStatus: SyncStatus.fromJson(
          json['syncStatus'] ?? json['sync_status'] ?? 'synced'),
      googleCalendarSynced: json['googleCalendarSynced'] ??
          json['google_calendar_synced'] ??
          json['sincronizado'] ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'googleEventId': googleEventId,
      'titulo': titulo,
      'descricao': descricao,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
      'duracaoMinutos': duracaoMinutos,
      'prioridade': prioridade.toJson(),
      'avisoAntesMinutos': avisoAntesMinutos,
      'avisoDepoisMinutos': avisoDepoisMinutos,
      'estado': estado.toJson(),
      'tempoRealMinutos': tempoRealMinutos,
      'isNegotiable': isNegotiable,
      'safetyMarginMinutes': safetyMarginMinutes,
      'sincronizado': googleCalendarSynced, // Retrocompatibilidade
      'versao': versao,
      'criadoEm': criadoEm,
      'atualizadoEm': atualizadoEm,
      'concluidoEm': concluidoEm,
      'googleCalendarSynced': googleCalendarSynced,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) throw ArgumentError('DateTime value cannot be null');
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    try {
      return (value as dynamic).toDate();
    } catch (e) {
      throw ArgumentError('Invalid DateTime value: $value');
    }
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    try {
      return (value as dynamic).toDate();
    } catch (e) {
      return null;
    }
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['user_id'] ?? map['userId'] ?? '',
      googleEventId: map['google_event_id'] ?? map['googleEventId'],
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'],
      dataInicio: _parseDateTime(map['data_inicio'] ?? map['dataInicio']),
      dataFim: _parseDateTime(map['data_fim'] ?? map['dataFim']),
      duracaoMinutos: map['duracao_minutos'] ?? map['duracaoMinutos'] ?? 0,
      prioridade: Prioridade.fromJson(map['prioridade'] ?? 'media'),
      avisoAntesMinutos:
          map['aviso_antes_minutos'] ?? map['avisoAntesMinutos'] ?? 10,
      avisoDepoisMinutos:
          map['aviso_depois_minutos'] ?? map['avisoDepoisMinutos'] ?? 5,
      estado: EstadoTarefa.fromJson(map['estado'] ?? 'pendente'),
      tempoRealMinutos: map['tempo_real_minutos'] ?? map['tempoRealMinutos'],
      isNegotiable: (map['is_negotiable'] ?? map['isNegotiable']) == true ||
          (map['is_negotiable'] == 1),
      safetyMarginMinutes:
          map['safety_margin_minutes'] ?? map['safetyMarginMinutes'] ?? 0,
      sincronizado: (map['sincronizado'] == 1) ||
          (map['sincronizado'] == true) ||
          (map['googleCalendarSynced'] == true),
      versao: map['versao'] ?? 1,
      criadoEm: _parseDateTime(map['criado_em'] ?? map['criadoEm']),
      atualizadoEm: _parseDateTime(map['atualizado_em'] ?? map['atualizadoEm']),
      concluidoEm:
          _parseDateTimeNullable(map['concluido_em'] ?? map['concluidoEm']),
      syncStatus: SyncStatus.fromJson(
          map['sync_status'] ?? map['syncStatus'] ?? 'synced'),
      googleCalendarSynced:
          map['googleCalendarSynced'] ?? map['google_calendar_synced'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'google_event_id': googleEventId,
      'titulo': titulo,
      'descricao': descricao,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'duracao_minutos': duracaoMinutos,
      'prioridade': prioridade.toJson(),
      'aviso_antes_minutos': avisoAntesMinutos,
      'aviso_depois_minutos': avisoDepoisMinutos,
      'estado': estado.toJson(),
      'tempo_real_minutos': tempoRealMinutos,
      'is_negotiable': isNegotiable ? 1 : 0,
      'safety_margin_minutes': safetyMarginMinutes,
      'sincronizado': googleCalendarSynced ? 1 : 0,
      'versao': versao,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'concluido_em': concluidoEm?.toIso8601String(),
      'sync_status': syncStatus.toJson(),
      'googleCalendarSynced': googleCalendarSynced,
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    String? googleEventId,
    String? titulo,
    String? descricao,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? duracaoMinutos,
    Prioridade? prioridade,
    int? avisoAntesMinutos,
    int? avisoDepoisMinutos,
    EstadoTarefa? estado,
    int? tempoRealMinutos,
    bool? isNegotiable,
    int? safetyMarginMinutes,
    bool? sincronizado,
    int? versao,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    DateTime? concluidoEm,
    SyncStatus? syncStatus,
    bool? googleCalendarSynced,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      googleEventId: googleEventId ?? this.googleEventId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      prioridade: prioridade ?? this.prioridade,
      avisoAntesMinutos: avisoAntesMinutos ?? this.avisoAntesMinutos,
      avisoDepoisMinutos: avisoDepoisMinutos ?? this.avisoDepoisMinutos,
      estado: estado ?? this.estado,
      tempoRealMinutos: tempoRealMinutos ?? this.tempoRealMinutos,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      safetyMarginMinutes: safetyMarginMinutes ?? this.safetyMarginMinutes,
      sincronizado: sincronizado ?? this.sincronizado,
      versao: versao ?? this.versao,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      concluidoEm: concluidoEm ?? this.concluidoEm,
      syncStatus: syncStatus ?? this.syncStatus,
      googleCalendarSynced: googleCalendarSynced ?? this.googleCalendarSynced,
    );
  }

  bool get isPendente => estado == EstadoTarefa.pendente;
  bool get isEmExecucao => estado == EstadoTarefa.emExecucao;
  bool get isConcluida => estado == EstadoTarefa.concluida;
  bool get isPulada => estado == EstadoTarefa.pulada;
  bool get isCancelada => estado == EstadoTarefa.cancelada;

  bool get isAtrasada {
    if (estado != EstadoTarefa.pendente) return false;
    return DateTime.now().isAfter(dataInicio);
  }

  Duration get duracaoRestante {
    if (estado != EstadoTarefa.emExecucao) return Duration.zero;
    final agora = DateTime.now();
    if (agora.isAfter(dataFim)) return Duration.zero;
    return dataFim.difference(agora);
  }
}
