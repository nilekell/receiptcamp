import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/models/folder.dart';

part 'file_explorer_state.dart';

// responsible for displaying folder name, back button, and upload button with correct folder reference
class FileExplorerCubit extends Cubit<FileExplorerCubitState> {
  FileExplorerCubit() : super(FileExplorerCubitInitial());

  Folder? currentlyDisplayedFolder;

  // method to display root folder information when the bottom navigation tab switches to file explorer
  initializeFileExplorerCubit() async {
    emit(FileExplorerCubitInitial());
    fetchFolderInformation(rootFolderId);
  }

  // method to fetch displayed folder information, which is required for FolderName, BackButton, FolderView, UploadButton
  fetchFolderInformation(String folderId) async {
    emit(FileExplorerCubitLoading());
    try {
      final folder = await DatabaseRepository.instance.getFolderById(folderId);
      currentlyDisplayedFolder = folder;
      emit(FileExplorerCubitFolderInformationSuccess(folder: folder));
    } catch (error) {
      emit(FileExplorerCubitError());
    }
  }

  // method for when folder tile is tapped
  selectFolder(String folderId) async {
    emit(FileExplorerCubitLoading());
    try {
      final folder = await DatabaseRepository.instance.getFolderById(folderId);
      currentlyDisplayedFolder = folder;
      emit(FileExplorerCubitFolderInformationSuccess(folder: folder));
    } catch (error) {
      emit(FileExplorerCubitError());
    }
  }

  // method for when back button is tapped
  navigateBack(String parentFolderId) async {
    emit(FileExplorerCubitLoading());
    try {
      final Folder parentFolder = await DatabaseRepository.instance.getFolderById(parentFolderId);
      currentlyDisplayedFolder = parentFolder;
      emit(FileExplorerCubitFolderInformationSuccess(folder: parentFolder));
    } catch (error) {
      emit(FileExplorerCubitError());
    }
  }
}
