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


class AuthenticationInitialEmailVerificationEvent extends AuthenticationEvent {}

class AuthenticationCheckEmailVerificationStatusEvent extends AuthenticationEvent {}

class AuthenticationTimerExpiredEvent extends AuthenticationEvent {}

class AuthenticationRegistrationSuccessedEvent extends AuthenticationEvent {}

class AuthenticationRegistrationCancelledEvent extends AuthenticationEvent {}

class AuthenticationDeleteAccountEvent extends AuthenticationEvent {}

class AuthenticationLogoutButtonClickedEvent extends AuthenticationEvent {}

class AuthenticationSwitchScreenButtonClickedEvent extends AuthenticationEvent {}