import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
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
      final List<dynamic> files =
          await DatabaseRepository.instance.getFolderContents(event.folderId);
      if (files.isNotEmpty) {
        emit(ExplorerLoadedSuccessState(files: files));
      } else {
        emit(ExplorerEmptyFilesState());
      }
    } catch (error) {
      emit(ExplorerErrorState());
    }
  }

  // define event to change folders
  FutureOr<void> explorerChangeFolderEvent(ExplorerChangeFolderEvent event, Emitter<ExplorerState> emit) async {
    add(ExplorerFetchFilesEvent(folderId: event.nextFolderId));
  }

  // define event to go to the parent folder of the currently displayed folder
  FutureOr<void> explorerGoBackEvent(ExplorerGoBackEvent event, Emitter<ExplorerState> emit) {
    add(ExplorerFetchFilesEvent(folderId: event.previousFolderId));
  }
}

