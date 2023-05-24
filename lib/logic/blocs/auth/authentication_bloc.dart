import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:receiptcamp/data/services/authentication.dart';
import 'package:receiptcamp/models/app_user.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthService _auth = AuthService();

  AuthenticationBloc() : super(AuthenticationInitialState()) {
    on<AuthenticationInitialEvent>(authenticationInitialEvent);
    on<AuthenticationLoginButtonClickedEvent>(
        authenticationLoginButtonClickedEvent);
    on<AuthenticationRegisterButtonClickedEvent>(
        authenticationRegisterButtonClickedEvent);
    on<AuthenticationLogoutButtonClickedEvent>(
        authenticationLogoutButtonClickedEvent);
    on<AuthenticationSwitchScreenButtonClickedEvent>(
        authenticationSwitchScreenClickedEvent);
  }

  void authenticationInitialEvent(AuthenticationInitialEvent event, Emitter<AuthenticationState> emit) async {
    print('authenticationInitialEvent()');
    try {
      emit(AuthenticationLoadingState());

      final currentUser = await _auth.retrieveCurrentUser().first;
      print(currentUser.uid);
      if (currentUser.uid != "uid" && currentUser.uid != null) {
        print('authenticationSuccessState()');
        emit(AuthenticationSuccessState(user: currentUser));
      } else {
        print('authenticationFailureState()');
        emit(AuthenticationFailureState(
            errorMessage: 'Provided user credentials are invalid.'));
      }
    } catch (e) {
      emit(AuthenticationFailureState(errorMessage: 'Authentication process.'));
    }
  }

  void authenticationLoginButtonClickedEvent(AuthenticationLoginButtonClickedEvent event, Emitter<AuthenticationState> emit) async {
    print('authenticationLoginButtonClickedEvent()');
    
    if (validFormFields(event.email, event.password) == false) {
      emit(AuthenticationFormErrorState());
      return;
    }

    try {
      emit(AuthenticationLoadingState());

      final user = await _auth.signIn(event.email, event.password);
      if (user != null) {
        print('${user.email} : ${user.uid}');
        emit(AuthenticationSuccessState(user: user));
      } else {
        emit(AuthenticationFailureState(
            errorMessage: 'Invalid email or password'));
      }
    } catch (e) {
      emit(AuthenticationFailureState(errorMessage: 'Failed to login'));
    }
  }

  void authenticationRegisterButtonClickedEvent(AuthenticationRegisterButtonClickedEvent event, Emitter<AuthenticationState> emit) async {
    print('authenticationRegisterButtonClickedEvent()');

    if (validFormFields(event.email, event.password) == false) {
          emit(AuthenticationFormErrorState());
          return;
        }

    try {
      emit(AuthenticationLoadingState());

      final user =
          await _auth.registerWithEmailAndPassword(event.email, event.password);
      if (user != null) {
        emit(AuthenticationSuccessState(user: user));
      } else {
        emit(AuthenticationFailureState(errorMessage: 'Failed to register'));
      }
    } catch (e) {
      emit(AuthenticationFailureState(errorMessage: 'Failed to register'));
    }
  }

  void authenticationLogoutButtonClickedEvent(AuthenticationLogoutButtonClickedEvent event, Emitter<AuthenticationState> emit) async {
    print('authenticationLogoutButtonClickedEvent()');
    try {
      emit(AuthenticationLoadingState());

      await _auth.signOutFunc();
      emit(AuthenticationLogoutSuccessState());
    } catch (e) {
      emit(AuthenticationFailureState(errorMessage: 'Failed to logout'));
    }
  }

  FutureOr<void> authenticationSwitchScreenClickedEvent(AuthenticationSwitchScreenButtonClickedEvent event, Emitter<AuthenticationState> emit) {
    print('authenticationSwitchScreenClickedEvent');
    emit(AuthenticationSwitchScreenState());
  }
}

bool validFormFields(String email, String password) {
  // validating email address
  final RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',);

  // Check if email is valid
  if (!emailRegExp.hasMatch(email)) {
    return false;
  }

  // checking if passwotf is 
  else if (password.length < 6) {
    return false;
  }

  else if (email.isEmpty) {
    return false;
  }

  return true;
}
