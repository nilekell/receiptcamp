part of 'explorer_bloc.dart';

sealed class ExplorerState extends Equatable {
  const ExplorerState();
  
  @override
  List<Object> get props => [];
}

final class ExplorerInitialState extends ExplorerState {}

final class ExplorerActionState extends ExplorerState {}

final class ExplorerLoadingState extends ExplorerState {}

final class ExplorerEmptyReceiptsState extends ExplorerState {}

final class ExplorerEmptyFilesState extends ExplorerState {}

final class ExplorerLoadedSuccessState extends ExplorerState {
  const ExplorerLoadedSuccessState({required this.files});

  final List<dynamic> files;

  @override
  List<Object> get props => [files];
}

final class ExplorerErrorState extends ExplorerState {}
