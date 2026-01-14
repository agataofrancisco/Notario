import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthGoogleLoginRequested extends AuthEvent {
  final String idToken;
  final String accessToken;

  const AuthGoogleLoginRequested({
    required this.idToken,
    required this.accessToken,
  });

  @override
  List<Object?> get props => [idToken, accessToken];
}

class AuthLogoutRequested extends AuthEvent {}
