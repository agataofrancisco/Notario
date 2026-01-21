import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

// Login com Google (opcional)
class AuthGoogleLoginRequested extends AuthEvent {
  final String? clientId;

  const AuthGoogleLoginRequested({this.clientId});

  @override
  List<Object?> get props => [clientId];
}

// Login com Email e Senha
class AuthEmailLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthEmailLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

// Registro com Email e Senha
class AuthEmailRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const AuthEmailRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

// Reset de Senha
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {}
