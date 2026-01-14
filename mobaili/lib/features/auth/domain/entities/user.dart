import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String googleId;
  final String email;
  final String nome;
  final String? fotoUrl;
  final String? googleCalendarId;
  final String timezone;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const User({
    required this.id,
    required this.googleId,
    required this.email,
    required this.nome,
    this.fotoUrl,
    this.googleCalendarId,
    this.timezone = 'Europe/Lisbon',
    required this.criadoEm,
    required this.atualizadoEm,
  });

  @override
  List<Object?> get props => [
        id,
        googleId,
        email,
        nome,
        fotoUrl,
        googleCalendarId,
        timezone,
        criadoEm,
        atualizadoEm,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'google_id': googleId,
      'email': email,
      'nome': nome,
      'foto_url': fotoUrl,
      'google_calendar_id': googleCalendarId,
      'timezone': timezone,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      googleId: json['google_id'] as String,
      email: json['email'] as String,
      nome: json['nome'] as String,
      fotoUrl: json['foto_url'] as String?,
      googleCalendarId: json['google_calendar_id'] as String?,
      timezone: json['timezone'] as String? ?? 'Europe/Lisbon',
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: DateTime.parse(json['atualizado_em'] as String),
    );
  }
}
