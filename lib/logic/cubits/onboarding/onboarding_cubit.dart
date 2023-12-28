import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:receiptcamp/data/services/preferences.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingInitial());

  final PreferencesService _prefs = PreferencesService.instance;

  init() {
    if (_prefs.getIsFirstAppOpen() == true) {
      emit(OnboardingShowScreen());
      _prefs.setIsFirstAppOpen(false);
    } else {
      return;
    }
  }

  closeScreen() {
    emit(OnboardingGoToApp());
    close();
  }
}
