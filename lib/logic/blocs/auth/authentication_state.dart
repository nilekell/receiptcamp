// ignore_for_file: public_member_api_docs, sort_constructors_first
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

class AuthenticationNavigateToEmailVerificationState extends AuthenticationState {
  AuthenticationNavigateToEmailVerificationState({required this.user});

  final AppUser user;
}

class AuthenticationEmailVerificationInProgressState extends AuthenticationState {
  AuthenticationEmailVerificationInProgressState({required this.user});
  
  final AppUser user;
}

class AuthenticationEmailVerifiedState extends AuthenticationState {
  AuthenticationEmailVerifiedState({required this.user});

  final AppUser user;
}

class AuthenticationRegistrationFailedState extends AuthenticationState {}

class AuthenticationLogoutSuccessState extends AuthenticationState {}

class AuthenticationSwitchScreenState  extends AuthenticationState {}
