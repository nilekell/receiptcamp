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
  }

  FutureOr<void> explorerInitialEvent(
      ExplorerInitialEvent event, Emitter<ExplorerState> emit) {
    emit(ExplorerInitialState());
    add(ExplorerFetchFilesEvent());
  }

  // Define fetch files event
  Future<FutureOr<void>> explorerFetchFilesEvent(
      ExplorerFetchFilesEvent event, Emitter<ExplorerState> emit) async {
    emit(ExplorerLoadingState());
    try {
      final List<dynamic> files =
          await DatabaseRepository.instance.getFolderContents('a1');
      if (files.isNotEmpty) {
        emit(ExplorerLoadedSuccessState(files: files));
      } else {
        emit(ExplorerEmptyFilesState());
      }
    } catch (error) {
      emit(ExplorerErrorState());
    }
  }

  FutureOr<void> explorerChangeFolderEvent(ExplorerChangeFolderEvent event, Emitter<ExplorerState> emit) async {
    emit(ExplorerLoadingState());
    try {
      final List<dynamic> files =
          await DatabaseRepository.instance.getFolderContents(event.nextFolderId);
      if (files.isNotEmpty) {
        emit(ExplorerLoadedSuccessState(files: files));
      } else {
        emit(ExplorerEmptyFilesState());
      }
    } catch (error) {
      emit(ExplorerErrorState());
    }
  }

}
