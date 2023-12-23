part of 'onboarding_cubit.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object> get props => [];
}

final class OnboardingInitial extends OnboardingState {}

final class OnboardingShowScreen extends OnboardingState {}

final class OnboardingGoToApp extends OnboardingState {}
