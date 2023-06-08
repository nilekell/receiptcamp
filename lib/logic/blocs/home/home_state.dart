part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object> get props => [];
}

final class HomeInitialState extends HomeState {}

final class HomeActionState extends HomeState {}

final class HomeLoadingState extends HomeState {}

final class HomeLoadedSuccessState extends HomeState {
  final List<Receipt> receipts;

  const HomeLoadedSuccessState(this.receipts);
}

final class HomeErrorState extends HomeState {}

final class HomeNavigateToFileExplorerState extends HomeActionState {}

// The following states are placeholders for future features

// final class HomeNavigateToSearchState extends HomeActionState {}

// final class HomeNavigateToSettingsState extends HomeActionState {}
