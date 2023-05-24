part of 'authentication_bloc.dart';

@immutable
abstract class AuthenticationEvent {}

class AuthenticationInitialEvent extends AuthenticationEvent {}

class AuthenticationLoginButtonClickedEvent extends AuthenticationEvent {
  AuthenticationLoginButtonClickedEvent({required this.email, required this.password});

  final String email;
  final String password;

}

class AuthenticationRegisterButtonClickedEvent extends AuthenticationEvent {
  AuthenticationRegisterButtonClickedEvent({required this.email, required this.password});

  final String email;
  final String password;

}

class AuthenticationLogoutButtonClickedEvent extends AuthenticationEvent {}

class AuthenticationSwitchScreenButtonClickedEvent extends AuthenticationEvent {}