part of 'authentication_bloc.dart';

@immutable
abstract class AuthenticationState {}

class AuthenticationInitialState extends AuthenticationState {}

class AuthenticationLoadingState extends AuthenticationState {}

class AuthenticationFormErrorState extends AuthenticationState {}

class AuthenticationFailureState extends AuthenticationState {
  AuthenticationFailureState({required this.errorMessage});

  final String errorMessage;
}

class AuthenticationSuccessState extends AuthenticationState {
  AuthenticationSuccessState({required this.user});

  final AppUser user;
}

class AuthenticationLogoutSuccessState extends AuthenticationState {}

class AuthenticationSwitchScreenState  extends AuthenticationState {}
