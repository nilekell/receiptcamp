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
  Timer? _emailVerificationTimer;
  Timer? _emailVerificationLifetimeTimer;

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
    on<AuthenticationInitialEmailVerificationEvent>(
        authenticationInitialEmailVerificationEvent);
    on<AuthenticationCheckEmailVerificationStatusEvent>(
        authenticationCheckEmailVerificationStatusEvent);
    on<AuthenticationTimerExpiredEvent>(authenticationTimerExpiredEvent);
    on<AuthenticationRegistrationCancelledEvent>(
        authenticationRegistrationCancelledEvent);
    on<AuthenticationDeleteAccountEvent>(authenticationDeleteAccountEvent);
  }

  void authenticationInitialEvent(AuthenticationInitialEvent event,
      Emitter<AuthenticationState> emit) async {
    print('authenticationInitialEvent()');
    try {
      emit(AuthenticationLoadingState());

      final currentUser = await _auth.retrieveCurrentUser().first;
      print(currentUser.uid);
      if (currentUser.uid != "uid") {
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

  void authenticationLoginButtonClickedEvent(
      AuthenticationLoginButtonClickedEvent event,
      Emitter<AuthenticationState> emit) async {
    print('authenticationLoginButtonClickedEvent()');

    if (validFormFieldsLogin(event.email, event.password) == false) {
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

  void authenticationLogoutButtonClickedEvent(
      AuthenticationLogoutButtonClickedEvent event,
      Emitter<AuthenticationState> emit) async {
    print('authenticationLogoutButtonClickedEvent()');
    try {
      emit(AuthenticationLoadingState());

      await _auth.signOutFunc();
      emit(AuthenticationInitialState());
    } catch (e) {
      emit(AuthenticationFailureState(errorMessage: 'Failed to logout'));
    }
  }

  FutureOr<void> authenticationSwitchScreenClickedEvent(
      AuthenticationSwitchScreenButtonClickedEvent event,
      Emitter<AuthenticationState> emit) {
    print('authenticationSwitchScreenClickedEvent');
    emit(AuthenticationSwitchScreenState());
  }

  FutureOr<void> authenticationRegisterButtonClickedEvent(
      AuthenticationRegisterButtonClickedEvent event,
      Emitter<AuthenticationState> emit) async {
    print('authenticationRegisterButtonClickedEvent()');

    // checking form for basic user input mistakes
    if (validFormFieldsRegister(event.email, event.password, event.confirmPassword) == false) {
      emit(AuthenticationFormErrorState());
      return;
    }

    try {
      emit(AuthenticationLoadingState());
      // creating user
      final user =
          await _auth.registerWithEmailAndPassword(event.email, event.password);
      if (user != null) {
        // going to email verification screen
        emit(AuthenticationNavigateToEmailVerificationState(user: user));
      } else {
        emit(AuthenticationFailureState(errorMessage: 'Failed to register'));
      }
    } catch (e) {
      emit(AuthenticationFailureState(errorMessage: 'Failed to register'));
    }
  }

  void startEmailVerification() async {
    print('startEmailVerification()');
    _auth.sendVerificationEmail();
    _emailVerificationLifetimeTimer = Timer(const Duration(seconds: 30), () {
      print('Lifetime timer finished');
      add(AuthenticationTimerExpiredEvent());
    });
    // Adjust the interval as needed
    _emailVerificationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(AuthenticationCheckEmailVerificationStatusEvent());
    });
  }

  FutureOr<void> authenticationCheckEmailVerificationStatusEvent(
      AuthenticationCheckEmailVerificationStatusEvent event,
      Emitter<AuthenticationState> emit) async {
    print('authenticationCheckEmailVerificationStatusEvent()');

    _auth.refreshCurrentUser();
    final currentUserStream = _auth.retrieveCurrentUser();

    await for (final user in currentUserStream) {
      print({user.email, user.isVerified});

      if (user.isVerified) {
        // Email is verified
        stopEmailVerificationTimers();
        emit(AuthenticationSuccessState(user: user));
        break;
      } else {
        emit(AuthenticationEmailVerificationInProgressState(user: user));
      }
    }
    /*
    final currentUser = await _auth.retrieveCurrentUser().first;
    print({currentUser.email, currentUser.isVerified});
    if (currentUser.isVerified) {
      // Email is verified
      stopEmailVerificationTimers();
      emit(AuthenticationSuccessState(user: currentUser)); 
    } else {
      emit(AuthenticationEmailVerificationInProgressState(user: currentUser));
    }
    */
  }

  FutureOr<void> authenticationInitialEmailVerificationEvent(
      AuthenticationInitialEmailVerificationEvent event,
      Emitter<AuthenticationState> emit) async {
    startEmailVerification();
  }

  FutureOr<void> authenticationTimerExpiredEvent(
      AuthenticationTimerExpiredEvent event,
      Emitter<AuthenticationState> emit) async {
    stopEmailVerificationTimers();
    // delete user
    // _auth.deleteUser();
    emit(AuthenticationRegistrationFailedState());
  }

  FutureOr<void> authenticationRegistrationCancelledEvent(
      AuthenticationRegistrationCancelledEvent event,
      Emitter<AuthenticationState> emit) {
    stopEmailVerificationTimers();
    // delete user
    // _auth.deleteUser();
    emit(AuthenticationRegistrationFailedState());
  }

  void stopEmailVerificationTimers() {
    print('stopEmailVerificationTimers()');
    _emailVerificationTimer?.cancel();
    _emailVerificationLifetimeTimer?.cancel();
  }

  FutureOr<void> authenticationDeleteAccountEvent(
      AuthenticationDeleteAccountEvent event,
      Emitter<AuthenticationState> emit) {
    // delete user
    _auth.deleteUser();
    emit(AuthenticationFailureState(
        errorMessage: 'Deleted account, forcing sign out'));
  }
}

bool validFormFieldsRegister(String email, String password, String confirmPassword) {
  // validating email address
  final RegExp emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  // Check if email is valid
  if (!emailRegExp.hasMatch(email)) {
    return false;
  }

  // checking if passwords match
  if (password != confirmPassword) {
    return false;
  }

  // checking if password is long enough
  else if (password.length < 6) {
    return false;
  } else if (email.isEmpty) {
    return false;
  }

  return true;
}

bool validFormFieldsLogin(String email, String password) {
  // validating email address
  final RegExp emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  // Check if email is valid
  if (!emailRegExp.hasMatch(email)) {
    return false;
  }

  // checking if password is long enough
  else if (password.length < 6) {
    return false;
  } else if (email.isEmpty) {
    return false;
  }

  return true;
}
