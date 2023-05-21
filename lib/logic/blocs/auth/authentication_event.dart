part of 'authentication_bloc.dart';

@immutable
abstract class AuthenticationEvent {}

class AuthenticationInitialEvent extends AuthenticationEvent {}

class AuthenticationLoginButtonClickedEvent extends AuthenticationEvent {}

class AuthenticationRegisterButtonClickedEvent extends AuthenticationEvent {}

class AuthenticationLogoutButtonClickedEvent extends AuthenticationEvent {}