import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/models/folder.dart';

part 'file_system_state.dart';

// responsible for displaying folder name, back button, and upload button with correct folder reference
class FileSystemCubit extends HydratedCubit<FileSystemCubitState> {
  FileSystemCubit() : super(FileSystemCubitInitial());

  // method to display root folder information when the bottom navigation tab switches to file explorer
  initializeFileSystemCubit() async {
    emit(FileSystemCubitInitial());
    fetchFolderInformation(rootFolderId);
  }

  // method to fetch displayed folder information, which is required for FolderName, BackButton, FolderView, UploadButton
  fetchFolderInformation(String folderId) async {
    emit(FileSystemCubitLoading());
    try {
      final folder = await DatabaseRepository.instance.getFolderById(folderId);
      emit(FileSystemCubitFolderInformationSuccess(folder: folder));
    } catch (error) {
      emit(FileSystemCubitError());
    }
  }

  // method for when folder tile is tapped
  selectFolder(String folderId) async {
    emit(FileSystemCubitLoading());
    try {
      final folder = await DatabaseRepository.instance.getFolderById(folderId);
      emit(FileSystemCubitFolderInformationSuccess(folder: folder));
    } catch (error) {
      emit(FileSystemCubitError());
    }
  }

  // method for when back button is tapped
  navigateBack(String parentFolderId) async {
    emit(FileSystemCubitLoading());
    try {
      final Folder parentFolder = await DatabaseRepository.instance.getFolderById(parentFolderId);
      emit(FileSystemCubitFolderInformationSuccess(folder: parentFolder));
    } catch (error) {
      emit(FileSystemCubitError());
    }
  }
  
  @override
  FileSystemCubitState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['folder'] != null) {
        final folder = Folder.fromMap(json['folder']);
        return FileSystemCubitFolderInformationSuccess(folder: folder);
      } else if (json['error'] == true) {
        return FileSystemCubitError();
      } else if (json['loading'] == true) {
        return FileSystemCubitLoading();
      } else {
        return FileSystemCubitInitial();
      }
    } catch (_) {
      return null;
    }
  }
  
  @override
  Map<String, dynamic>? toJson(FileSystemCubitState state) {
    try {
      if (state is FileSystemCubitFolderInformationSuccess) {
        return {
          'folder': json.decode(state.folder.toJson()),
        };
      } else if (state is FileSystemCubitError) {
        return {'error': true};
      } else if (state is FileSystemCubitLoading) {
        return {'loading': true};
      } else if (state is FileSystemCubitInitial) {
        return {'initial': true};
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
