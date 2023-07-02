part of 'explorer_bloc.dart';

sealed class ExplorerEvent extends Equatable {
  const ExplorerEvent();

  @override
  List<Object> get props => [];
}

final class ExplorerInitialEvent extends ExplorerEvent {}

final class ExplorerFetchFilesEvent extends ExplorerEvent {
  final String folderId;

  const ExplorerFetchFilesEvent({required this.folderId});
}

final class ExplorerChangeFolderEvent extends ExplorerEvent {
  final String currentFolderId;
  final String nextFolderId;
  const ExplorerChangeFolderEvent({required this.currentFolderId, required this.nextFolderId});
}

final class ExplorerGoBackEvent extends ExplorerEvent {
  final String currentFolderId;
  final String previousFolderId;

  const ExplorerGoBackEvent({required this.currentFolderId, required this.previousFolderId});
}
// The following events are placeholders for future features

// final class ExplorerNavigateToSearchEvent extends ExplorerEvent {}

//final class ExplorerNavigateToSettingsEvent extends ExplorerEvent {}
