import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(AuthenticationInitial()) {
    on<AuthenticationInitialEvent>(authenticationInitialEvent);
    on<AuthenticationLoginButtonClickedEvent>(authenticationLoginButtonClickedButtonEvent);
    on<AuthenticationRegisterButtonClickedEvent>(authenticationRegisterButtonClickedEvent);
    on<AuthenticationLogoutButtonClickedEvent>(authenticationLogoutButtonClickedEvent);
  }

  FutureOr<void> authenticationInitialEvent(AuthenticationInitialEvent event, Emitter<AuthenticationState> emit) {
  }

  FutureOr<void> authenticationLoginButtonClickedButtonEvent(AuthenticationLoginButtonClickedEvent event, Emitter<AuthenticationState> emit) {
  }

  FutureOr<void> authenticationRegisterButtonClickedEvent(AuthenticationRegisterButtonClickedEvent event, Emitter<AuthenticationState> emit) {
  }

  FutureOr<void> authenticationLogoutButtonClickedEvent(AuthenticationLogoutButtonClickedEvent event, Emitter<AuthenticationState> emit) {
  }
}
