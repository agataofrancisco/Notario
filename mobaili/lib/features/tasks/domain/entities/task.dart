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
  final bool sincronizado;
  final int versao;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final DateTime? concluidoEm;
  final SyncStatus syncStatus;

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
    this.sincronizado = false,
    this.versao = 1,
    required this.criadoEm,
    required this.atualizadoEm,
    this.concluidoEm,
    this.syncStatus = SyncStatus.synced,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Suporta tanto Firestore Timestamp quanto String ISO
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      // Firestore Timestamp
      return (value as dynamic).toDate();
    }

    return Task(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'], // Firestore usa camelCase
      googleEventId: json['googleEventId'] ?? json['google_event_id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      dataInicio: parseDateTime(json['dataInicio'] ?? json['data_inicio']),
      dataFim: parseDateTime(json['dataFim'] ?? json['data_fim']),
      duracaoMinutos: json['duracaoMinutos'] ?? json['duracao_minutos'],
      prioridade: Prioridade.fromJson(json['prioridade']),
      avisoAntesMinutos:
          json['avisoAntesMinutos'] ?? json['aviso_antes_minutos'] ?? 10,
      avisoDepoisMinutos:
          json['avisoDepoisMinutos'] ?? json['aviso_depois_minutos'] ?? 5,
      estado: EstadoTarefa.fromJson(json['estado'] ?? 'pendente'),
      tempoRealMinutos: json['tempoRealMinutos'] ?? json['tempo_real_minutos'],
      sincronizado: json['sincronizado'] ?? false,
      versao: json['versao'] ?? 1,
      criadoEm: parseDateTime(json['criadoEm'] ?? json['criado_em']),
      atualizadoEm:
          parseDateTime(json['atualizadoEm'] ?? json['atualizado_em']),
      concluidoEm: json['concluidoEm'] != null || json['concluido_em'] != null
          ? parseDateTime(json['concluidoEm'] ?? json['concluido_em'])
          : null,
      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toJson() {
    // Firestore usa camelCase
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
      'sincronizado': sincronizado,
      'versao': versao,
      'criadoEm': criadoEm,
      'atualizadoEm': atualizadoEm,
      'concluidoEm': concluidoEm,
    };
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
      'sincronizado': sincronizado ? 1 : 0,
      'versao': versao,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'concluido_em': concluidoEm?.toIso8601String(),
      'sync_status': syncStatus.toJson(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['user_id'],
      googleEventId: map['google_event_id'],
      titulo: map['titulo'],
      descricao: map['descricao'],
      dataInicio: DateTime.parse(map['data_inicio']),
      dataFim: DateTime.parse(map['data_fim']),
      duracaoMinutos: map['duracao_minutos'],
      prioridade: Prioridade.fromJson(map['prioridade']),
      avisoAntesMinutos: map['aviso_antes_minutos'] ?? 10,
      avisoDepoisMinutos: map['aviso_depois_minutos'] ?? 5,
      estado: EstadoTarefa.fromJson(map['estado'] ?? 'pendente'),
      tempoRealMinutos: map['tempo_real_minutos'],
      sincronizado: map['sincronizado'] == 1,
      versao: map['versao'] ?? 1,
      criadoEm: DateTime.parse(map['criado_em']),
      atualizadoEm: DateTime.parse(map['atualizado_em']),
      concluidoEm: map['concluido_em'] != null
          ? DateTime.parse(map['concluido_em'])
          : null,
      syncStatus: SyncStatus.fromJson(map['sync_status'] ?? 'synced'),
    );
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
    bool? sincronizado,
    int? versao,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    DateTime? concluidoEm,
    SyncStatus? syncStatus,
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
      sincronizado: sincronizado ?? this.sincronizado,
      versao: versao ?? this.versao,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      concluidoEm: concluidoEm ?? this.concluidoEm,
      syncStatus: syncStatus ?? this.syncStatus,
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
