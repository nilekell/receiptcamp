import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/explorer/explorer_bloc.dart';
import 'package:receiptcamp/logic/blocs/upload/upload_bloc.dart';
import 'package:receiptcamp/logic/cubits/file_edit/file_editing_cubit.dart';

abstract interface class SnackBarUtility {
  static String _message = '';

  static final SnackBar _appSnackBar = SnackBar(
    content: Text(_message),
    duration: const Duration(milliseconds: 2000));
    
  // currently adding ExplorerFetchFilesEvent() when a new receipt/folder is added
  static void showUploadSnackBar(BuildContext context, UploadState state) {
    switch (state.runtimeType) {
      case UploadFolderSuccess:
        UploadFolderSuccess currentState = state as UploadFolderSuccess;
         _message = '${currentState.folder.name} added successfully';
         context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
          ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case UploadReceiptSuccess:
        UploadReceiptSuccess currentState = state as UploadReceiptSuccess;
        _message = '${currentState.receipt.name} added successfully';
        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case UploadFailed:
        _message = 'Failed to save file object';
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      default:
        print('default state');
        return;
    }
  }

  // currently adding ExplorerFetchFilesEvent() when a new receipt/folder is renamed, moved, deleted
  // IN FUTURE REFACTOR THIS TO ADD EVENTS BASED ON FileEditingCubit INSTEAD
  static void showFileEditSnackBar(BuildContext context, FileEditingCubitState state) {
    switch (state.runtimeType) {
      case FileEditingCubitRenameSuccess:
        FileEditingCubitRenameSuccess currentState = state as FileEditingCubitRenameSuccess;
        _message = '${currentState.oldName} renamed to ${currentState.newName}';
        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitRenameFailure:
      FileEditingCubitRenameFailure currentState = state as FileEditingCubitRenameFailure;
        _message = 'Failed to rename ${currentState.oldName}';
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitMoveSuccess:
      FileEditingCubitMoveSuccess currentState = state as FileEditingCubitMoveSuccess;
        _message = 'Moved ${currentState.oldFolderName} to ${currentState.newFolderName}';
        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitMoveFailure:
      FileEditingCubitMoveFailure currentState = state as FileEditingCubitMoveFailure;
        _message = 'Failed to move ${currentState.oldFolderName} to ${currentState.newFolderName}';
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitDeleteSuccess:
      FileEditingCubitDeleteSuccess currentState = state as FileEditingCubitDeleteSuccess;
        _message = 'Deleted ${currentState.deletedName}';
        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitDeleteFailure:
      FileEditingCubitDeleteFailure currentState = state as FileEditingCubitDeleteFailure;
        _message = 'Failed to delete ${currentState.deletedName}';
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitShareSuccess:
      FileEditingCubitShareSuccess currentState = state as FileEditingCubitShareSuccess;
        _message = 'Shared ${currentState.receiptName}';
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitShareFailure:
      FileEditingCubitShareFailure currentState = state as FileEditingCubitShareFailure;
        _message = 'Failed to share ${currentState.receiptName}';;
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitSaveImageSuccess:
      FileEditingCubitSaveImageSuccess currentState = state as FileEditingCubitSaveImageSuccess;
        _message = 'Saved ${currentState.receiptName} to camera roll';
        ScaffoldMessenger.of(context).showSnackBar(_appSnackBar);
      case FileEditingCubitSaveImageFailure:
        FileEditingCubitSaveImageFailure currentState = state as FileEditingCubitSaveImageFailure;
        _message = 'Saved ${currentState.receiptName} to camera roll';
      default:
        print('default state');
        return;
    }
  }
}