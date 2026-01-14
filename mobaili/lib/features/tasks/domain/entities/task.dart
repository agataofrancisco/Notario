import 'package:equatable/equatable.dart';

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
}

class Task extends Equatable {
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

  const Task({
    required this.id,
    required this.userId,
    this.googleEventId,
    required this.titulo,
    this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.duracaoMinutos,
    required this.prioridade,
    this.avisoAntesMinutos = 15,
    this.avisoDepoisMinutos = 5,
    this.estado = EstadoTarefa.pendente,
    this.tempoRealMinutos,
    this.sincronizado = false,
    this.versao = 1,
    required this.criadoEm,
    required this.atualizadoEm,
    this.concluidoEm,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        googleEventId,
        titulo,
        descricao,
        dataInicio,
        dataFim,
        duracaoMinutos,
        prioridade,
        avisoAntesMinutos,
        avisoDepoisMinutos,
        estado,
        tempoRealMinutos,
        sincronizado,
        versao,
        criadoEm,
        atualizadoEm,
        concluidoEm,
      ];

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'google_event_id': googleEventId,
      'titulo': titulo,
      'descricao': descricao,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'duracao_minutos': duracaoMinutos,
      'prioridade': prioridade.name,
      'aviso_antes_minutos': avisoAntesMinutos,
      'aviso_depois_minutos': avisoDepoisMinutos,
      'estado': estado.name,
      'tempo_real_minutos': tempoRealMinutos,
      'sincronizado': sincronizado ? 1 : 0,
      'versao': versao,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'concluido_em': concluidoEm?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      googleEventId: json['google_event_id'] as String?,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String?,
      dataInicio: DateTime.parse(json['data_inicio'] as String),
      dataFim: DateTime.parse(json['data_fim'] as String),
      duracaoMinutos: json['duracao_minutos'] as int,
      prioridade: Prioridade.values.byName(json['prioridade'] as String),
      avisoAntesMinutos: json['aviso_antes_minutos'] as int? ?? 15,
      avisoDepoisMinutos: json['aviso_depois_minutos'] as int? ?? 5,
      estado: EstadoTarefa.values.byName(json['estado'] as String),
      tempoRealMinutos: json['tempo_real_minutos'] as int?,
      sincronizado: (json['sincronizado'] as int?) == 1,
      versao: json['versao'] as int? ?? 1,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: DateTime.parse(json['atualizado_em'] as String),
      concluidoEm: json['concluido_em'] != null
          ? DateTime.parse(json['concluido_em'] as String)
          : null,
    );
  }
}
