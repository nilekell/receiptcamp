import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/models/folder.dart';
part 'explorer_event.dart';
part 'explorer_state.dart';

class ExplorerBloc extends Bloc<ExplorerEvent, ExplorerState> {
  ExplorerBloc() : super(ExplorerInitialState()) {
    on<ExplorerInitialEvent>(explorerInitialEvent);
    on<ExplorerFetchFilesEvent>(explorerFetchFilesEvent);
    on<ExplorerChangeFolderEvent>(explorerChangeFolderEvent);
    on<ExplorerGoBackEvent>(explorerGoBackEvent);
  }

  FutureOr<void> explorerInitialEvent(
      ExplorerInitialEvent event, Emitter<ExplorerState> emit) {
    emit(ExplorerInitialState());
    add(const ExplorerFetchFilesEvent(folderId: 'a1'));
  }

  // Define fetch files event
  Future<FutureOr<void>> explorerFetchFilesEvent(
      ExplorerFetchFilesEvent event, Emitter<ExplorerState> emit) async {
    emit(ExplorerLoadingState());
    try {
      final Folder folder = await DatabaseRepository.instance.getFolderById(event.folderId);
      final List<dynamic> files =
          await DatabaseRepository.instance.getFolderContents(event.folderId);
        emit(ExplorerLoadedSuccessState(files: files, folder: folder));
    } catch (error) {
      emit(ExplorerErrorState());
    }
  }

  // printing method names as the bloc observer doesn't capture these methods (probably because they quickly/directly add another Event)

  // define event to change folders
  FutureOr<void> explorerChangeFolderEvent(ExplorerChangeFolderEvent event, Emitter<ExplorerState> emit) async {
    print('explorerChangeFolderEvent');
    add(ExplorerFetchFilesEvent(folderId: event.nextFolderId));
  }

  // define event to go to the parent folder of the currently displayed folder
  FutureOr<void> explorerGoBackEvent(ExplorerGoBackEvent event, Emitter<ExplorerState> emit) {
    print('explorerGoBackEvent()');
    add(ExplorerFetchFilesEvent(folderId: event.previousFolderId));
  }
}

