import 'package:equatable/equatable.dart';

/// Entidade de Nota
class Note extends Equatable {
  final String id;
  final String userId;
  final String titulo;
  final String conteudo;
  final DateTime? lembrete; // Quando o usuário quer ser lembrado
  final bool notificacaoEnviada;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const Note({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.conteudo,
    this.lembrete,
    this.notificacaoEnviada = false,
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
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
    );
  }
}
