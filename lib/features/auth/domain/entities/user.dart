class User {
  final String id;
  final String googleId;
  final String email;
  final String nome;
  final String? fotoUrl;
  final String? googleCalendarId;
  final String timezone;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  User({
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      googleId: json['google_id'],
      email: json['email'],
      nome: json['nome'],
      fotoUrl: json['foto_url'],
      googleCalendarId: json['google_calendar_id'],
      timezone: json['timezone'] ?? 'Europe/Lisbon',
      criadoEm: DateTime.parse(json['criado_em']),
      atualizadoEm: DateTime.parse(json['atualizado_em']),
    );
  }

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

  Map<String, dynamic> toMap() {
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

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      googleId: map['google_id'],
      email: map['email'],
      nome: map['nome'],
      fotoUrl: map['foto_url'],
      googleCalendarId: map['google_calendar_id'],
      timezone: map['timezone'] ?? 'Europe/Lisbon',
      criadoEm: DateTime.parse(map['criado_em']),
      atualizadoEm: DateTime.parse(map['atualizado_em']),
    );
  }

  User copyWith({
    String? id,
    String? googleId,
    String? email,
    String? nome,
    String? fotoUrl,
    String? googleCalendarId,
    String? timezone,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return User(
      id: id ?? this.id,
      googleId: googleId ?? this.googleId,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      googleCalendarId: googleCalendarId ?? this.googleCalendarId,
      timezone: timezone ?? this.timezone,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
