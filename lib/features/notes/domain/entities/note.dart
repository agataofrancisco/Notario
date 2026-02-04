import 'package:equatable/equatable.dart';

/// Entidade de Nota
class Note extends Equatable {
  final String id;
  final String userId;
  final String titulo;
  final String conteudo;
  final DateTime? lembrete; // Quando o usuário quer ser lembrado
  final bool notificacaoEnviada;
  final bool notionSynced;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const Note({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.conteudo,
    this.lembrete,
    this.notificacaoEnviada = false,
    this.notionSynced = false,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        titulo,
        conteudo,
        lembrete,
        notificacaoEnviada,
        notionSynced,
        criadoEm,
        atualizadoEm,
      ];

  Note copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? conteudo,
    DateTime? lembrete,
    bool? notificacaoEnviada,
    bool? notionSynced,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      lembrete: lembrete ?? this.lembrete,
      notificacaoEnviada: notificacaoEnviada ?? this.notificacaoEnviada,
      notionSynced: notionSynced ?? this.notionSynced,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'titulo': titulo,
      'conteudo': conteudo,
      'lembrete': lembrete?.toIso8601String(),
      'notificacaoEnviada': notificacaoEnviada,
      'notionSynced': notionSynced,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['userId'] as String,
      titulo: json['titulo'] as String,
      conteudo: json['conteudo'] as String,
      lembrete: json['lembrete'] != null
          ? DateTime.parse(json['lembrete'] as String)
          : null,
      notificacaoEnviada: json['notificacaoEnviada'] as bool? ?? false,
      notionSynced: json['notionSynced'] as bool? ?? false,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
    );
  }

  /// Converte para Map (SQLite/Firestore partial)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'titulo': titulo,
      'conteudo': conteudo,
      'data_lembrete': lembrete?.toIso8601String(),
      'notificacao_enviada': notificacaoEnviada ? 1 : 0,
      'notion_synced': notionSynced ? 1 : 0,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  /// Cria Note a partir de Map (SQLite/Firestore partial)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      userId: map['user_id'] ?? map['userId'] ?? '',
      titulo: map['titulo'] as String,
      conteudo: map['conteudo'] as String,
      lembrete: map['data_lembrete'] != null || map['lembrete'] != null
          ? DateTime.parse((map['data_lembrete'] ?? map['lembrete']) as String)
          : null,
      notificacaoEnviada: (map['notificacao_enviada'] as int? ?? 0) == 1 || (map['notificacaoEnviada'] == true),
      notionSynced: (map['notion_synced'] as int? ?? 0) == 1 || (map['notionSynced'] == true),
      criadoEm: DateTime.parse((map['criado_em'] ?? map['criadoEm']) as String),
      atualizadoEm: DateTime.parse((map['atualizado_em'] ?? map['atualizadoEm']) as String),
    );
  }
}
